//
//  FLRecordingController.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/4/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLRecordingController.h"
#import "FLRecorder.h"

@interface FLRecordingController ()

@property (nonatomic, strong) FLRecorder *recorderLib;


@end

@implementation FLRecordingController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Ankur's VC"];
    self.recorderLib  = [[FLRecorder alloc] init];
    [self.recorderLib configWithCompletionBlock:nil error:nil];
    [self.recorderLib setDelegate:self];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.recorderLib startCaptureSession];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.recorderLib stopCaptureSession];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
