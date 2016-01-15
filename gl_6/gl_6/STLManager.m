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
        [self _prepareData];
    }
    return self;
}

- (void)_prepareData {
    NSString *stlPath = [[NSBundle mainBundle] pathForResource:@"RevolvedModel" ofType:@"stl"];
   
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:stlPath];
    
    unsigned long long fileSize = [fileHandle seekToEndOfFile];
    
    NSLog(@"stl file size = %llu \n",fileSize);
    
    [fileHandle seekToFileOffset:0];
    
    NSData *subfixData = [fileHandle readDataOfLength:SubfixSize];
    NSString *subfixDataString = [[NSString alloc] initWithData:subfixData encoding:NSUTF8StringEncoding];
    NSLog(@"subfix Data = %@",subfixDataString);
    
    unsigned long long stripeCount = (fileSize - SubfixSize - 4) / FaceStructSize;
    
    NSLog(@"stripe count = %llu",stripeCount);
    
    for (int stripe = 0; stripe < stripeCount; stripe ++) {
        NSData *stripeData = [fileHandle readDataOfLength:FaceStructSize];
        
        FaceStruct face = {};
        [stripeData getBytes:&face length:FaceStructSize];
        
        NSLog(@"face %f %f %f",
              face.v1.x,face.v1.y,face.v1.z

              );
    }
    
    [fileHandle closeFile];
}

@end
