// Minimal ABI-compatible subset of AMD AMF SDK v1.4.35.
// Derived from the official MIT-licensed headers at:
// https://github.com/GPUOpen-LibrariesAndSDKs/AMF/tree/v1.4.35/amf/public/include
//
// Copyright (c) 2017-2018 Advanced Micro Devices, Inc. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, subject to inclusion of this notice. THE SOFTWARE IS
// PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.

#pragma once

#include <cstddef>
#include <cstdint>

#define AMF_STD_CALL __stdcall
#define AMF_CDECL_CALL __cdecl

using amf_int64 = std::int64_t;
using amf_int32 = std::int32_t;
using amf_uint64 = std::uint64_t;
using amf_uint32 = std::uint32_t;
using amf_uint16 = std::uint16_t;
using amf_uint8 = std::uint8_t;
using amf_size = std::size_t;
using amf_long = long;
using amf_pts = amf_int64;
using amf_bool = bool;
using amf_handle = void*;

constexpr amf_pts AMF_SECOND = 10000000;
constexpr amf_uint64 AMF_FULL_VERSION =
    (amf_uint64{1} << 48) | (amf_uint64{4} << 32) | (amf_uint64{35} << 16);

enum AMF_RESULT {
    AMF_OK = 0, AMF_FAIL, AMF_UNEXPECTED, AMF_ACCESS_DENIED, AMF_INVALID_ARG,
    AMF_OUT_OF_RANGE, AMF_OUT_OF_MEMORY, AMF_INVALID_POINTER, AMF_NO_INTERFACE,
    AMF_NOT_IMPLEMENTED, AMF_NOT_SUPPORTED, AMF_NOT_FOUND, AMF_ALREADY_INITIALIZED,
    AMF_NOT_INITIALIZED, AMF_INVALID_FORMAT, AMF_WRONG_STATE, AMF_FILE_NOT_OPEN,
    AMF_NO_DEVICE, AMF_DIRECTX_FAILED, AMF_OPENCL_FAILED, AMF_GLX_FAILED,
    AMF_XV_FAILED, AMF_ALSA_FAILED, AMF_EOF, AMF_REPEAT, AMF_INPUT_FULL,
    AMF_RESOLUTION_CHANGED, AMF_RESOLUTION_UPDATED, AMF_INVALID_DATA_TYPE,
    AMF_INVALID_RESOLUTION, AMF_CODEC_NOT_SUPPORTED, AMF_SURFACE_FORMAT_NOT_SUPPORTED,
    AMF_SURFACE_MUST_BE_SHARED, AMF_DECODER_NOT_PRESENT,
    AMF_DECODER_SURFACE_ALLOCATION_FAILED, AMF_DECODER_NO_FREE_SURFACES,
    AMF_ENCODER_NOT_PRESENT, AMF_DEM_ERROR, AMF_DEM_PROPERTY_READONLY,
    AMF_DEM_REMOTE_DISPLAY_CREATE_FAILED, AMF_DEM_START_ENCODING_FAILED,
    AMF_DEM_QUERY_OUTPUT_FAILED, AMF_TAN_CLIPPING_WAS_REQUIRED,
    AMF_TAN_UNSUPPORTED_VERSION, AMF_NEED_MORE_INPUT, AMF_VULKAN_FAILED
};

struct AMFRect { amf_int32 left, top, right, bottom; };
struct AMFSize { amf_int32 width, height; };
struct AMFPoint { amf_int32 x, y; };
struct AMFRate { amf_uint32 num, den; };
struct AMFRatio { amf_uint32 num, den; };
struct AMFColor { amf_uint32 rgba; };
struct AMFFloatSize { float width, height; };
struct AMFFloatPoint2D { float x, y; };
struct AMFFloatPoint3D { float x, y, z; };
struct AMFFloatVector4D { float x, y, z, w; };

struct AMFGuid {
    amf_uint32 data1;
    amf_uint16 data2;
    amf_uint16 data3;
    amf_uint8 data41, data42, data43, data44, data45, data46, data47, data48;
};

