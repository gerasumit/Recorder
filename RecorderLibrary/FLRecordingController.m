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
    [self.recorderLib initializeWithPreviewView:self.previewView andDelegate:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.recorderLib startSession];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.recorderLib stopSession];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
