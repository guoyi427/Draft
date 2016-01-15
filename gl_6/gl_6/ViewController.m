//
//  ViewController.m
//  gl_6
//
//  Created by guoyi on 16/1/13.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "ViewController.h"

#import "OpenGLView.h"
#import "STLManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    STLManager *modelManager = [STLManager stlMananger];
    
    
    OpenGLView *glView = [[OpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
