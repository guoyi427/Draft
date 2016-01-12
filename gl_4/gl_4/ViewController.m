//
//  ViewController.m
//  gl_4
//
//  Created by guoyi on 16/1/12.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "ViewController.h"

#import "OpenGLView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    OpenGLView *glView = [[OpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
