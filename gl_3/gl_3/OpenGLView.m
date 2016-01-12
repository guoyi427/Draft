//
//  OpenGLView.m
//  gl_3
//
//  Created by guoyi on 16/1/11.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "OpenGLView.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#import "ShaderManager.h"
#import "GLESUtils.h"
#import "ksMatrix.h"

@interface OpenGLView ()
{
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    
    GLuint _positionSlot;
    GLuint _modelViewSlot;
    GLuint _projectionSlot;
    
    ksMatrix4 _modelViewMatrix;
    ksMatrix4 _projectionMatrix;
    
    float _touchPosition;
    float _angle;
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
        [self setupProjection];
        
        [self setupBuffer];
        [self updateTransform];
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
        NSLog(@"create EAGLContext error");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"set Current Context Error");
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
    [EAGLContext setCurrentContext:_context];
    
    glDeleteBuffers(1, &_colorRenderBuffer);
    _colorRenderBuffer = 0;
    glDeleteBuffers(1, &_frameBuffer);
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
        //  链接程序失败
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"link program error %@",messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "vPosition");
    _modelViewSlot = glGetUniformLocation(programHandle, "modelView");
    _projectionSlot = glGetUniformLocation(programHandle, "projection");
}

- (void)setupProjection {
    float aspect = self.bounds.size.width / self.bounds.size.height;
    ksMatrixLoadIdentity(&_projectionMatrix);
    ksPerspective(&_projectionMatrix, 60.0f, aspect, 1.0f, 20.0f);
    glUniformMatrix4fv(_projectionSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
}

- (void)updateTransform {
    ksMatrixLoadIdentity(&_modelViewMatrix);
    /*
     _posX = 0.0;
     _posY = 0.0;
     _posZ = -5.5;
     
     _scaleZ = 1.0;
     _rotateX = 0.0;
     */
    ksMatrixTranslate(&_modelViewMatrix, 0.0, 0.0, -5.5);
    ksMatrixRotate(&_modelViewMatrix, _angle, 1.0, 1.0, 1.0);
    ksMatrixScale(&_modelViewMatrix, 1.0, 1.0, 1.0);
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
}

- (void)render {
    glClearColor(0.5, 0.1, 0.2, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    GLfloat vertices[] = {
        //  前
        0.5,    0.5,    0.5,//0
        0.5,    -0.5,   0.5,//1
        -0.5,   -0.5,   0.5,//2
        -0.5,   0.5,    0.5,//3

        //  右
        0.5,    0.5,    -0.5,//4
        0.5,    -0.5,   -0.5,//5
        
        //  上
        -0.5,   0.5,    -0.5,//6
        
        //  左
        -0.5,   -0.5,   -0.5,//7
        
    };
    
    GLubyte indices[] = {
        0,1,1,2,2,3,3,0,    //前
        0,4,4,5,5,1,        //右
        4,6,6,3,            //上
        6,7,7,2,            //左
        7,5,                //下
    };
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(_positionSlot);
    
    glDrawElements(GL_LINES, sizeof(indices) / sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Touch Delegate

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchPosition = [touches.anyObject locationInView:self].y;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [touches.anyObject locationInView:self];
    float offset = point.y - _touchPosition;
    NSLog(@"offset = %f",offset);
    _angle = offset;
    [self updateTransform];
    [self render];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

@end
