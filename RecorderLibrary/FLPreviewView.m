//
//  FLPreviewView.m
//  RecorderLibrary
//
//  Created by Sumit Gera on 04/07/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation FLPreviewView

+ (Class) layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
    [(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
