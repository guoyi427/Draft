//
//  OpenGLView.m
//  gl_6
//
//  Created by guoyi on 16/1/15.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "OpenGLView.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#import "ShaderManager.h"
#import "ksMatrix.h"
#import "GLESUtils.h"

@interface OpenGLView ()
{
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    
    GLuint _positionSlot;
    GLuint _sourceColorSlot;
    GLuint _projectionSlot;
    GLuint _modelViewSlot;
    
    ksMatrix4 _projectionMatrix;
    ksMatrix4 _modelViewMatrix;
}

@end

@implementation OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupBuffers];
        [self setupProgram];
        [self setupProjection];
        [self render];
    }
    return self;
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = @{
                                      kEAGLDrawablePropertyRetainedBacking : @NO,
                                      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
                                      };
}

- (void)setupContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        NSLog(@"create EAGLContext faile");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"set Current Context faile");
        exit(1);
    }
}

- (void)setupBuffers {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupProgram {
    GLuint vertexShader = [ShaderManager compileShader:@"VertexShader" andType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [ShaderManager compileShader:@"FragmentShader" andType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"program link faile = %@",messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "vPosition");
    _sourceColorSlot = glGetAttribLocation(programHandle, "vSourceColor");
    _projectionSlot = glGetUniformLocation(programHandle, "projection");
    _modelViewSlot = glGetUniformLocation(programHandle, "modelView");
}

- (void)setupProjection {
    ksMatrixLoadIdentity(&_projectionMatrix);
    ksPerspective(&_projectionMatrix, 100, self.bounds.size.width / self.bounds.size.height, 1, 20);
    
    glUniformMatrix4fv(_projectionSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
    glEnable(GL_CULL_FACE);
}

- (void)updateTransform {
    ksMatrixLoadIdentity(&_modelViewMatrix);
    ksMatrixTranslate(&_modelViewMatrix, 0, 0, -5.5);
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
}

- (void)drawGraph {
    GLfloat vertices[] = {
        0.5,    0.5,    0.5,    1.0,    0.0,    0.0,    1.0,
        -0.5,   0.5,    0.5,    0.0,    1.0,    0.0,    1.0,
        -0.5,   -0.5,   0.5,    0.0,    1.0,    1.0,    1.0,
        0.5,    -0.5,   0.5,    0.0,    0.0,    1.0,    1.0,
    };
    
    GLubyte indices[] = {
        0,1,2, 2,3,0
    };
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 7, vertices);
    glVertexAttribPointer(_sourceColorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 7, vertices + 3);
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_sourceColorSlot);
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}

- (void)render {
    glClearColor(0.6, 0.1, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self updateTransform];
    [self drawGraph];
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
