//
//  FLAssetExportSession.h
//  RecorderLibrary
//
//  Created by Sumit Gera on 08/07/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

#define FLAssetExportSessionPresetHighestQuality AVAssetExportPresetHighestQuality
#define FLAssetExportSessionPresetMediumQuality AVAssetExportPresetMediumQuality
#define FLAssetExportSessionPresetLowQuality AVAssetExportPresetLowQuality

@interface FLAssetExportSession : AVAssetExportSession

@property (nonatomic) BOOL useGPUForRenderingFilters;
@property (nonatomic) BOOL keepVideoTransform;
@property (nonatomic) CGAffineTransform videoTransform;
@property (nonatomic) CMTime maxVideoFrameDuration;
@property (nonatomic) BOOL keepVideoSize;
@property (strong, nonatomic) NSArray * filterArray;
@property (strong, nonatomic) NSDictionary *audioSettings;
@property (strong, nonatomic) NSDictionary *videoSettings;


- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(void))completionHandler;

@end
