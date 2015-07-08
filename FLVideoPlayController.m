//
//  FLVideoPlayController.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/8/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLVideoPlayController.h"
#import "FLFilterVideoPlayer.h"
#import <GLKit/GLKit.h>
#import "FLAssetExportSession.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface FLVideoPlayController ()<FLFilterVideoPlayerDelegate>

@property (nonatomic) FLFilterVideoPlayer *filterVideoPlayer;

@end

@implementation FLVideoPlayController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.filterVideoPlayer = [[FLFilterVideoPlayer alloc] init];

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    GLKView *pView = [self.filterVideoPlayer setEAGLContext:self.view.bounds];
    [self.view addSubview:pView];
    [self.view sendSubviewToBack:pView];
    
    
    [self.filterVideoPlayer setCIContext];
    [self.filterVideoPlayer config];
    NSURL *mediaUrl = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"];
    [self.filterVideoPlayer loadVideoFromUrl:mediaUrl completionBlock:nil error:nil];
}

-(IBAction)togglePlay:(id)sender{
    [self.filterVideoPlayer play];
    FLAssetExportSession * assetExportSession = [[FLAssetExportSession alloc] initWithAsset:[AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"video" withExtension:@"mp4"]] presetName:FLAssetExportSessionPresetHighestQuality];
    assetExportSession.filterArray = [NSArray arrayWithObjects:[CIFilter filterWithName:@"CISepiaTone"
                                                                          keysAndValues:kCIInputIntensityKey, @0.8, nil], nil];
    assetExportSession.outputFileType = AVFileTypeMPEG4;
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"videomerged.mp4"];
    assetExportSession.outputURL = [NSURL fileURLWithPath:filePath];
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        
        if (assetExportSession.error == nil) {
            ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:assetExportSession.outputURL completionBlock:nil];
            //            completionHandler(assetExportSession.outputURL, assetExportSession.error);
        } else {
            NSLog(@"Something bad happened");
        }
    }];
}

-(void)playerStatusChanged:(BOOL)readyToPlay{
    if(readyToPlay){
        [self.playButton setHidden:NO];
        [self.stopButton setHidden:NO];
        [self.timeLabel setHidden:NO];
    }else{
        [self.playButton setHidden:YES];
        [self.stopButton setHidden:YES];
        [self.timeLabel setHidden:YES];
    }
}

-(void)onTimeUpdate:(CMTime)cmTime{
    
}

@end
