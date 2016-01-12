//
//  ShaderManager.m
//  gl_2
//
//  Created by guoyi on 16/1/11.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "ShaderManager.h"

@implementation ShaderManager

+ (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"loading shader error %@",error);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        //  编译失败
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"compile shader error %@",messageString);
        exit(1);
    }
    
    return shaderHandle;
}

@end
