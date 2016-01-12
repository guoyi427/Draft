//
//  OpenGLView.m
//  gl_2
//
//  Created by guoyi on 16/1/11.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "OpenGLView.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "ShaderManager.h"

@interface OpenGLView ()
{
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    
    GLuint _positionSlot;
}

@end

@implementation OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupProgram];
    }
    return self;
}

- (void)layoutSubviews {
    [EAGLContext setCurrentContext:_context];
    [self destoryBuffer];
    [self setupBuffer];
    [self render];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"creat openglContext faile");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"set currentContext faile");
        exit(1);
    }
}

- (void)setupBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)destoryBuffer {
    glDeleteBuffers(1, &_colorRenderBuffer);
    glDeleteBuffers(1, &_frameBuffer);
    _colorRenderBuffer = 0;
    _frameBuffer = 0;
}

- (void)setupProgram {
    GLuint vertexShader = [ShaderManager compileShader:@"VertexShader" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [ShaderManager compileShader:@"FragmentShader" withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        //  链接程序 失败
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"link program error %@",messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "vPosition");
}

- (void)render {
    glClearColor(0.2, 0.1, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    GLfloat vertices[] = {
        -0.5f,  0.5f,   0.0f,
        -0.5,   -0.5f,  0.0f,
        0.5f,   -0.5f,  0.0f,
        0.5f,   0.5f,   0.0f,
        -0.5,   0.5,    0.0,
        0.5,    -0.5,   0.0,
        -0.5,   0.5,    0.0,
        0,      0.7,    0.0,
        0.5,    0.5,    0.0
    };
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(_positionSlot);
    
    glDrawArrays(GL_TRIANGLES, 0, 9);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
