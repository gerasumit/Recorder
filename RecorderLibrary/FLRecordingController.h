//
//  FLRecordingController.h
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/4/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLPreviewView.h"
#import "FLAbstractRecorder.h"

@interface FLRecordingController : UIViewController<FLRecorderDelegate>

@property (nonatomic, strong) IBOutlet FLPreviewView *previewView;

@end