enum AMF_VARIANT_TYPE {
    AMF_VARIANT_EMPTY = 0, AMF_VARIANT_BOOL, AMF_VARIANT_INT64, AMF_VARIANT_DOUBLE,
    AMF_VARIANT_RECT, AMF_VARIANT_SIZE, AMF_VARIANT_POINT, AMF_VARIANT_RATE,
    AMF_VARIANT_RATIO, AMF_VARIANT_COLOR, AMF_VARIANT_STRING, AMF_VARIANT_WSTRING,
    AMF_VARIANT_INTERFACE, AMF_VARIANT_FLOAT, AMF_VARIANT_FLOAT_SIZE,
    AMF_VARIANT_FLOAT_POINT2D, AMF_VARIANT_FLOAT_POINT3D, AMF_VARIANT_FLOAT_VECTOR4D
};

namespace amf {
class AMFInterface;

struct AMFVariantStruct {
    AMF_VARIANT_TYPE type;
    union {
        amf_bool boolValue;
        amf_int64 int64Value;
        double doubleValue;
        char* stringValue;
        wchar_t* wstringValue;
        AMFInterface* pInterface;
        AMFRect rectValue;
        AMFSize sizeValue;
        AMFPoint pointValue;
        AMFRate rateValue;
        AMFRatio ratioValue;
        AMFColor colorValue;
        float floatValue;
        AMFFloatSize floatSizeValue;
        AMFFloatPoint2D floatPoint2DValue;
        AMFFloatPoint3D floatPoint3DValue;
        AMFFloatVector4D floatVector4DValue;
    };
};
static_assert(sizeof(AMFVariantStruct) == 24, "AMFVariantStruct ABI mismatch");

inline AMFVariantStruct AMFVariantInt64(amf_int64 value) {
    AMFVariantStruct result{};
    result.type = AMF_VARIANT_INT64;
    result.int64Value = value;
    return result;
}
inline AMFVariantStruct AMFVariantBool(amf_bool value) {
    AMFVariantStruct result{};
    result.type = AMF_VARIANT_BOOL;
    result.boolValue = value;
    return result;
}
inline AMFVariantStruct AMFVariantSize(amf_int32 width, amf_int32 height) {
    AMFVariantStruct result{};
    result.type = AMF_VARIANT_SIZE;
    result.sizeValue = {width, height};
    return result;
}
inline AMFVariantStruct AMFVariantRate(amf_uint32 num, amf_uint32 den) {
    AMFVariantStruct result{};
    result.type = AMF_VARIANT_RATE;
    result.rateValue = {num, den};
    return result;
}

enum AMF_MEMORY_TYPE {
    AMF_MEMORY_UNKNOWN = 0, AMF_MEMORY_HOST = 1, AMF_MEMORY_DX9 = 2,
    AMF_MEMORY_DX11 = 3, AMF_MEMORY_OPENCL = 4, AMF_MEMORY_OPENGL = 5,
    AMF_MEMORY_XV = 6, AMF_MEMORY_GRALLOC = 7, AMF_MEMORY_COMPUTE_FOR_DX9 = 8,
    AMF_MEMORY_COMPUTE_FOR_DX11 = 9, AMF_MEMORY_VULKAN = 10, AMF_MEMORY_DX12 = 11
};

enum AMF_DX_VERSION { AMF_DX9 = 90, AMF_DX9_EX = 91, AMF_DX11_0 = 110, AMF_DX11_1 = 111 };
enum AMF_DATA_TYPE { AMF_DATA_BUFFER = 0, AMF_DATA_SURFACE = 1, AMF_DATA_AUDIO_BUFFER = 2 };
enum AMF_SURFACE_FORMAT {
    AMF_SURFACE_UNKNOWN = 0, AMF_SURFACE_NV12 = 1, AMF_SURFACE_YV12 = 2,
    AMF_SURFACE_BGRA = 3, AMF_SURFACE_ARGB = 4, AMF_SURFACE_RGBA = 5
};
enum AMF_FRAME_TYPE { AMF_FRAME_UNKNOWN = -1, AMF_FRAME_PROGRESSIVE = 0 };

class AMFPropertyStorage;
class AMFPropertyStorageObserver;
class AMFPropertyInfo;
class AMFData;
class AMFBuffer;
class AMFBufferObserver;
class AMFSurface;
class AMFSurfaceObserver;
class AMFAudioBuffer;
class AMFComputeFactory;
class AMFComputeDevice;
class AMFCompute;
class AMFPlane;
class AMFCaps;
class AMFDataAllocatorCB;
class AMFComponentOptimizationCallback;

class __declspec(novtable) AMFInterface {
public:
    virtual amf_long AMF_STD_CALL Acquire() = 0;
    virtual amf_long AMF_STD_CALL Release() = 0;
    virtual AMF_RESULT AMF_STD_CALL QueryInterface(const AMFGuid& interfaceID, void** ppInterface) = 0;
};

class __declspec(novtable) AMFPropertyStorage : public AMFInterface {
public:
    virtual AMF_RESULT AMF_STD_CALL SetProperty(const wchar_t*, AMFVariantStruct) = 0;
    virtual AMF_RESULT AMF_STD_CALL GetProperty(const wchar_t*, AMFVariantStruct*) const = 0;
    virtual amf_bool AMF_STD_CALL HasProperty(const wchar_t*) const = 0;
    virtual amf_size AMF_STD_CALL GetPropertyCount() const = 0;
    virtual AMF_RESULT AMF_STD_CALL GetPropertyAt(amf_size, wchar_t*, amf_size, AMFVariantStruct*) const = 0;
    virtual AMF_RESULT AMF_STD_CALL Clear() = 0;
    virtual AMF_RESULT AMF_STD_CALL AddTo(AMFPropertyStorage*, amf_bool, amf_bool) const = 0;
    virtual AMF_RESULT AMF_STD_CALL CopyTo(AMFPropertyStorage*, amf_bool) const = 0;
    virtual void AMF_STD_CALL AddObserver(AMFPropertyStorageObserver*) = 0;
    virtual void AMF_STD_CALL RemoveObserver(AMFPropertyStorageObserver*) = 0;
};

class __declspec(novtable) AMFPropertyStorageEx : public AMFPropertyStorage {
public:
    virtual amf_size AMF_STD_CALL GetPropertiesInfoCount() const = 0;
    virtual AMF_RESULT AMF_STD_CALL GetPropertyInfo(amf_size, const AMFPropertyInfo**) const = 0;
    virtual AMF_RESULT AMF_STD_CALL GetPropertyInfo(const wchar_t*, const AMFPropertyInfo**) const = 0;
    virtual AMF_RESULT AMF_STD_CALL ValidateProperty(const wchar_t*, AMFVariantStruct, AMFVariantStruct*) const = 0;
};

class __declspec(novtable) AMFData : public AMFPropertyStorage {
public:
    virtual AMF_MEMORY_TYPE AMF_STD_CALL GetMemoryType() = 0;
    virtual AMF_RESULT AMF_STD_CALL Duplicate(AMF_MEMORY_TYPE, AMFData**) = 0;
    virtual AMF_RESULT AMF_STD_CALL Convert(AMF_MEMORY_TYPE) = 0;
    virtual AMF_RESULT AMF_STD_CALL Interop(AMF_MEMORY_TYPE) = 0;
    virtual AMF_DATA_TYPE AMF_STD_CALL GetDataType() = 0;
    virtual amf_bool AMF_STD_CALL IsReusable() = 0;
    virtual void AMF_STD_CALL SetPts(amf_pts) = 0;
    virtual amf_pts AMF_STD_CALL GetPts() = 0;
    virtual void AMF_STD_CALL SetDuration(amf_pts) = 0;
    virtual amf_pts AMF_STD_CALL GetDuration() = 0;
};

class __declspec(novtable) AMFBuffer : public AMFData {
public:
    static AMFGuid IID() { return {0xb04b7248, 0xb6f0, 0x4321, 0xb6, 0x91, 0xba, 0xa4, 0x74, 0x0f, 0x9f, 0xcb}; }
    virtual AMF_RESULT AMF_STD_CALL SetSize(amf_size) = 0;
    virtual amf_size AMF_STD_CALL GetSize() = 0;
    virtual void* AMF_STD_CALL GetNative() = 0;
    virtual void AMF_STD_CALL AddObserver(AMFBufferObserver*) = 0;
    virtual void AMF_STD_CALL RemoveObserver(AMFBufferObserver*) = 0;
};

class __declspec(novtable) AMFSurface : public AMFData {
public:
    virtual AMF_SURFACE_FORMAT AMF_STD_CALL GetFormat() = 0;
    virtual amf_size AMF_STD_CALL GetPlanesCount() = 0;
    virtual AMFPlane* AMF_STD_CALL GetPlaneAt(amf_size) = 0;
    virtual AMFPlane* AMF_STD_CALL GetPlane(amf_int32) = 0;
    virtual AMF_FRAME_TYPE AMF_STD_CALL GetFrameType() = 0;
    virtual void AMF_STD_CALL SetFrameType(AMF_FRAME_TYPE) = 0;
    virtual AMF_RESULT AMF_STD_CALL SetCrop(amf_int32, amf_int32, amf_int32, amf_int32) = 0;
    virtual AMF_RESULT AMF_STD_CALL CopySurfaceRegion(AMFSurface*, amf_int32, amf_int32,
        amf_int32, amf_int32, amf_int32, amf_int32) = 0;
    virtual void AMF_STD_CALL AddObserver(AMFSurfaceObserver*) = 0;
    virtual void AMF_STD_CALL RemoveObserver(AMFSurfaceObserver*) = 0;
};

class __declspec(novtable) AMFContext : public AMFPropertyStorage {
public:
    virtual AMF_RESULT AMF_STD_CALL Terminate() = 0;
    virtual AMF_RESULT AMF_STD_CALL InitDX9(void*) = 0;
    virtual void* AMF_STD_CALL GetDX9Device(AMF_DX_VERSION) = 0;
    virtual AMF_RESULT AMF_STD_CALL LockDX9() = 0;
    virtual AMF_RESULT AMF_STD_CALL UnlockDX9() = 0;
    virtual AMF_RESULT AMF_STD_CALL InitDX11(void*, AMF_DX_VERSION = AMF_DX11_0) = 0;
    virtual void* AMF_STD_CALL GetDX11Device(AMF_DX_VERSION = AMF_DX11_0) = 0;
    virtual AMF_RESULT AMF_STD_CALL LockDX11() = 0;
    virtual AMF_RESULT AMF_STD_CALL UnlockDX11() = 0;
    virtual AMF_RESULT AMF_STD_CALL InitOpenCL(void*) = 0;
    virtual void* AMF_STD_CALL GetOpenCLContext() = 0;
    virtual void* AMF_STD_CALL GetOpenCLCommandQueue() = 0;
    virtual void* AMF_STD_CALL GetOpenCLDeviceID() = 0;
    virtual AMF_RESULT AMF_STD_CALL GetOpenCLComputeFactory(AMFComputeFactory**) = 0;
    virtual AMF_RESULT AMF_STD_CALL InitOpenCLEx(AMFComputeDevice*) = 0;
    virtual AMF_RESULT AMF_STD_CALL LockOpenCL() = 0;
    virtual AMF_RESULT AMF_STD_CALL UnlockOpenCL() = 0;
    virtual AMF_RESULT AMF_STD_CALL InitOpenGL(amf_handle, amf_handle, amf_handle) = 0;
    virtual amf_handle AMF_STD_CALL GetOpenGLContext() = 0;
    virtual amf_handle AMF_STD_CALL GetOpenGLDrawable() = 0;
    virtual AMF_RESULT AMF_STD_CALL LockOpenGL() = 0;
    virtual AMF_RESULT AMF_STD_CALL UnlockOpenGL() = 0;
    virtual AMF_RESULT AMF_STD_CALL InitXV(void*) = 0;
    virtual void* AMF_STD_CALL GetXVDevice() = 0;
    virtual AMF_RESULT AMF_STD_CALL LockXV() = 0;
    virtual AMF_RESULT AMF_STD_CALL UnlockXV() = 0;
    virtual AMF_RESULT AMF_STD_CALL InitGralloc(void*) = 0;
    virtual void* AMF_STD_CALL GetGrallocDevice() = 0;
    virtual AMF_RESULT AMF_STD_CALL LockGralloc() = 0;
    virtual AMF_RESULT AMF_STD_CALL UnlockGralloc() = 0;
    virtual AMF_RESULT AMF_STD_CALL AllocBuffer(AMF_MEMORY_TYPE, amf_size, AMFBuffer**) = 0;
    virtual AMF_RESULT AMF_STD_CALL AllocSurface(AMF_MEMORY_TYPE, AMF_SURFACE_FORMAT,
        amf_int32, amf_int32, AMFSurface**) = 0;
    virtual AMF_RESULT AMF_STD_CALL AllocAudioBuffer(AMF_MEMORY_TYPE, amf_int32,
        amf_int32, amf_int32, amf_int32, AMFAudioBuffer**) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateBufferFromHostNative(void*, amf_size,
        AMFBuffer**, AMFBufferObserver*) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateSurfaceFromHostNative(AMF_SURFACE_FORMAT,
        amf_int32, amf_int32, amf_int32, amf_int32, void*, AMFSurface**, AMFSurfaceObserver*) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateSurfaceFromDX9Native(void*, AMFSurface**, AMFSurfaceObserver*) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateSurfaceFromDX11Native(void*, AMFSurface**, AMFSurfaceObserver*) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateSurfaceFromOpenGLNative(AMF_SURFACE_FORMAT,
        amf_handle, AMFSurface**, AMFSurfaceObserver*) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateSurfaceFromGrallocNative(amf_handle, AMFSurface**, AMFSurfaceObserver*) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateSurfaceFromOpenCLNative(AMF_SURFACE_FORMAT,
        amf_int32, amf_int32, void**, AMFSurface**, AMFSurfaceObserver*) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateBufferFromOpenCLNative(void*, amf_size, AMFBuffer**) = 0;
    virtual AMF_RESULT AMF_STD_CALL GetCompute(AMF_MEMORY_TYPE, AMFCompute**) = 0;
};

class __declspec(novtable) AMFComponent : public AMFPropertyStorageEx {
public:
    virtual AMF_RESULT AMF_STD_CALL Init(AMF_SURFACE_FORMAT, amf_int32, amf_int32) = 0;
    virtual AMF_RESULT AMF_STD_CALL ReInit(amf_int32, amf_int32) = 0;
    virtual AMF_RESULT AMF_STD_CALL Terminate() = 0;
    virtual AMF_RESULT AMF_STD_CALL Drain() = 0;
    virtual AMF_RESULT AMF_STD_CALL Flush() = 0;
    virtual AMF_RESULT AMF_STD_CALL SubmitInput(AMFData*) = 0;
    virtual AMF_RESULT AMF_STD_CALL QueryOutput(AMFData**) = 0;
    virtual AMFContext* AMF_STD_CALL GetContext() = 0;
    virtual AMF_RESULT AMF_STD_CALL SetOutputDataAllocatorCB(AMFDataAllocatorCB*) = 0;
    virtual AMF_RESULT AMF_STD_CALL GetCaps(AMFCaps**) = 0;
    virtual AMF_RESULT AMF_STD_CALL Optimize(AMFComponentOptimizationCallback*) = 0;
};

class __declspec(novtable) AMFFactory {
public:
    virtual AMF_RESULT AMF_STD_CALL CreateContext(AMFContext**) = 0;
    virtual AMF_RESULT AMF_STD_CALL CreateComponent(AMFContext*, const wchar_t*, AMFComponent**) = 0;
    virtual AMF_RESULT AMF_STD_CALL SetCacheFolder(const wchar_t*) = 0;
    virtual const wchar_t* AMF_STD_CALL GetCacheFolder() = 0;
    virtual AMF_RESULT AMF_STD_CALL GetDebug(void**) = 0;
    virtual AMF_RESULT AMF_STD_CALL GetTrace(void**) = 0;
    virtual AMF_RESULT AMF_STD_CALL GetPrograms(void**) = 0;
};
}

