//
//  FLPreviewView.h
//  RecorderLibrary
//
//  Created by Sumit Gera on 04/07/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVCaptureSession;

@interface FLPreviewView : UIView

@property (nonatomic) AVCaptureSession * session;

@end
