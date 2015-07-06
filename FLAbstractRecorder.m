//
//  FLRecorder.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/4/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLAbstractRecorder.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "FLPreviewView.h"
#import <AVFoundation/AVFoundation.h>
#import "FLCaptureSession.h"

static void *RecordingContext = &RecordingContext;
static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface FLAbstractRecorder () <AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
	AVCaptureInput *flCaptureInput;
	AVCaptureOutput *flCaptureOutput;
	AVCaptureDevice *flCaptureDevice;
	NSMutableArray *segments;
}
@end

@implementation FLAbstractRecorder

#pragma -mark Initializations & Setup

- (void)configWithPreviewView:(FLPreviewView *)previewView completionBlock:(void (^)(void))completionBlock error:(void (^)(NSError *error))errorBlock {
	// Create the FLCaptureSession
	FLCaptureSession *session = [[FLCaptureSession alloc] init];
	[self setFlCaptureSession:session];

	[self setPreviewView:previewView];
	[self.previewView setSession:session];

	// Check for device authorization
	[self checkDeviceAuthorizationStatus];

	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];

	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];

		NSError *error = nil;

		AVCaptureDevice *videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

		if (error) {
		    dispatch_async(dispatch_get_main_queue(), ^{
				if (errorBlock != nil)
					errorBlock(error);
			});
		    NSLog(@"FLRecorder Error %@", error);
		    return;
		}

		if ([session canAddInput:videoDeviceInput]) {
		    [session addInput:videoDeviceInput];
		    [self setVideoDeviceInput:videoDeviceInput];
		    dispatch_async(dispatch_get_main_queue(), ^{
				[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
			});
		}

		AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
		AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];

		if (error) {
		    dispatch_async(dispatch_get_main_queue(), ^{
				if (errorBlock != nil)
					errorBlock(error);
			});
		    NSLog(@"FLRecorder Error %@", error);
		    return;
		}

		if ([session canAddInput:audioDeviceInput]) {
		    [session addInput:audioDeviceInput];
		}

		AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
		if ([session canAddOutput:movieFileOutput]) {
		    [session addOutput:movieFileOutput];
		    AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];

		    // Showing warning as the method is deprecated in 8.0
		    if ([connection isVideoStabilizationSupported])
				[connection setEnablesVideoStabilizationWhenAvailable:YES];
		    [self setMovieFileOutput:movieFileOutput];
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			if (completionBlock != nil)
				completionBlock();
		});
	});
}

- (void)startCaptureSession {
	dispatch_async([self sessionQueue], ^{
		[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
		[self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];

		__weak FLAbstractRecorder *weakSelf = self;
		[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:FLCaptureSessionRuntimeErrorNotification object:[self flCaptureSession] queue:nil usingBlock: ^(NSNotification *note) {
		    FLAbstractRecorder *strongSelf = weakSelf;
		    dispatch_async([strongSelf sessionQueue], ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[[strongSelf flCaptureSession] startRunning];
			});
		}]];
		[[self flCaptureSession] startRunning];
	});
}

- (void)stopCaptureSession {
	dispatch_async([self sessionQueue], ^{
		[[self flCaptureSession] stopRunning];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];

		[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
		[self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
	});
}


#pragma -mark Recording

- (void)toggleMovieRecording {
	dispatch_async([self sessionQueue], ^{
		if (![[self movieFileOutput] isRecording]) {
		    [self setLockInterfaceRotation:YES];

		    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
		        // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
		        [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
			}

		    // Update the orientation on the movie file output video connection before starting recording.
		    [[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];

		    // Turning OFF flash for video recording
		    [self setFlashMode:AVCaptureFlashModeOff error:nil];


		    // Add segments here
		    // Start recording to a temporary file.
		    NSUInteger segmentIndex = [self.flCaptureSession getCurrentSegmentIndex];
		    NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSString stringWithFormat:@"movieseg%lu", (unsigned long)segmentIndex] stringByAppendingPathExtension:@"mov"]];
		    [[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
		}
		else {
		    [[self movieFileOutput] stopRecording];
		    [self.flCaptureSession addSegmentWithURL:[self movieFileOutput].outputFileURL];

		    AVCaptureMovieFileOutput *oldFileOutput = self.movieFileOutput;
		    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
		    if ([self.flCaptureSession canAddOutput:movieFileOutput]) {
		        [self.flCaptureSession addOutput:movieFileOutput];
		        AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];

		        // Showing warning as the method is deprecated in 8.0
		        if ([connection isVideoStabilizationSupported])
					[connection setEnablesVideoStabilizationWhenAvailable:YES];
		        [self setMovieFileOutput:movieFileOutput];
			}
		    NSLog(@"%@", oldFileOutput);
		}
	});
}

