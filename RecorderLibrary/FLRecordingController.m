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

@property (nonatomic, strong) FLAbstractRecorder *recorderLib;


@end

@implementation FLRecordingController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Ankur's VC"];
    self.recorderLib  = [[FLRecorder alloc] init];
    [self.recorderLib setDelegate:self];
    [self.recorderLib configWithPreviewView:self.previewView completionBlock:nil error:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.recorderLib startCaptureSession];
    [self.recorderLib setTint:100 error:nil];
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
