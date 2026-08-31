#include "native/ICompressionInternal_native.h"
#include "archive_magic.hpp"

#include <Windows.h>

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <vector>

using namespace gm::wire;
using namespace gm_structs;
using namespace gm_enums;

namespace {

constexpr std::uintmax_t kMaxArchiveBytes = 1ull << 30;

enum TaskStatus : int32_t {
    TaskUnknown = 0,
    TaskQueued = 1,
    TaskRunning = 2,
    TaskSucceeded = 3,
    TaskFailed = 4,
    TaskCancelled = 5,
};

struct ZipTask {
    std::atomic<int32_t> status{TaskQueued};
    std::atomic<int32_t> exit_code{-1};
    std::atomic<bool> cancel_requested{false};
    std::mutex mutex;
    HANDLE process = nullptr;
    std::string error;
    std::thread worker;
};

std::mutex g_tasks_mutex;
std::unordered_map<int32_t, std::shared_ptr<ZipTask>> g_tasks;
std::atomic<int32_t> g_next_task_id{1};
std::mutex g_error_mutex;
std::string g_last_error;
std::atomic<bool> g_shutting_down{false};

std::wstring utf8_to_wide(std::string_view text) {
    if (text.empty()) return {};
    int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(), static_cast<int>(text.size()), nullptr, 0);
    UINT code_page = CP_UTF8;
    DWORD flags = MB_ERR_INVALID_CHARS;
    // GameMaker normally passes UTF-8, but older extension call paths can pass
    // the active Windows code page for non-ASCII strings. Keep UTF-8 as the
    // canonical path and only fall back when the byte sequence is invalid.
    if (count <= 0) {
        code_page = CP_ACP;
        flags = 0;
        count = MultiByteToWideChar(code_page, flags, text.data(), static_cast<int>(text.size()), nullptr, 0);
    }
    if (count <= 0) return {};
    std::wstring result(static_cast<size_t>(count), L'\0');
    MultiByteToWideChar(code_page, flags, text.data(), static_cast<int>(text.size()), result.data(), count);
    return result;
}

std::string wide_to_utf8(std::wstring_view text) {
    if (text.empty()) return {};
    const int count = WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0, nullptr, nullptr);
    if (count <= 0) return {};
    std::string result(static_cast<size_t>(count), '\0');
    WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), result.data(), count, nullptr, nullptr);
    return result;
}

std::string process_output_to_utf8(const std::string& bytes) {
    if (bytes.empty()) return {};
    int count = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, bytes.data(), static_cast<int>(bytes.size()), nullptr, 0);
    UINT code_page = CP_UTF8;
    DWORD flags = MB_ERR_INVALID_CHARS;
    if (count <= 0) {
        code_page = CP_ACP;
        flags = 0;
        count = MultiByteToWideChar(code_page, flags, bytes.data(), static_cast<int>(bytes.size()), nullptr, 0);
    }
    if (count <= 0) return bytes;
    std::wstring wide(static_cast<size_t>(count), L'\0');
    MultiByteToWideChar(code_page, flags, bytes.data(), static_cast<int>(bytes.size()), wide.data(), count);
    return wide_to_utf8(wide);
}

void set_last_error(std::string message) {
    std::lock_guard lock(g_error_mutex);
    g_last_error = std::move(message);
}

std::wstring quote_arg(std::wstring_view arg) {
    std::wstring result = L"\"";
    size_t slashes = 0;
    for (const wchar_t ch : arg) {
        if (ch == L'\\') {
            ++slashes;
            continue;
        }
        if (ch == L'\"') {
            result.append(slashes * 2 + 1, L'\\');
            result.push_back(L'\"');
            slashes = 0;
            continue;
        }
        result.append(slashes, L'\\');
        slashes = 0;
        result.push_back(ch);
    }
    result.append(slashes * 2, L'\\');
    result.push_back(L'\"');
    return result;
}

std::filesystem::path tar_path() {
    std::wstring system_dir(MAX_PATH, L'\0');
    const UINT size = GetSystemDirectoryW(system_dir.data(), static_cast<UINT>(system_dir.size()));
    if (size == 0 || size >= system_dir.size()) return {};
    system_dir.resize(size);
    return std::filesystem::path(system_dir) / L"tar.exe";
}