- (void)completeRecording {
	[self.flCaptureSession getCompleteVideoWithAudioAsset:nil];
}


#pragma -mark Utilities

- (void)setFocusMode:(AVCaptureFocusMode)focusMode error:(void (^)(NSError *error))errorBlock {
	NSError *error = nil;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	if ([device lockForConfiguration:&error]) {
		if ([device isFocusModeSupported:focusMode]) {
			[device setFocusMode:focusMode];
		}
		else {
			NSLog(@"FLRecorder Error: Focus mode %@ is not supported. Focus mode is %@.", [self stringFromFocusMode:focusMode], [self stringFromFocusMode:device.focusMode]);
			dispatch_async(dispatch_get_main_queue(), ^{
				if (errorBlock != nil)
					errorBlock(error);
			});
		}
		[device unlockForConfiguration];
	}
	else {
		NSLog(@"FLRecorder Error: %@", error);
		dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}
}

- (void)setExposureMode:(AVCaptureExposureMode)expMode error:(void (^)(NSError *error))errorBlock {
	NSError *error = nil;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	if ([device lockForConfiguration:&error]) {
		if ([device isExposureModeSupported:expMode]) {
			[device setExposureMode:expMode];
		}
		else {
			NSLog(@"FLRecorder Error: Exposure mode %@ is not supported. Exposure mode is %@.", [self stringFromExposureMode:expMode], [self stringFromExposureMode:device.exposureMode]);
			dispatch_async(dispatch_get_main_queue(), ^{
				if (errorBlock != nil)
					errorBlock(error);
			});
		}
		[device unlockForConfiguration];
	}
	else {
		NSLog(@"%@", error);
		dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}
}

- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode error:(void (^)(NSError *error))errorBlock {
	NSError *error = nil;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	if ([device lockForConfiguration:&error]) {
		if ([device isWhiteBalanceModeSupported:whiteBalanceMode]) {
			[device setWhiteBalanceMode:whiteBalanceMode];
		}
		else {
			NSLog(@"White balance mode %@ is not supported. White balance mode is %@.", [self stringFromWhiteBalanceMode:whiteBalanceMode], [self stringFromWhiteBalanceMode:device.whiteBalanceMode]);
		}
		[device unlockForConfiguration];
	}
	else {
		NSLog(@"%@", error);
		dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}
}

- (void)setLensPosition:(int)value error:(void (^)(NSError *error))errorBlock {
	NSError *error = nil;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	if ([device lockForConfiguration:&error]) {
		[device setFocusModeLockedWithLensPosition:value completionHandler:nil];
		[device unlockForConfiguration];
	}
	else {
		NSLog(@"%@", error);
		dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}
}

- (void)setISO:(int)value error:(void (^)(NSError *error))errorBlock {
	NSError *error = nil;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	if ([device lockForConfiguration:&error]) {
		[device setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:value completionHandler:nil];
		[device unlockForConfiguration];
	}
	else {
		NSLog(@"%@", error);
		dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}
}

- (void)setExposureTargetBias:(int)value error:(void (^)(NSError *error))errorBlock {
	NSError *error = nil;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	if ([device lockForConfiguration:&error]) {
		[device setExposureTargetBias:value completionHandler:nil];
		[device unlockForConfiguration];
	}
	else {
		NSLog(@"%@", error);
		dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}
}

- (void)setTemperature:(int)value error:(void (^)(NSError *error))errorBlock {
	AVCaptureDevice *device = self.videoDeviceInput.device;
	AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
		.temperature = value,
		.tint = value,
	};

	[self setWhiteBalanceGains:[device deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint] error: ^(NSError *error) {
	    dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}];
}

