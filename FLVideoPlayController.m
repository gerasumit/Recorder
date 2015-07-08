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

- (void) exportVideoAsset: (AVAsset *) videoAsset filterArray: (NSArray *) filterArray outputURL: (NSURL *) outputURL outputFileType: (NSString *) outputFileType andAssetExportSessionPreset: (NSString *) assetExportSessionPreset {
    
    // videoAsset: Expected AVAsset with video and audio Tracks
    // filterArray: NSArray with CIFilters to be applied in cascaded fashion
    // outputURL: Required filePath of the exported video
    // outputFileType: Required fileType
    // assetExportSessionPreset: Required session preset at which video is to be exported
    
    FLAssetExportSession * assetExportSession = [[FLAssetExportSession alloc] initWithAsset:videoAsset presetName:assetExportSessionPreset];
    
    assetExportSession.filterArray = filterArray;
    assetExportSession.outputFileType = outputFileType;
    assetExportSession.outputURL = outputURL;
    [assetExportSession exportAsynchronouslyWithCompletionHandler: ^{
        
        if (assetExportSession.error == nil) {
            NSLog(@"Video exported successfully! URL : %@", assetExportSession.outputURL);
        } else {
            NSLog(@"Something bad happened");
        }
    }];
}

@end
