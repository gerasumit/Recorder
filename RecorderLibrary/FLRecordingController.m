//
//  FLRecordingController.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/4/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLRecordingController.h"
#import "FLRecorder.h"
#import "FLAssetExportSession.h"

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

#pragma -mark Delegate Callbacks
- (void)recordingContextChanged:(BOOL)isRecording{
    if(isRecording){
        [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
        [self.saveButton setHidden:YES];
    }
    else{
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
        [self.saveButton setHidden:NO];
    }
}

-(void)sessionRunningAndDeviceAuthorizedContextChanged:(BOOL)isRunning{
    if(isRunning){
        [self.playButton setHidden:NO];
        [self.saveButton setHidden:NO];
    }
    else{
        [self.playButton setHidden:YES];
        [self.saveButton setHidden:YES];
    }
}

- (void)assetExportCompleted:(NSURL *)assetURL{
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
