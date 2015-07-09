//
//  FLFilterVideoPlayer.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/7/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLFilterVideoPlayer.h"
#import <GLKit/GLKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

# define ONE_FRAME_DURATION 1.0

static void *PlayerStatusContext= &PlayerStatusContext;

@interface FLFilterVideoPlayer ()<AVPlayerItemOutputPullDelegate>
{
    dispatch_queue_t myVideoOutputQueue;
    id notificationToken;
    id timeObserver;
    
    
    GLKView *_videoPreviewView;
    CIContext *_ciContext;
    EAGLContext *_eaglContext;
    CGRect _videoPreviewViewBounds;
}

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property AVPlayerItemVideoOutput *videoOutput;
@property CADisplayLink *displayLink;

- (void)displayLinkCallback:(CADisplayLink *)sender;

@end

@implementation FLFilterVideoPlayer

- (void)config{
    self.player = [[AVPlayer alloc] init];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
    [[self displayLink] addToRunLoop:[NSRunLoop currentRunLoop]forMode:NSDefaultRunLoopMode];
    [[self displayLink] setPaused:YES];
    
    // Setup AVPlayerItemVideoOutput with the required pixelbuffer attributes.
    NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    [[self videoOutput] setDelegate:self queue:myVideoOutputQueue];
}

-(GLKView*)setEAGLContext:(CGRect)rect{
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _videoPreviewView = [[GLKView alloc] initWithFrame:rect context:_eaglContext];
    _videoPreviewView.enableSetNeedsDisplay = NO;
    _videoPreviewView.frame = rect;
    _videoPreviewViewBounds = rect;
    return _videoPreviewView;
}

-(void)setCIContext{
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
    [_videoPreviewView bindDrawable];
    _videoPreviewViewBounds = CGRectZero;
    _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
    _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;
}

- (void)addTimeObserverToPlayer
{
    [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:PlayerStatusContext];
    if (timeObserver)
        return;
    __weak FLFilterVideoPlayer* weakSelf = self;
    timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if([weakSelf.delegate respondsToSelector:@selector(onTimeUpdate:)]){
            [weakSelf.delegate onTimeUpdate:time];
        }
    }];
}

- (void)removeTimeObserverFromPlayer
{
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:PlayerStatusContext];
    if (timeObserver)
    {
        [self.player removeTimeObserver:timeObserver];
        timeObserver = nil;
    }
}

-(void)loadVideoFromUrl:(NSURL *)videoUrl completionBlock:(void (^)(void))completionBlock error:(void (^)(NSError *error))errorBlock{
    
    [[self.player currentItem] removeOutput:self.videoOutput];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    NSString *tracksKey = @"tracks";
    
    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            if (status == AVKeyValueStatusLoaded) {
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                
                [self.playerItem addObserver:self forKeyPath:@"status"
                                     options:NSKeyValueObservingOptionInitial context:&PlayerStatusContext];
                
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:self.playerItem];
                
                [self.playerItem addOutput:self.videoOutput];
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
                [self.videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];

            }
            else {
                errorBlock(error);
                return;
            }
        });
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == &PlayerStatusContext) {
        dispatch_async(dispatch_get_main_queue(),^{
            if (self.player.currentItem == nil && ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
                [self.delegate playerStatusChanged:YES];
            }
            else {
                [self.delegate playerStatusChanged:NO];
            }
        });
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    
    return;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
}

- (void)play {
    if(self.player.currentItem.status == AVPlayerItemStatusReadyToPlay){
        [self.player play];
    }
}

- (void)pause {
    if(self.player.currentItem.status == AVPlayerItemStatusReadyToPlay){
        [self.player pause];
    }
}

- (void)stop {
    if(self.player.currentItem.status == AVPlayerItemStatusReadyToPlay){
        [self.player pause];
        [self.player seekToTime:kCMTimeZero];
    }
}

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    /*
     * The callback gets called once every Vsync. 
     * Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy
     * the pixel buffer for that time This pixel buffer can then be processed and later rendered on screen.
     */
    CMTime outputItemTime = kCMTimeInvalid;
    
    // Calculate the nextVsync time which is when the screen will be refreshed next.
    CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
    
    outputItemTime = [[self videoOutput] itemTimeForHostTime:nextVSync];
    
    if ([[self videoOutput] hasNewPixelBufferForItemTime:outputItemTime]) {
        CVPixelBufferRef pixelBuffer = NULL;
        pixelBuffer = [[self videoOutput] copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];

        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:pixelBuffer options:nil];
        
        CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"
                                      keysAndValues: kCIInputImageKey, sourceImage,
                            @"inputIntensity", @0.8, nil];
        
        CIImage *outputImage = [filter outputImage];
        // You should apply filters here.
        
        
        // Render
        [_videoPreviewView bindDrawable];
        [_ciContext drawImage:outputImage inRect:_videoPreviewViewBounds fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
        [_videoPreviewView display];
        
        // This should be done even under ARC.
        CVPixelBufferRelease(pixelBuffer);
    }
}

#pragma mark - AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    // Restart display link.
    [[self displayLink] setPaused:NO];
}


@end
