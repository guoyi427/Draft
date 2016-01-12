//
//  ViewController.m
//  gl_3
//
//  Created by guoyi on 16/1/11.
//  Copyright © 2016年 郭毅. All rights reserved.
//

#import "ViewController.h"

#import "OpenGLView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    OpenGLView *glView = [[OpenGLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:glView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
