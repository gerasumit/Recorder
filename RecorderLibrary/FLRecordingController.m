//
//  FLRecordingController.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/4/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLRecordingController.h"
#import "FLRecorder.h"

@interface FLRecordingController ()<FLCircularProgressBarDelegate>
{
    NSTimer *tickTickTimer;
    NSDate *tickTickTimerPauseStart, *tickTickTimerPreviousFireDate;
    
    //NSTimer *nintySecTimer;
    //NSDate *nintySecTimerPauseStart, *nintySecTimerPreviousFireDate;
    
    float progress;
    
    float time;
}

@property (nonatomic, strong) FLAbstractRecorder *recorderLib;

@end

@implementation FLRecordingController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Ankur's VC"];
    self.recorderLib  = [[FLRecorder alloc] init];
    [self.recorderLib setDelegate:self];
    [self.recorderLib configWithPreviewView:self.previewView completionBlock:nil error:nil];
    
    [self.playButton setHidden:NO];
    [self.deleteButton setHidden:YES];
    [self.saveButton setHidden:YES];
    
    self.circularBar.delegate  = self;
    
    time =0.0;
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.recorderLib startCaptureSession];
    [self.recorderLib.flCaptureSession setDelegate:self];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.recorderLib stopCaptureSession];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(IBAction)playButtonPressed:(id)sender{
    [self.recorderLib toggleMovieRecording];
}

-(IBAction)saveButtonPressed:(id)sender{
    [self.recorderLib completeRecordingWithAsset:nil];
}

-(IBAction)deleteButtonPressed:(id)sender{
    // TODO: Implement me.
}

-(void)timerTick{
    
    time += 0.1;
    progress+=(1.0/9);
    NSLog(@"Tick %f", time);

    [self.circularBar setProgress:progress];
    [self.circularBar setNeedsDisplay];
    
    
}

-(void)progressMaxedOut{
    [tickTickTimer invalidate];
    [self.recorderLib toggleMovieRecording];
    [self.recorderLib completeRecordingWithAsset:nil];
}


#pragma -mark Delegate Callbacks
- (void)recordingContextChanged:(BOOL)isRecording{
    if(isRecording){
        [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
    else{
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    }
}

-(void)sessionRunningAndDeviceAuthorizedContextChanged:(BOOL)isRunning{
    if(isRunning){
        [self.playButton setHidden:NO];
    }else{
        [self.playButton setHidden:YES];
        [self.deleteButton setHidden:YES];
        [self.saveButton setHidden:YES];
    }
}


-(void) recordingStarted{
    [self.deleteButton setHidden:YES];
    [self.saveButton setHidden:YES];
    
    time=0.0;
    progress =0.0;
    
    // Start the timers.
    tickTickTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerTick) userInfo:nil repeats:YES];


}

-(void) recordingResumed{
    [self.deleteButton setHidden:YES];
    [self.saveButton setHidden:YES];
    self.circularBar.drawMode = PROGRESS;
    [self.circularBar setNeedsDisplay];
    
    // Resume the timer.
    float pauseTime1 = -1*[tickTickTimerPauseStart timeIntervalSinceNow];
    [tickTickTimer setFireDate:[NSDate dateWithTimeInterval:pauseTime1 sinceDate:tickTickTimerPreviousFireDate]];

}

-(void) recordingPaused{
    [self.deleteButton setHidden:NO];
    [self.saveButton setHidden:NO];
    self.circularBar.drawMode = SEGMENTS;
    [self.circularBar setNeedsDisplay];
    
    // Pause the timer;
    tickTickTimerPauseStart = [NSDate dateWithTimeIntervalSinceNow:0];
    tickTickTimerPreviousFireDate = [tickTickTimer fireDate];
    [tickTickTimer setFireDate:[NSDate distantFuture]];

}

-(void) recordingEnded{
    [self.playButton setHidden:NO];
    [self.deleteButton setHidden:YES];
    [self.saveButton setHidden:YES];
}

- (void) segmentCreated{
    [self.circularBar markSegment];
}



#pragma mark-  Alert Box methods
- (void)assetExportCompleted{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Success"
                                          message:@"Video saved successfuly."
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   NSLog(@"OK action");
                               }];
    
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)assetExportFailedWithError:(NSError *)anError{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Failure"
                                          message:@"Video not saved."
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   NSLog(@"OK action");
                               }];
    
    [alertController addAction:okAction];
    
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