using AMFInit_Fn = AMF_RESULT (AMF_CDECL_CALL*)(amf_uint64, amf::AMFFactory**);
using AMFQueryVersion_Fn = AMF_RESULT (AMF_CDECL_CALL*)(amf_uint64*);

constexpr wchar_t AMFVideoConverter[] = L"AMFVideoConverter";
constexpr wchar_t AMFVideoEncoderVCE_AVC[] = L"AMFVideoEncoderVCE_AVC";

constexpr wchar_t AMF_VIDEO_CONVERTER_OUTPUT_FORMAT[] = L"OutputFormat";
constexpr wchar_t AMF_VIDEO_CONVERTER_MEMORY_TYPE[] = L"MemoryType";
constexpr wchar_t AMF_VIDEO_CONVERTER_OUTPUT_SIZE[] = L"OutputSize";

constexpr wchar_t AMF_VIDEO_ENCODER_USAGE[] = L"Usage";
constexpr wchar_t AMF_VIDEO_ENCODER_PROFILE[] = L"Profile";
constexpr wchar_t AMF_VIDEO_ENCODER_FRAMESIZE[] = L"FrameSize";
constexpr wchar_t AMF_VIDEO_ENCODER_MAX_CONSECUTIVE_BPICTURES[] = L"MaxConsecutiveBPictures";
constexpr wchar_t AMF_VIDEO_ENCODER_RATE_CONTROL_METHOD[] = L"RateControlMethod";
constexpr wchar_t AMF_VIDEO_ENCODER_QUALITY_PRESET[] = L"QualityPreset";
constexpr wchar_t AMF_VIDEO_ENCODER_FRAMERATE[] = L"FrameRate";
constexpr wchar_t AMF_VIDEO_ENCODER_QP_I[] = L"QPI";
constexpr wchar_t AMF_VIDEO_ENCODER_QP_P[] = L"QPP";
constexpr wchar_t AMF_VIDEO_ENCODER_QP_B[] = L"QPB";
constexpr wchar_t AMF_VIDEO_ENCODER_B_PIC_PATTERN[] = L"BPicturesPattern";
constexpr wchar_t AMF_VIDEO_ENCODER_IDR_PERIOD[] = L"IDRPeriod";
constexpr wchar_t AMF_VIDEO_ENCODER_INSERT_AUD[] = L"InsertAUD";
constexpr wchar_t AMF_VIDEO_ENCODER_INSERT_SPS[] = L"InsertSPS";
constexpr wchar_t AMF_VIDEO_ENCODER_INSERT_PPS[] = L"InsertPPS";
constexpr wchar_t AMF_VIDEO_ENCODER_MEMORY_TYPE[] = L"EncoderMemoryType";

constexpr amf_int64 AMF_VIDEO_ENCODER_USAGE_TRANSCODING = 0;
constexpr amf_int64 AMF_VIDEO_ENCODER_PROFILE_HIGH = 100;
constexpr amf_int64 AMF_VIDEO_ENCODER_RATE_CONTROL_METHOD_CONSTANT_QP = 0;
constexpr amf_int64 AMF_VIDEO_ENCODER_QUALITY_PRESET_BALANCED = 0;
constexpr amf_int64 AMF_VIDEO_ENCODER_QUALITY_PRESET_SPEED = 1;
constexpr amf_int64 AMF_VIDEO_ENCODER_QUALITY_PRESET_QUALITY = 2;