std::filesystem::path create_staging_directory() {
    wchar_t temp_name[MAX_PATH]{};
    wchar_t temp_path[MAX_PATH]{};
    const DWORD temp_length = GetTempPathW(static_cast<DWORD>(std::size(temp_path)), temp_path);
    if (temp_length == 0 || temp_length >= std::size(temp_path)) return {};
    if (GetTempFileNameW(temp_path, L"ICZ", 0, temp_name) == 0) return {};
    DeleteFileW(temp_name);
    if (!CreateDirectoryW(temp_name, nullptr)) return {};
    return std::filesystem::path(temp_name);
}

bool is_dangerous_clean_path(const std::filesystem::path& path) {
    const auto absolute = std::filesystem::absolute(path).lexically_normal();
    return absolute.empty() || absolute == absolute.root_path();
}

std::shared_ptr<ZipTask> find_task(int32_t task_id) {
    std::lock_guard lock(g_tasks_mutex);
    const auto it = g_tasks.find(task_id);
    return it == g_tasks.end() ? nullptr : it->second;
}

bool run_process(const std::shared_ptr<ZipTask>& task, std::wstring command_line, std::string* captured_output = nullptr) {
    SECURITY_ATTRIBUTES security{sizeof(SECURITY_ATTRIBUTES), nullptr, TRUE};
    HANDLE read_pipe = nullptr;
    HANDLE write_pipe = nullptr;
    if (!CreatePipe(&read_pipe, &write_pipe, &security, 0)) {
        task->error = "Failed to create output pipe.";
        return false;
    }
    SetHandleInformation(read_pipe, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOW startup{};
    startup.cb = sizeof(startup);
    startup.dwFlags = STARTF_USESTDHANDLES;
    startup.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    startup.hStdOutput = write_pipe;
    startup.hStdError = write_pipe;
    PROCESS_INFORMATION process_info{};

    std::vector<wchar_t> mutable_command(command_line.begin(), command_line.end());
    mutable_command.push_back(L'\0');
    const BOOL created = CreateProcessW(
        nullptr,
        mutable_command.data(),
        nullptr,
        nullptr,
        TRUE,
        CREATE_NO_WINDOW | CREATE_UNICODE_ENVIRONMENT,
        nullptr,
        nullptr,
        &startup,
        &process_info);
    CloseHandle(write_pipe);

    if (!created) {
        CloseHandle(read_pipe);
        task->error = "Failed to start Windows tar.exe (error " + std::to_string(GetLastError()) + ").";
        return false;
    }

    {
        std::lock_guard lock(task->mutex);
        task->process = process_info.hProcess;
    }
    CloseHandle(process_info.hThread);

    if (task->cancel_requested.load()) TerminateProcess(process_info.hProcess, ERROR_CANCELLED);

    std::string output;
    char chunk[4096];
    DWORD read_count = 0;
    while (ReadFile(read_pipe, chunk, sizeof(chunk), &read_count, nullptr) && read_count > 0) {
        output.append(chunk, chunk + read_count);
        if (task->cancel_requested.load()) TerminateProcess(process_info.hProcess, ERROR_CANCELLED);
    }
    CloseHandle(read_pipe);
    if (captured_output) *captured_output = output;
    WaitForSingleObject(process_info.hProcess, INFINITE);

    DWORD exit_code = 1;
    GetExitCodeProcess(process_info.hProcess, &exit_code);
    task->exit_code.store(static_cast<int32_t>(exit_code));
    {
        std::lock_guard lock(task->mutex);
        task->process = nullptr;
    }
    CloseHandle(process_info.hProcess);

    if (task->cancel_requested.load()) return false;
    if (exit_code != 0) {
        task->error = process_output_to_utf8(output);
        if (task->error.empty()) task->error = "tar.exe failed with exit code " + std::to_string(exit_code) + ".";
        return false;
    }
    return true;
}

template <typename Work>
int32_t start_task(Work work) {
    if (g_shutting_down.load()) {
        set_last_error("I_Compression is shutting down.");
        return -1;
    }

    int32_t task_id = g_next_task_id.fetch_add(1);
    if (task_id <= 0) {
        g_next_task_id.store(2);
        task_id = 1;
    }
    auto task = std::make_shared<ZipTask>();
    {
        std::lock_guard lock(g_tasks_mutex);
        g_tasks[task_id] = task;
    }

    task->worker = std::thread([task, work = std::move(work)]() mutable {
        task->status.store(TaskRunning);
        bool succeeded = false;
        try {
            succeeded = work(task);
        } catch (const std::exception& exception) {
            task->error = exception.what();
        } catch (...) {
            task->error = "Unknown native ZIP error.";
        }

        if (task->cancel_requested.load()) task->status.store(TaskCancelled);
        else task->status.store(succeeded ? TaskSucceeded : TaskFailed);
    });
    return task_id;
}

} // namespace

