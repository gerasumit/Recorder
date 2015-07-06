//
//  FLCaptureSession.h
//  RecorderLibrary
//
//  Created by Sumit Gera on 04/07/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#define FLCaptureSessionPreset352x288 AVCaptureSessionPreset352x288
#define FLCaptureSessionPreset640x480 AVCaptureSessionPreset640x480
#define FLCaptureSessionPreset1280x720 AVCaptureSessionPreset1280x720
#define FLCaptureSessionPreset1920x1080 AVCaptureSessionPreset1920x1080

#define FLCaptureSessionRuntimeErrorNotification AVCaptureSessionRuntimeErrorNotification


@protocol FLCaptureSessionDelegate <NSObject>

- (void)assetExportCompleted;
- (void)assetExportFailedWithError:(NSError *)anError;

@end

@interface FLCaptureSession : AVCaptureSession {
	NSMutableArray *videoSegments;
}

@property (nonatomic, weak) id <FLCaptureSessionDelegate> delegate;

- (NSUInteger)getCurrentSegmentIndex;

- (void)addSegmentWithURL:(NSURL *)url;
- (void)removeSegmentWithURL:(NSURL *)url;

- (NSURL *)getCompleteVideoWithAudioAsset:(AVAsset *)audioAsset;

@end
