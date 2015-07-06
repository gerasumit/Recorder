//
//  FLRecorder.h
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/4/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLPreviewView.h"
#import <AVFoundation/AVFoundation.h>
#import "FLCaptureSession.h"


/*!
 *  @discussion Classes that use this library must conform to this protocol inorder to get event callbacks.
 */
@protocol FLRecorderDelegate <NSObject>

@optional
/*!
 *  @discussion Called when the decice is not autorized to use the camera.
 */
- (void)deviceNotAuthorized;

/*!
 *  @discussion Called when recording context changes. Use this method to control the states of your recording play/pause buttons and other ui elements.
 *  @param isRecording Is true when recording context changes to true else false.
 */
- (void)recordingContextChanged:(BOOL)isRecording;

/*!
 *  @discussion Called when session context changes. This is not same as the recording context. Use this method to control the states of your recording play/pause buttons and other ui elements.
 *  @param isRunning Is true when session context changes to true else false.
 */
- (void)sessionRunningAndDeviceAuthorizedContextChanged:(BOOL)isRunning;

/*!
 *  @discussion Called when the camera is changed.
 */
- (void)cameraSwitched;

@end


@interface FLRecorder : NSObject

@property (nonatomic, weak) id <FLRecorderDelegate> delegate;
@property (nonatomic, weak) FLPreviewView *previewView;

- (void)configWithCompletionBlock:(void (^)(void))completionBlock error:(void (^)(NSError *error))errorBlock;
- (void)startCaptureSession;
- (void)stopCaptureSession;

- (void)toggleMovieRecording;
- (void)completeRecording;

- (void)setFocusMode:(AVCaptureFocusMode)focusMode error:(void (^)(NSError *error))errorBlock;
- (void)setExposureMode:(AVCaptureExposureMode)expMode error:(void (^)(NSError *error))errorBlock;
- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode error:(void (^)(NSError *error))errorBlock;
- (void)setLensPosition:(int)value error:(void (^)(NSError *error))errorBlock;
- (void)setISO:(int)value error:(void (^)(NSError *error))errorBlock;
- (void)setExposureTargetBias:(int)value error:(void (^)(NSError *error))errorBlock;
- (void)setTemperature:(int)value error:(void (^)(NSError *error))errorBlock;
- (void)setTint:(int)value error:(void (^)(NSError *error))errorBlock;
- (void)lockWithGrayWorldError:(void (^)(NSError *error))errorBlock;
- (void)setWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains error:(void (^)(NSError *error))errorBlock;
- (void)setFlashMode:(AVCaptureFlashMode)flashMode error:(void (^)(NSError *error))errorBlock;
- (void)toggleRecorderMirroringWithCaptureConnection:(AVCaptureConnection *)aCaptureConnection;
- (void)switchCamera;

@end
