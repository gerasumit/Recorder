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
#import "FLCircularProgressBar.h"

@interface FLRecordingController : UIViewController<FLRecorderDelegate,FLCaptureSessionDelegate>

@property (nonatomic, strong) IBOutlet FLPreviewView *previewView;
@property (nonatomic, strong) IBOutlet FLCircularProgressBar *circularBar;

@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;
@property (nonatomic, strong) IBOutlet UIButton *deleteButton;

-(IBAction)playButtonPressed:(id)sender;
-(IBAction)saveButtonPressed:(id)sender;
-(IBAction)deleteButtonPressed:(id)sender;

@end
