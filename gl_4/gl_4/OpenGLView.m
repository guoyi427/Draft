//
//  OpenGLView.m
//  gl_4
//
//  Created by guoyi on 16/1/12.
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
    GLuint _projectionSlot;
    GLuint _modelViewSlot;
    GLuint _sourceColorSlot;
    
    ksMatrix4 _projectionMatrix;
    ksMatrix4 _modelViewMatrix;
    
    float _touchPosition;
    float _angle;
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
        NSLog(@"set current context faile");
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
    GLuint vertexShader = [ShaderManager compileShader:@"VertexShader" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [ShaderManager compileShader:@"FragmentShader" withType:GL_FRAGMENT_SHADER];
    
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
        NSLog(@"link program faile %@",messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "vPosition");
    _projectionSlot = glGetUniformLocation(programHandle, "projection");
    _modelViewSlot = glGetUniformLocation(programHandle, "modelView");
    _sourceColorSlot = glGetAttribLocation(programHandle, "vSourceColor");
}

- (void)setupProjection {
    float aspect = self.bounds.size.width / self.bounds.size.height;
    ksMatrixLoadIdentity(&_projectionMatrix);
    /*  
     *第一个参数 projection指针  
     *第二个参数 屏幕所能放下的单位数量越多 值越大就可以了
     *第三个参数 长宽比
     *第四个参数 屏幕近端z轴
     *第五个参数 屏幕远端z轴
     */
    ksPerspective(&_projectionMatrix, 60.0f, aspect, 1.0f, 20.0f);
    
    glUniformMatrix4fv(_projectionSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);

    glEnable(GL_CULL_FACE);// 关闭背面渲染
}

- (void)updateTransform {
    ksMatrixLoadIdentity(&_modelViewMatrix);
    ksMatrixTranslate(&_modelViewMatrix, 0.0f, 0.0f, -5.5f);
    ksMatrixRotate(&_modelViewMatrix, _angle, 1.0f, 1.0f, 1.0f);
    
    glUniformMatrix4fv(_modelViewSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
}

- (void)render {
    glClearColor(0.0, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    GLfloat vertices[] = {
        -0.5f,  0.5f,   0.5f,   1.0f,   0.0f,   0.0f,   1.0f,   //0
        0.5f,   0.5f,   0.5f,   0.0f,   1.0f,   0.0f,   1.0f,   //1
        0.5f,   -0.5f,  0.5f,   0.0f,   1.0f,   1.0f,   1.0f,   //2
        -0.5f,  -0.5f,  0.5f,   0.0f,   0.0f,   1.0f,   1.0f,   //3
        
        -0.5f,  0.5f,   -0.5f,  0.0f,   1.0f,   1.0f,   1.0f,   //4
        0.5f,   0.5f,   -0.5f,  0.0f,   0.0f,   1.0f,   1.0f,   //5
        0.5f,   -0.5f,  -0.5f,  1.0f,   0.0f,   0.0f,   1.0f,   //6
        -0.5f,  -0.5f,  -0.5f,  0.0f,   1.0f,   0.0f,   1.0f    //7
    };
    
    GLubyte indices[] = {
        //  前
        0,2,1, 0,3,2,
        //  后
        4,5,7, 7,5,6,
        //  左
        0,4,7, 0,7,3,
        //  右
        1,6,5, 1,2,6,
        //  上
        4,0,1, 4,1,5,
        //  下
        3,7,2, 7,6,2
    };
    
    [self updateTransform];
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 7, vertices);
    glVertexAttribPointer(_sourceColorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 7, vertices + 3);
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_sourceColorSlot);
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, indices);
    glDisableVertexAttribArray(_sourceColorSlot);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - Touch Delegate

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchPosition = [touches.anyObject locationInView:self].y;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    float point_y = [touches.anyObject locationInView:self].y;
    float offset = point_y - _touchPosition;
    _angle = offset;
    
    [self updateTransform];
    [self render];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

@end