void unicode_zip_initialize() {
    g_shutting_down.store(false);
    set_last_error({});
}

bool unicode_zip_available() {
    std::error_code error;
    return std::filesystem::is_regular_file(tar_path(), error);
}

int32_t unicode_zip_extract_async(std::string_view archive_path, std::string_view output_directory, bool overwrite, bool clean_output);
int32_t unicode_zip_compress_async(std::string_view source_path, std::string_view archive_path, bool include_root, bool overwrite);
bool unicode_zip_task_release(int32_t task_id);

std::string unicode_zip_detect(std::string_view archive_path) {
    if (archive_path.empty()) {
        set_last_error("Archive path must be a valid UTF-8 string.");
        return "unknown";
    }
    const auto wide = utf8_to_wide(archive_path);
    if (wide.empty()) {
        set_last_error("Archive path must be a valid UTF-8 string.");
        return "unknown";
    }
    const std::filesystem::path archive = std::filesystem::absolute(wide).lexically_normal();
    std::error_code error;
    if (!std::filesystem::is_regular_file(archive, error)) {
        set_last_error("Archive does not exist: " + wide_to_utf8(archive.wstring()));
        return "unknown";
    }
    set_last_error({});
    return detect_archive_kind_from_path(wide_to_utf8(archive.wstring()));
}

bool wait_task(int32_t task_id) {
    if (task_id < 0) return false;
    const auto task = find_task(task_id);
    if (!task) return false;
    if (task->worker.joinable()) task->worker.join();
    const bool ok = task->status.load() == TaskSucceeded;
    if (!ok) set_last_error(task->error);
    else set_last_error({});
    unicode_zip_task_release(task_id);
    return ok;
}

bool unicode_zip_extract(std::string_view archive_path, std::string_view output_directory, bool overwrite, bool clean_output) {
    return wait_task(unicode_zip_extract_async(archive_path, output_directory, overwrite, clean_output));
}

bool unicode_zip_extract_password(std::string_view archive_path, std::string_view output_directory,
    bool overwrite, bool clean_output, std::string_view password) {
    if (!password.empty()) {
        set_last_error("Password-protected archives are not supported on Windows.");
        return false;
    }
    return unicode_zip_extract(archive_path, output_directory, overwrite, clean_output);
}

bool unicode_zip_compress(std::string_view source_path, std::string_view archive_path, bool include_root, bool overwrite) {
    return wait_task(unicode_zip_compress_async(source_path, archive_path, include_root, overwrite));
}

bool unicode_zip_compress_password(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite, std::string_view password) {
    if (!password.empty()) {
        set_last_error("Password-protected compression is not supported on Windows.");
        return false;
    }
    return unicode_zip_compress(source_path, archive_path, include_root, overwrite);
}

bool unicode_zip_compress_format(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite, std::string_view password, std::string_view format) {
    (void)format;
    return unicode_zip_compress_password(source_path, archive_path, include_root, overwrite, password);
}

int32_t unicode_zip_extract_async_password(std::string_view archive_path, std::string_view output_directory,
    bool overwrite, bool clean_output, std::string_view password) {
    if (!password.empty()) {
        set_last_error("Password-protected archives are not supported on Windows.");
        return -1;
    }
    return unicode_zip_extract_async(archive_path, output_directory, overwrite, clean_output);
}

int32_t unicode_zip_compress_async_password(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite, std::string_view password) {
    if (!password.empty()) {
        set_last_error("Password-protected compression is not supported on Windows.");
        return -1;
    }
    return unicode_zip_compress_async(source_path, archive_path, include_root, overwrite);
}