- (void)setTint:(int)value error:(void (^)(NSError *error))errorBlock {
	AVCaptureDevice *device = self.videoDeviceInput.device;
	AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
		.temperature = value,
		.tint = value,
	};
	[self setWhiteBalanceGains:[device deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint] error: ^(NSError *error) {
	    dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}];
}

- (void)lockWithGrayWorldError:(void (^)(NSError *error))errorBlock {
	AVCaptureDevice *device = self.videoDeviceInput.device;
	[self setWhiteBalanceGains:device.grayWorldDeviceWhiteBalanceGains error: ^(NSError *error) {
	    dispatch_async(dispatch_get_main_queue(), ^{
			if (errorBlock != nil)
				errorBlock(error);
		});
	}];
}

- (void)setWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains error:(void (^)(NSError *error))errorBlock {
	NSError *error = nil;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	if ([device lockForConfiguration:&error]) {
		AVCaptureWhiteBalanceGains normalizedGains = [self normalizedGains:gains]; // Conversion can yield out-of-bound values, cap to limits
		[device setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:normalizedGains completionHandler:nil];
		[device unlockForConfiguration];
	}
	else {
		NSLog(@"%@", error);
		if (errorBlock != nil)
			errorBlock(error);
	}
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode error:(void (^)(NSError *error))errorBlock {
	NSError *error = nil;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	if ([device hasFlash] && [device isFlashModeSupported:flashMode]) {
		if ([device lockForConfiguration:&error]) {
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else {
			NSLog(@"%@", error);
			if (errorBlock != nil)
				errorBlock(error);
		}
	}
}

- (void)toggleRecorderMirroringWithCaptureConnection:(AVCaptureConnection *)aCaptureConnection {
	// Check whether capture connection supports mirroring

	if (aCaptureConnection.isVideoMirroringSupported) {
		if (aCaptureConnection.isVideoMirrored) {
			[aCaptureConnection setVideoMirrored:NO];
		}
		else {
			[aCaptureConnection setVideoMirrored:YES];
		}
	}
}

- (void)switchCamera {
	AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
	AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
	AVCaptureDevicePosition currentPosition = [currentVideoDevice position];

	switch (currentPosition) {
		case AVCaptureDevicePositionUnspecified:
			preferredPosition = AVCaptureDevicePositionFront;
			break;

		case AVCaptureDevicePositionBack:
			preferredPosition = AVCaptureDevicePositionFront;
			break;

		case AVCaptureDevicePositionFront:
			preferredPosition = AVCaptureDevicePositionBack;
			break;
	}

	AVCaptureDevice *videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
	AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];

	[[self flCaptureSession] beginConfiguration];

	[[self flCaptureSession] removeInput:[self videoDeviceInput]];
	if ([[self flCaptureSession] canAddInput:videoDeviceInput]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];

		[self setFlashMode:AVCaptureFlashModeAuto error:nil];


		[[self flCaptureSession] addInput:videoDeviceInput];
		[self setVideoDeviceInput:videoDeviceInput];
	}
	else {
		[[self flCaptureSession] addInput:[self videoDeviceInput]];
	}

	[[self flCaptureSession] commitConfiguration];
}


