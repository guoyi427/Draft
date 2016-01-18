//
//  STLManager.m
//  gl_6
//
//  Created by guoyi on 16/1/15.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "STLManager.h"

#import <GLKit/GLKit.h>

/// stl文件前缀长度
static const NSUInteger SubfixSize = 80;
/// 结构体大小
static const size_t FaceStructSize = 50.0f;

/// stl 结构体
typedef struct FaceStruct {
    GLKVector3 normal;
    GLKVector3 v1;
    GLKVector3 v2;
    GLKVector3 v3;
    u_int16_t attrib;
} FaceStruct;


@implementation STLManager

+ (instancetype)stlMananger {
    STLManager *m_stl = [[STLManager alloc] init];
    return m_stl;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (int)getStlWithVertice:(GLfloat *)vertice {
    NSString *stlPath = [[NSBundle mainBundle] pathForResource:@"RevolvedModel 4" ofType:@"stl"];
   
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:stlPath];
    
    unsigned long long fileSize = [fileHandle seekToEndOfFile];
    
    NSLog(@"stl file size = %llu \n",fileSize);
    
    [fileHandle seekToFileOffset:0];
    
    NSData *subfixData = [fileHandle readDataOfLength:SubfixSize];
    NSString *subfixDataString = [[NSString alloc] initWithData:subfixData encoding:NSUTF8StringEncoding];
    NSLog(@"subfix Data = %@",subfixDataString);
    
    unsigned long long stripeCount = (fileSize - SubfixSize - 4) / FaceStructSize;
    
    NSLog(@"stripe count = %llu",stripeCount);
    int vertexCount = 0;
    
    for (int stripe = 0; stripe < stripeCount; stripe ++) {
        NSData *stripeData = [fileHandle readDataOfLength:FaceStructSize];
        
        FaceStruct face = {};
        [stripeData getBytes:&face length:FaceStructSize];
        
        vertice[stripe * 9] =       face.v1.x;
        vertice[stripe * 9 + 1] =   face.v1.y;
        vertice[stripe * 9 + 2] =   face.v1.z;
        
        vertice[stripe * 9 + 3] =   face.v2.x;
        vertice[stripe * 9 + 4] =   face.v2.y;
        vertice[stripe * 9 + 5] =   face.v2.z;
        
        vertice[stripe * 9 + 6] =   face.v2.x;
        vertice[stripe * 9 + 7] =   face.v3.y;
        vertice[stripe * 9 + 8] =   face.v3.z;
        
        vertexCount += 9;
    }
    
    [fileHandle closeFile];
    return vertexCount;
}

@end