int32_t unicode_zip_compress_async_format(std::string_view source_path, std::string_view archive_path,
    bool include_root, bool overwrite, std::string_view password, std::string_view format) {
    (void)format;
    return unicode_zip_compress_async_password(source_path, archive_path, include_root, overwrite, password);
}

int32_t unicode_zip_extract_async(std::string_view archive_path, std::string_view output_directory, bool overwrite, bool clean_output) {
    const auto archive_wide = utf8_to_wide(archive_path);
    const auto output_wide = utf8_to_wide(output_directory);
    if (archive_wide.empty() || output_wide.empty()) {
        set_last_error("Archive and output paths must be valid UTF-8 strings.");
        return -1;
    }

    const std::filesystem::path archive = std::filesystem::absolute(archive_wide).lexically_normal();
    const std::filesystem::path output = std::filesystem::absolute(output_wide).lexically_normal();
    const std::filesystem::path tar = tar_path();
    return start_task([archive, output, tar, overwrite, clean_output](const std::shared_ptr<ZipTask>& task) {
        std::error_code error;
        if (!std::filesystem::is_regular_file(tar, error)) {
            task->error = "Windows tar.exe is unavailable.";
            return false;
        }
        if (!std::filesystem::is_regular_file(archive, error)) {
            task->error = "ZIP archive does not exist: " + wide_to_utf8(archive.wstring());
            return false;
        }
        const auto archive_size = std::filesystem::file_size(archive, error);
        if (error) {
            task->error = "Failed to inspect ZIP archive size: " + error.message();
            return false;
        }
        if (archive_size > kMaxArchiveBytes) {
            task->error = "ZIP archive size exceeds the 1 GiB limit.";
            return false;
        }
        if (clean_output) {
            if (is_dangerous_clean_path(output)) {
                task->error = "Refusing to clean a filesystem root directory.";
                return false;
            }
            std::filesystem::remove_all(output, error);
            if (error) {
                task->error = "Failed to clean output directory: " + error.message();
                return false;
            }
        }
        std::filesystem::create_directories(output, error);
        if (error) {
            task->error = "Failed to create output directory: " + error.message();
            return false;
        }

        // Windows tar.exe can mishandle non-ASCII command-line paths even when
        // the archive itself contains valid UTF-8 entry names. Keep tar's input
        // and output paths ASCII, then move the extracted tree with filesystem's
        // UTF-16 APIs so both archive paths and entry paths remain Unicode-safe.
        const auto staging = create_staging_directory();
        if (staging.empty()) {
            task->error = "Failed to create a temporary ZIP staging directory.";
            return false;
        }
        const auto staged_archive = staging / L"archive.zip";
        const auto staged_output = staging / L"out";
        auto cleanup_staging = [&]() {
            std::error_code cleanup_error;
            std::filesystem::remove_all(staging, cleanup_error);
        };
        std::filesystem::copy_file(archive, staged_archive, std::filesystem::copy_options::overwrite_existing, error);
        if (error) {
            task->error = "Failed to stage ZIP archive: " + error.message();
            cleanup_staging();
            return false;
        }
        std::filesystem::create_directories(staged_output, error);
        if (error) {
            task->error = "Failed to create temporary ZIP output: " + error.message();
            cleanup_staging();
            return false;
        }

        // Many community ZIP charts store legacy Chinese names as CP936 without
        // the UTF-8 flag. Explicitly flagged UTF-8 names remain UTF-8.
        std::wstring command = quote_arg(tar.wstring()) + L" --options hdrcharset=CP936 -xf "
            + quote_arg(staged_archive.wstring()) + L" -C " + quote_arg(staged_output.wstring());
        if (!run_process(task, std::move(command))) {
            cleanup_staging();
            return false;
        }

        const auto copy_options = overwrite
            ? std::filesystem::copy_options::recursive | std::filesystem::copy_options::overwrite_existing
            : std::filesystem::copy_options::recursive | std::filesystem::copy_options::skip_existing;
        std::filesystem::copy(staged_output, output, copy_options, error);
        if (error) {
            task->error = "Failed to move extracted Unicode files: " + error.message();
            cleanup_staging();
            return false;
        }
        cleanup_staging();
        return true;
    });
}

