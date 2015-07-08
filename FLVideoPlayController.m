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

@end
