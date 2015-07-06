//
//  FLRecorder.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/6/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLRecorder.h"

@implementation FLRecorder

- (void)setFocusMode:(AVCaptureFocusMode)focusMode error:(void (^)(NSError *))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setFocusMode:focusMode error:errorBlock];
	});
}

- (void)setExposureMode:(AVCaptureExposureMode)expMode error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setExposureMode:expMode error:errorBlock];
	});
}

- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setWhiteBalanceMode:whiteBalanceMode error:errorBlock];
	});
}

- (void)setLensPosition:(int)value error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setLensPosition:value error:errorBlock];
	});
}

- (void)setISO:(int)value error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setISO:value error:errorBlock];
	});
}

- (void)setExposureTargetBias:(int)value error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setExposureTargetBias:value error:errorBlock];
	});
}

- (void)setTemperature:(int)value error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setTemperature:value error:errorBlock];
	});
}

- (void)setTint:(int)value error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setTint:value error:errorBlock];
	});
}

- (void)lockWithGrayWorldError:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super lockWithGrayWorldError:errorBlock];
	});
}

- (void)setWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setWhiteBalanceGains:gains error:errorBlock];
	});
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode error:(void (^)(NSError *error))errorBlock {
	dispatch_async([self sessionQueue], ^{
		[super setFlashMode:flashMode error:errorBlock];
	});
}

- (void)toggleRecorderMirroringWithCaptureConnection:(AVCaptureConnection *)aCaptureConnection {
	dispatch_async([self sessionQueue], ^{
		[super toggleRecorderMirroringWithCaptureConnection:aCaptureConnection];
	});
}

- (void)switchCamera {
	dispatch_async([self sessionQueue], ^{
		[super switchCamera];
	});
}

@end