int32_t unicode_zip_compress_async(std::string_view source_path, std::string_view archive_path, bool include_root, bool overwrite) {
    const auto source_wide = utf8_to_wide(source_path);
    const auto archive_wide = utf8_to_wide(archive_path);
    if (source_wide.empty() || archive_wide.empty()) {
        set_last_error("Source and archive paths must be valid UTF-8 strings.");
        return -1;
    }

    const std::filesystem::path source = std::filesystem::absolute(source_wide).lexically_normal();
    const std::filesystem::path archive = std::filesystem::absolute(archive_wide).lexically_normal();
    const std::filesystem::path tar = tar_path();
    return start_task([source, archive, tar, include_root, overwrite](const std::shared_ptr<ZipTask>& task) {
        std::error_code error;
        if (!std::filesystem::is_regular_file(tar, error)) {
            task->error = "Windows tar.exe is unavailable.";
            return false;
        }
        if (!std::filesystem::exists(source, error)) {
            task->error = "Source path does not exist: " + wide_to_utf8(source.wstring());
            return false;
        }
        if (std::filesystem::exists(archive, error)) {
            if (!overwrite) {
                task->error = "Archive already exists.";
                return false;
            }
            std::filesystem::remove(archive, error);
            if (error) {
                task->error = "Failed to replace existing archive: " + error.message();
                return false;
            }
        }
        if (!archive.parent_path().empty()) {
            std::filesystem::create_directories(archive.parent_path(), error);
            if (error) {
                task->error = "Failed to create archive directory: " + error.message();
                return false;
            }
        }

        std::filesystem::path base;
        std::filesystem::path entry;
        if (std::filesystem::is_directory(source, error) && !include_root) {
            base = source;
            entry = L".";
        } else {
            base = source.parent_path();
            entry = source.filename();
        }
        std::wstring command = quote_arg(tar.wstring()) + L" -a -cf " + quote_arg(archive.wstring()) + L" -C " + quote_arg(base.wstring()) + L" " + quote_arg(entry.wstring());
        return run_process(task, std::move(command));
    });
}

int32_t unicode_zip_task_status(int32_t task_id) {
    const auto task = find_task(task_id);
    return task ? task->status.load() : TaskUnknown;
}

int32_t unicode_zip_task_exit_code(int32_t task_id) {
    const auto task = find_task(task_id);
    return task ? task->exit_code.load() : -1;
}

std::string unicode_zip_task_error(int32_t task_id) {
    const auto task = find_task(task_id);
    if (!task) return "Unknown ZIP task.";
    const int32_t status = task->status.load();
    if (status == TaskQueued || status == TaskRunning) return {};
    return task->error;
}

bool unicode_zip_task_cancel(int32_t task_id) {
    const auto task = find_task(task_id);
    if (!task) return false;
    const int32_t status = task->status.load();
    if (status >= TaskSucceeded) return false;
    task->cancel_requested.store(true);
    std::lock_guard lock(task->mutex);
    if (task->process) TerminateProcess(task->process, ERROR_CANCELLED);
    return true;
}

bool unicode_zip_task_release(int32_t task_id) {
    std::shared_ptr<ZipTask> task;
    {
        std::lock_guard lock(g_tasks_mutex);
        const auto it = g_tasks.find(task_id);
        if (it == g_tasks.end()) return false;
        task = it->second;
        if (task->status.load() == TaskQueued || task->status.load() == TaskRunning) return false;
        g_tasks.erase(it);
    }
    if (task->worker.joinable()) task->worker.join();
    return true;
}

std::string unicode_zip_last_error() {
    std::lock_guard lock(g_error_mutex);
    return g_last_error;
}

void unicode_zip_shutdown() {
    g_shutting_down.store(true);
    std::vector<std::shared_ptr<ZipTask>> tasks;
    {
        std::lock_guard lock(g_tasks_mutex);
        for (const auto& [id, task] : g_tasks) {
            (void)id;
            tasks.push_back(task);
        }
        g_tasks.clear();
    }
    for (const auto& task : tasks) {
        task->cancel_requested.store(true);
        std::lock_guard lock(task->mutex);
        if (task->process) TerminateProcess(task->process, ERROR_CANCELLED);
    }
    for (const auto& task : tasks) {
        if (task->worker.joinable()) task->worker.join();
    }
}
