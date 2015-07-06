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

@interface FLRecordingController : UIViewController<FLRecorderDelegate,FLCaptureSessionDelegate>

@property (nonatomic, strong) IBOutlet FLPreviewView *previewView;

@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;

-(IBAction)playButtonPressed:(id)sender;
-(IBAction)saveButtonPressed:(id)sender;
@end
