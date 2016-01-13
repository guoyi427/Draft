//
//  OpenGLView.m
//  gl_5
//
//  Created by guoyi on 16/1/12.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "OpenGLView.h"

#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>
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
    GLuint _sourceColorSlot;
    GLuint _projectionSlot;
    GLuint _modelViewSlot;
    
    ksMatrix4 _projectionMatrix;
    ksMatrix4 _modelViewMatrix;
    ksMatrix4 _modelViewMatrix_1;
    ksMatrix4 _modelViewMatrix_2;
    
    CGPoint _touchPoint;
    float _offset;
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
        [self setupBuffer];
        [self setupProgram];
        [self setupProjection];
        
        [self render];
        self.backgroundColor = [UIColor yellowColor];
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

- (void)setupBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupProgram {
    GLuint vertextShader = [ShaderManager compileShader:@"VertexShader" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [ShaderManager compileShader:@"FragmentShader" withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    
    glAttachShader(programHandle, vertextShader);
    glAttachShader(programHandle, fragmentShader);
    
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"program link faile %@",messageString);
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
    ksPerspective(&_projectionMatrix, 100.0f, self.bounds.size.width / self.bounds.size.height, 1.0f, 20.0f);
    
    glUniformMatrix4fv(_projectionSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
    
    glEnable(GL_CULL_FACE);
}

- (void)updateTransform1WithOffset:(float)offset {
    ksMatrixLoadIdentity(&_modelViewMatrix_1);
    ksMatrixTranslate(&_modelViewMatrix_1, 0, 0, -5.5f);
    ksMatrixRotate(&_modelViewMatrix_1, offset, 0, 1, 0);
    ksMatrixCopy(&_modelViewMatrix, &_modelViewMatrix_1);
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
}

- (void)updateTransform2WithOffset:(float)offset {
    
    ksMatrixCopy(&_modelViewMatrix_2, &_modelViewMatrix_1);
    ksMatrixRotate(&_modelViewMatrix_2, offset, 1, 0, 0);
    ksMatrixCopy(&_modelViewMatrix, &_modelViewMatrix_2);
    
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
}

- (void)drawRectangle1 {
    GLfloat vertices[] = {
        -1.0,   0.5,    0.5,    1.0,    0.0,    0.0,    1.0,
        1.0,    0.5,    0.5,    0.0,    1.0,    0.0,    1.0,
        1.0,    -0.5,   0.5,    0.0,    1.0,    1.0,    1.0,
        -1.0,   -0.5,   0.5,    0.0,    0.0,    1.0,    1.0,
        
        -1.0,   0.5,    -0.5,    0.0,    1.0,    1.0,    1.0,
        1.0,    0.5,    -0.5,    0.0,    0.0,    1.0,    1.0,
        1.0,    -0.5,   -0.5,    1.0,    0.0,    0.0,    1.0,
        -1.0,   -0.5,   -0.5,    0.0,    1.0,    0.0,    1.0,
    };
    
    GLubyte indices[] = {
        //  front
        1,0,2,  2,0,3,
        //  back
        4,5,6,  4,6,7,
        //  left
        0,4,3,  3,4,7,
        //  right
        5,1,2,  2,6,5,
        //  top
        0,1,5,  0,5,4,
        //  bottom
        3,6,2,  3,7,6
        
    };
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 7, vertices);
    glVertexAttribPointer(_sourceColorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 7, vertices + 3);
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_sourceColorSlot);
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}

- (void)drawRectangle2 {
    GLfloat vertices[] = {
        1.5,   0.5,    0.5,    1.0,    0.0,    0.0,    1.0,
        3.5,    0.5,    0.5,    0.0,    1.0,    0.0,    1.0,
        3.5,    -0.5,   0.5,    0.0,    1.0,    1.0,    1.0,
        1.5,   -0.5,   0.5,    0.0,    0.0,    1.0,    1.0,
        
        1.5,   0.5,    -0.5,    0.0,    1.0,    1.0,    1.0,
        3.5,    0.5,    -0.5,    0.0,    0.0,    1.0,    1.0,
        3.5,    -0.5,   -0.5,    1.0,    0.0,    0.0,    1.0,
        1.5,   -0.5,   -0.5,    0.0,    1.0,    0.0,    1.0,
    };
    
    GLubyte indices[] = {
        //  front
        1,0,2,  2,0,3,
        //  back
        4,5,6,  4,6,7,
        //  left
        0,4,3,  3,4,7,
        //  right
        5,1,2,  2,6,5,
        //  top
        0,1,5,  0,5,4,
        //  bottom
        3,6,2,  3,7,6
        
    };
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 7, vertices);
    glVertexAttribPointer(_sourceColorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 7, vertices + 3);
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_sourceColorSlot);
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
}

- (void)render {
    glClearColor(0.1, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self updateTransform1WithOffset:_offset];
    [self drawRectangle1];
    [self updateTransform2WithOffset:_offset];
    [self drawRectangle2];
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Touch Delegate

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchPoint = [touches.anyObject locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint originPoint = [touches.anyObject locationInView:self];
    _offset = originPoint.y - _touchPoint.y;
    
    
    [self render];
}


@end