#pragma -mark Observers for KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == RecordingContext) {
		BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];

		dispatch_async(dispatch_get_main_queue(), ^{
			if ([self.delegate respondsToSelector:@selector(recordingContextChanged:)]) {
			    [self.delegate recordingContextChanged:isRecording];
			}
		});
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext) {
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];

		dispatch_async(dispatch_get_main_queue(), ^{
			if ([self.delegate respondsToSelector:@selector(sessionRunningAndDeviceAuthorizedContextChanged:)]) {
			    [self.delegate sessionRunningAndDeviceAuthorizedContextChanged:isRunning];
			}
		});
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma -mark Delegate Callbacks

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
	if (error)
		NSLog(@"%@", error);

	[self setLockInterfaceRotation:NO];

	// Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
	UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];

	[[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock: ^(NSURL *assetURL, NSError *error) {
	    if (error)
			NSLog(@"%@", error);

	    if (backgroundRecordingID != UIBackgroundTaskInvalid)
			[[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
	}];
}


#pragma -mark Helpers

- (void)setOptimumSessionPreset:(FLCaptureSession *)aCaptureSession {
	NSArray *devices = [AVCaptureDevice devices];

	for (AVCaptureDevice *device in devices) {
		if ([device hasMediaType:AVMediaTypeVideo]) {
			if ([aCaptureSession canSetSessionPreset:FLCaptureSessionPreset1920x1080])
				[aCaptureSession setSessionPreset:FLCaptureSessionPreset1920x1080];
			else if ([aCaptureSession canSetSessionPreset:FLCaptureSessionPreset1280x720])
				[aCaptureSession setSessionPreset:FLCaptureSessionPreset1280x720];
			else if ([aCaptureSession canSetSessionPreset:FLCaptureSessionPreset640x480])
				[aCaptureSession setSessionPreset:FLCaptureSessionPreset640x480];
			else if ([aCaptureSession canSetSessionPreset:FLCaptureSessionPreset352x288])
				[aCaptureSession setSessionPreset:FLCaptureSessionPreset352x288];
			else
				NSLog(@"Error: Failed to set SessionPreset!");
		}
		else
			NSLog(@"Error: No Camera Found!");
	}
}

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];

	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			captureDevice = device;
			break;
		}
	}

	return captureDevice;
}

- (void)checkDeviceAuthorizationStatus {
	NSString *mediaType = AVMediaTypeVideo;

	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler: ^(BOOL granted) {
	    if (granted) {
	        //Granted access to mediaType
	        [self setDeviceAuthorized:YES];
		}
	    else {
	        [self setDeviceAuthorized:NO];

	        //Not granted access to mediaType
	        dispatch_async(dispatch_get_main_queue(), ^{
				// Notify the delegate that the device is not autorized to use the camera.
				if ([self.delegate respondsToSelector:@selector(deviceNotAuthorized)]) {
				    [self.delegate deviceNotAuthorized];
				}
			});
		}
	}];
}

- (NSString *)stringFromFocusMode:(AVCaptureFocusMode)focusMode {
	NSString *string = @"INVALID FOCUS MODE";

	if (focusMode == AVCaptureFocusModeLocked) {
		string = @"Locked";
	}
	else if (focusMode == AVCaptureFocusModeAutoFocus) {
		string = @"Auto";
	}
	else if (focusMode == AVCaptureFocusModeContinuousAutoFocus) {
		string = @"ContinuousAuto";
	}

	return string;
}

- (NSString *)stringFromExposureMode:(AVCaptureExposureMode)exposureMode {
	NSString *string = @"INVALID EXPOSURE MODE";

	if (exposureMode == AVCaptureExposureModeLocked) {
		string = @"Locked";
	}
	else if (exposureMode == AVCaptureExposureModeAutoExpose) {
		string = @"Auto";
	}
	else if (exposureMode == AVCaptureExposureModeContinuousAutoExposure) {
		string = @"ContinuousAuto";
	}
	else if (exposureMode == AVCaptureExposureModeCustom) {
		string = @"Custom";
	}

	return string;
}

- (NSString *)stringFromWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode {
	NSString *string = @"INVALID WHITE BALANCE MODE";

	if (whiteBalanceMode == AVCaptureWhiteBalanceModeLocked) {
		string = @"Locked";
	}
	else if (whiteBalanceMode == AVCaptureWhiteBalanceModeAutoWhiteBalance) {
		string = @"Auto";
	}
	else if (whiteBalanceMode == AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance) {
		string = @"ContinuousAuto";
	}

	return string;
}

- (AVCaptureWhiteBalanceGains)normalizedGains:(AVCaptureWhiteBalanceGains)gains {
	AVCaptureWhiteBalanceGains g = gains;
	AVCaptureDevice *device = self.videoDeviceInput.device;
	g.redGain = MAX(1.0, g.redGain);
	g.greenGain = MAX(1.0, g.greenGain);
	g.blueGain = MAX(1.0, g.blueGain);

	g.redGain = MIN(device.maxWhiteBalanceGain, g.redGain);
	g.greenGain = MIN(device.maxWhiteBalanceGain, g.greenGain);
	g.blueGain = MIN(device.maxWhiteBalanceGain, g.blueGain);

	return g;
}

@end
