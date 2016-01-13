//
//  ShaderManager.h
//  gl_5
//
//  Created by guoyi on 16/1/12.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/gl.h>

@interface ShaderManager : NSObject

+ (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType;

@end
