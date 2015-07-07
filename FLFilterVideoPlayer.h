//
//  FLFilterVideoPlayer.h
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/7/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>

@protocol FLFilterVideoPlayerDelegate <NSObject>

@required
-(void)playerStatusChanged:(BOOL)readyToPlay;

@optional
-(void)onTimeUpdate:(CMTime)cmTime;

@end

@interface FLFilterVideoPlayer : NSObject
@property (nonatomic, weak) id<FLFilterVideoPlayerDelegate> delegate;

- (void)config;
-(GLKView*)setEAGLContext:(CGRect)rect;
-(void)setCIContext;

- (void)addTimeObserverToPlayer;
- (void)removeTimeObserverFromPlayer;
-(void)loadVideoFromUrl:(NSURL *)videoUrl completionBlock:(void (^)(void))completionBlock error:(void (^)(NSError *error))errorBlock;



-(void) play;
-(void) pause;
-(void) stop;

@end
