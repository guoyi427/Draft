//
//  STLManager.h
//  gl_6
//
//  Created by guoyi on 16/1/15.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/gl.h>

@interface STLManager : NSObject

+ (instancetype)stlMananger;

- (int)getStlWithVertice:(GLfloat *)vertice;

@end
