#pragma once

#include <EGL/egl.h>
#include <GLES2/gl2.h>

// Native renderers must restore driver state as well as GameMaker's cached
// state. In particular, texture unit zero and the alpha blend factors differ
// from the currently active texture unit / RGB factors during layer capture.
namespace pls {

class GlesTextureState {
public:
    explicit GlesTextureState(bool external = false) : external_(external) {
        glGetIntegerv(GL_ACTIVE_TEXTURE, &active_);
        glActiveTexture(GL_TEXTURE0);
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &texture_);
        if (external_) glGetIntegerv(0x8D67, &externalTexture_);
    }

    ~GlesTextureState() {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture_);
        if (external_) glBindTexture(0x8D65, externalTexture_);
        glActiveTexture(active_);
    }

    GlesTextureState(const GlesTextureState&) = delete;
    GlesTextureState& operator=(const GlesTextureState&) = delete;

private:
    GLint active_ = GL_TEXTURE0;
    GLint texture_ = 0;
    GLint externalTexture_ = 0;
    bool external_;
};

class GlesDrawState {
public:
    explicit GlesDrawState(GLuint privateVao, bool external = false) : texture_(external) {
        glGetIntegerv(GL_CURRENT_PROGRAM, &program_);
        glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &buffer_);
        glGetIntegerv(GL_VIEWPORT, viewport_);
        glGetIntegerv(GL_SCISSOR_BOX, scissor_);
        glGetBooleanv(GL_COLOR_WRITEMASK, colorMask_);
        glGetIntegerv(GL_BLEND_SRC_RGB, &srcRgb_);
        glGetIntegerv(GL_BLEND_DST_RGB, &dstRgb_);
        glGetIntegerv(GL_BLEND_SRC_ALPHA, &srcAlpha_);
        glGetIntegerv(GL_BLEND_DST_ALPHA, &dstAlpha_);
        blend_ = glIsEnabled(GL_BLEND);
        depth_ = glIsEnabled(GL_DEPTH_TEST);
        cull_ = glIsEnabled(GL_CULL_FACE);
        stencil_ = glIsEnabled(GL_STENCIL_TEST);
        scissorEnabled_ = glIsEnabled(GL_SCISSOR_TEST);
        bindVao_ = reinterpret_cast<BindVao>(eglGetProcAddress("glBindVertexArray"));
        if (!bindVao_) bindVao_ = reinterpret_cast<BindVao>(eglGetProcAddress("glBindVertexArrayOES"));
        if (bindVao_ && privateVao != 0) {
            glGetIntegerv(0x85B5, &vao_);
            bindVao_(privateVao);
        } else {
            bindVao_ = nullptr;
            // GLES2 without VAOs: preserve every attribute the quad modifies.
            for (GLuint index = 0; index < 4; index++) {
                auto& attribute = attributes_[index];
                glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &attribute.enabled);
                glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &attribute.buffer);
                glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_SIZE, &attribute.size);
                glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_TYPE, &attribute.type);
                glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, &attribute.normalized);
                glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_STRIDE, &attribute.stride);
                glGetVertexAttribPointerv(index, GL_VERTEX_ATTRIB_ARRAY_POINTER, &attribute.pointer);
            }
        }
        glDisable(GL_STENCIL_TEST);
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    }

    ~GlesDrawState() {
        if (bindVao_) bindVao_(vao_);
        else {
            for (GLuint index = 0; index < 4; index++) {
                const auto& attribute = attributes_[index];
                glBindBuffer(GL_ARRAY_BUFFER, attribute.buffer);
                glVertexAttribPointer(index, attribute.size, attribute.type, attribute.normalized,
                    attribute.stride, attribute.pointer);
                if (attribute.enabled) glEnableVertexAttribArray(index);
                else glDisableVertexAttribArray(index);
            }
        }
        glBindBuffer(GL_ARRAY_BUFFER, buffer_);
        glUseProgram(program_);
        glViewport(viewport_[0], viewport_[1], viewport_[2], viewport_[3]);
        glScissor(scissor_[0], scissor_[1], scissor_[2], scissor_[3]);
        glColorMask(colorMask_[0], colorMask_[1], colorMask_[2], colorMask_[3]);
        glBlendFuncSeparate(srcRgb_, dstRgb_, srcAlpha_, dstAlpha_);
        enabled(GL_BLEND, blend_);
        enabled(GL_DEPTH_TEST, depth_);
        enabled(GL_CULL_FACE, cull_);
        enabled(GL_STENCIL_TEST, stencil_);
        enabled(GL_SCISSOR_TEST, scissorEnabled_);
    }

    GlesDrawState(const GlesDrawState&) = delete;
    GlesDrawState& operator=(const GlesDrawState&) = delete;

private:
    using BindVao = void (*)(GLuint);
    struct Attribute {
        GLint enabled = 0, buffer = 0, size = 4, type = GL_FLOAT, normalized = 0, stride = 0;
        void* pointer = nullptr;
    };
    static void enabled(GLenum state, bool value) {
        if (value) glEnable(state);
        else glDisable(state);
    }

    GlesTextureState texture_;
    BindVao bindVao_ = nullptr;
    GLint program_ = 0, buffer_ = 0, vao_ = 0;
    GLint viewport_[4]{}, scissor_[4]{};
    GLint srcRgb_ = GL_ONE, dstRgb_ = GL_ZERO, srcAlpha_ = GL_ONE, dstAlpha_ = GL_ZERO;
    GLboolean colorMask_[4]{};
    bool blend_ = false, depth_ = false, cull_ = false, stencil_ = false, scissorEnabled_ = false;
    Attribute attributes_[4];
};

} // namespace pls
