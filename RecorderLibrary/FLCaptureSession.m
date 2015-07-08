//
//  FLCaptureSession.m
//  RecorderLibrary
//
//  Created by Sumit Gera on 04/07/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLCaptureSession.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface FLCaptureSession () {
	AVMutableComposition *mixComposition;
}

@end

@implementation FLCaptureSession

- (instancetype)init {
	self = [super init];

	if (self) {
		videoSegments = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)addSegmentWithURL:(NSURL *)url {
	[videoSegments addObject:url.path];
}

- (void)removeSegmentWithURL:(NSURL *)url {
	[videoSegments removeObject:url.path];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:url.path error:NULL];
}

- (NSUInteger)getCurrentSegmentIndex {
	if (videoSegments != nil) {
		return [videoSegments count];
	}
	else {
		videoSegments = [[NSMutableArray alloc] init];
		return [videoSegments count];
	}
}

- (NSURL *)getCompleteVideoWithAudioAsset:(AVAsset *)audioAsset {
	NSURL *mergedVideoURL = [[NSURL alloc] init];
	mixComposition = [[AVMutableComposition alloc] init];
    
	AVMutableCompositionTrack *mainTrackVideo = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
	                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *mainTrackAudio = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
    
	for (NSString *path in videoSegments) {
		NSURL *videoURL = [NSURL fileURLWithPath:path];
		AVURLAsset *currentVideoSegment = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        
        
        
		NSLog(@"%@", [currentVideoSegment tracksWithMediaType:AVMediaTypeVideo]);
		if (currentVideoSegment != nil) {
			[mainTrackVideo insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentVideoSegment.duration)
			                   ofTrack:[[currentVideoSegment tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:mainTrackVideo.timeRange.duration error:nil];
            [mainTrackAudio insertTimeRange:CMTimeRangeMake(kCMTimeZero, currentVideoSegment.duration)
                               ofTrack:[[currentVideoSegment tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:mainTrackAudio.timeRange.duration error:nil];
		}
        
        AVAssetTrack * currentTrack = [[currentVideoSegment tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] ;
        if (currentTrack && mainTrackVideo) {
            [mainTrackVideo setPreferredTransform:currentTrack.preferredTransform];
        }
        
	}

	if (audioAsset != nil) {
		AVMutableCompositionTrack *AudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
		                                                                    preferredTrackID:kCMPersistentTrackID_Invalid];
		[AudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, mainTrackAudio.timeRange.duration)
		                    ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
	}

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
	                         [NSString stringWithFormat:@"mergeVideo-%d.mov", arc4random() % 1000]];
	NSURL *url = [NSURL fileURLWithPath:myPathDocs];
	// 5 - Create exporter
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
	                                                                  presetName:AVAssetExportPresetHighestQuality];
	exporter.outputURL = url;
	exporter.outputFileType = AVFileTypeQuickTimeMovie;
	exporter.shouldOptimizeForNetworkUse = NO;
	[exporter exportAsynchronouslyWithCompletionHandler: ^{
	    [self exportDidFinish:exporter];

	    for (int i = 0; i < videoSegments.count; i++) {
	        [self removeSegmentWithURL:[NSURL URLWithString:videoSegments[i]]];
		}
	}];

	return mergedVideoURL;
    

    
}

- (void)exportDidFinish:(AVAssetExportSession *)session {
	if (session.status == AVAssetExportSessionStatusCompleted) {
		NSURL *outputURL = session.outputURL;
		ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
		if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
			[library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock: ^(NSURL *assetURL, NSError *error) {
			    dispatch_async(dispatch_get_main_queue(), ^{
					if (error) {
					    if ([self.delegate respondsToSelector:@selector(assetExportFailedWithError:)])
							[self.delegate assetExportFailedWithError:error];
					}
					else {
                        if ([self.delegate respondsToSelector:@selector(assetExportCompleted:)]) {
                            [self.delegate assetExportCompleted: outputURL];
						}
					}
				});
			}];
		}
	}
}


@end
