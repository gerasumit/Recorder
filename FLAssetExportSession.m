//
//  FLAssetExportSession.m
//  RecorderLibrary
//
//  Created by Sumit Gera on 08/07/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLAssetExportSession.h"

#define EnsureSuccess(error, x) if (error != nil) { _error = error; if (x != nil) x(); return; }
#define kVideoPixelFormatTypeForCI kCVPixelFormatType_32BGRA
#define kVideoPixelFormatTypeDefault kCVPixelFormatType_422YpCbCr8
#define kAudioFormatType kAudioFormatLinearPCM
#define k *1000.0

@interface FLAssetExportSession () {
    AVAssetReader * assetReader;
    AVAssetReaderOutput * assetReaderAudioOutput;
    AVAssetReaderOutput * assetReaderVideoOutput;
    AVAssetWriter * assetWriter;
    AVAssetWriterInput * assetWriterAudioInput;
    AVAssetWriterInput * assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *_videoPixelAdaptor;
    uint32_t _pixelFormat;
    NSError *_error;
    dispatch_queue_t _dispatchQueue;
    dispatch_group_t _dispatchGroup;
    EAGLContext *_eaglContext;
    CIContext *_ciContext;
    CMTime _nextAllowedVideoFrame;
}

@end

@implementation FLAssetExportSession

- (instancetype)initWithAsset:(AVAsset *)asset presetName:(NSString *)presetName {
    self = [super initWithAsset:asset presetName:presetName];
    
    if (self) {
        _dispatchQueue = dispatch_queue_create("me.corsin.EvAssetExportSession", nil);
        _dispatchGroup = dispatch_group_create();
        _useGPUForRenderingFilters = YES;
        _keepVideoTransform = YES;
        _videoTransform = CGAffineTransformIdentity;
        _maxVideoFrameDuration = kCMTimeInvalid;
        _keepVideoSize = YES;
    }
    
    return self;
}

- (AVAssetReaderOutput *)addReader:(AVAssetTrack *)track  withSettings:(NSDictionary*)outputSettings {
    AVAssetReaderOutput *reader = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:outputSettings];
    
    if ([assetReader canAddOutput:reader]) {
        [assetReader addOutput:reader];
    } else {
        NSLog(@"Cannot add input reader %d", kAudioFormatMPEG4AAC);
        reader = nil;
    }
    
    return reader;
}

- (AVAssetWriterInput *)addWriter:(NSString *)mediaType withSettings:(NSDictionary *)outputSettings {
    AVAssetWriterInput *writer = [AVAssetWriterInput assetWriterInputWithMediaType:mediaType outputSettings:outputSettings];
    
    if ([assetWriter canAddInput:writer]) {
        [assetWriter addInput:writer];
    }
    
    return writer;
}

- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer presentationTime:(CMTime)presentationTime {
    if (![_videoPixelAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime]) {
        NSLog(@"Failed to append to pixel buffer");
    }
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (_ciContext != nil) {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        if (_eaglContext == nil) {
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        }
        
        CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIFilter *ciFilter = [self.filterArray objectAtIndex:0];
        [ciFilter setValue:image forKey:kCIInputImageKey];
        CIImage *result = [ciFilter valueForKey:kCIOutputImageKey];
        
        CVPixelBufferRef outputPixelBuffer = nil;
        CVPixelBufferPoolCreatePixelBuffer(NULL, [_videoPixelAdaptor pixelBufferPool], &outputPixelBuffer);
        
        CVPixelBufferLockBaseAddress(outputPixelBuffer, 0);
        
        [_ciContext render:result toCVPixelBuffer:outputPixelBuffer];
        
        [self processPixelBuffer:outputPixelBuffer presentationTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        
        CVPixelBufferUnlockBaseAddress(outputPixelBuffer, 0);
        
        if (_eaglContext == nil) {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        }
        
        CVPixelBufferRelease(outputPixelBuffer);
        outputPixelBuffer = nil;
    } else {
        [assetWriterAudioInput appendSampleBuffer:sampleBuffer];
    }
}

- (void)markInputComplete:(AVAssetWriterInput *)input error:(NSError *)error {
    if (assetReader.status == AVAssetReaderStatusFailed) {
        _error = assetReader.error;
    } else if (error != nil) {
        _error = error;
    }
    
    [input markAsFinished];
}

- (void)beginReadWriteOnInput:(AVAssetWriterInput *)input fromOutput:(AVAssetReaderOutput *)output {
    if (input != nil) {
        dispatch_group_enter(_dispatchGroup);
        [input requestMediaDataWhenReadyOnQueue:_dispatchQueue usingBlock:^{
            while (input.isReadyForMoreMediaData) {
                CMSampleBufferRef buffer = [output copyNextSampleBuffer];
                
                if (buffer != nil) {
                    if (input == assetWriterVideoInput) {
                        CMTime currentVideoTime = CMSampleBufferGetPresentationTimeStamp(buffer);
                        if (CMTIME_COMPARE_INLINE(currentVideoTime, >=, _nextAllowedVideoFrame)) {
                            [self processSampleBuffer:buffer];
                            
                            if (CMTIME_IS_VALID(_maxVideoFrameDuration)) {
                                _nextAllowedVideoFrame = CMTimeAdd(currentVideoTime, _maxVideoFrameDuration);
                            }
                        }
                    } else {
                        [input appendSampleBuffer:buffer];
                    }
                    
                    CFRelease(buffer);
                } else {
                    [self markInputComplete:input error:nil];
                    
                    dispatch_group_leave(_dispatchGroup);
                    break;
                }
            }
        }];
    }
}

- (void)callCompletionHandler:(void (^)())completionHandler {
    if (completionHandler != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler();
        });
    }
}

- (void)setupCoreImage:(AVAssetTrack *)videoTrack {
    if ([self needsCIContext] && assetWriterAudioInput != nil) {
        if (self.useGPUForRenderingFilters) {
            _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        }
        
        if (_eaglContext == nil) {
            NSDictionary *options = @{
                                      kCIContextUseSoftwareRenderer : [NSNumber numberWithBool:YES]
                                      };
            _ciContext = [CIContext contextWithOptions:options];
        } else {
            NSDictionary *options = @{ kCIContextWorkingColorSpace : [NSNull null], kCIContextOutputColorSpace : [NSNull null] };
            
            _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:options];
        }
        
    } else {
        _ciContext = nil;
        _eaglContext = nil;
    }
}

- (BOOL)needsInputPixelBufferAdaptor {
    return _ciContext != nil;
}

+ (NSError*)createError:(NSString*)errorDescription {
    return [NSError errorWithDomain:@"FLAssetExportSession" code:200 userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
}

- (void)setupSettings:(AVAssetTrack *)videoTrack error:(NSError **)error {
    if (self.presetName != nil) {
        int sampleRate = 0;
        int audioBitrate = 0;
        int channels = 0;
        double width = 0;
        double height = 0;
        double videoBitrate = 0;
        
        if (videoTrack != nil && _keepVideoSize) {
            width = videoTrack.naturalSize.width;
            height = videoTrack.naturalSize.height;
        }
        
        // Because Yoda was my master
        if ([FLAssetExportSessionPresetHighestQuality isEqualToString:self.presetName]) {
            sampleRate = 44100;
            audioBitrate = 256 k;
            channels = 2;
            
            if (!_keepVideoSize) {
                width = 1920;
                height = 1080;
            }
            
            videoBitrate = width * height * 4;
        } else if ([FLAssetExportSessionPresetMediumQuality isEqualToString:self.presetName]) {
            sampleRate = 44100;
            audioBitrate = 128 k;
            channels = 2;
            
            if (!_keepVideoSize) {
                width = 1280;
                height = 720;
            }
            
            videoBitrate = width * height;
        } else if ([FLAssetExportSessionPresetLowQuality isEqualToString:self.presetName]) {
            sampleRate = 44100;
            audioBitrate = 64 k;
            channels = 1;
            
            if (!_keepVideoSize) {
                width = 640;
                height = 480;
            }
            
            videoBitrate = width * height / 2;
        } else {
            *error = [FLAssetExportSession createError:@"Unrecognized export preset"];
            return;
        }
        
        if (_audioSettings == nil) {
            _audioSettings = @{
                               AVFormatIDKey : [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                               AVSampleRateKey : [NSNumber numberWithInt:sampleRate],
                               AVEncoderBitRateKey : [NSNumber numberWithInt:audioBitrate],
                               AVNumberOfChannelsKey : [NSNumber numberWithInt:channels]
                               };
            
        }
        if (_videoSettings == nil) {
            _videoSettings = @{
                               AVVideoCodecKey : AVVideoCodecH264,
                               AVVideoWidthKey : [NSNumber numberWithDouble:width],
                               AVVideoHeightKey : [NSNumber numberWithDouble:height],
                               AVVideoCompressionPropertiesKey : @{AVVideoAverageBitRateKey: [NSNumber numberWithDouble:videoBitrate ]}
                               };
        }
    }
}

- (BOOL)needsCIContext {
    return self.filterArray.count > 0;
}

- (void)setupPixelBufferAdaptor:(AVAssetTrack *)videoTrack {
    if ([self needsInputPixelBufferAdaptor] && assetWriterVideoInput != nil) {
        CGSize videoSize = videoTrack.naturalSize;
        NSDictionary *pixelBufferAttributes = @{
                                                (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:_pixelFormat],
                                                (id)kCVPixelBufferWidthKey : [NSNumber numberWithFloat:videoSize.width],
                                                (id)kCVPixelBufferHeightKey : [NSNumber numberWithFloat:videoSize.height]
                                                };
        
        _videoPixelAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:pixelBufferAttributes];
    }
}

- (void)exportAsynchronouslyWithCompletionHandler:(void (^)())completionHandler {
    _nextAllowedVideoFrame = kCMTimeZero;
    NSError *error = nil;
    
    [[NSFileManager defaultManager] removeItemAtURL:self.outputURL error:nil];
    
    assetWriter = [AVAssetWriter assetWriterWithURL:self.outputURL fileType:self.outputFileType error:&error];
    
    EnsureSuccess(error, completionHandler);
    
    assetReader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
    EnsureSuccess(error, completionHandler);
    
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count > 0) {
        assetReaderAudioOutput = [self addReader:[audioTracks objectAtIndex:0] withSettings:@{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatType] }];
    } else {
        assetReaderAudioOutput = nil;
    }
    
    NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = nil;
    if (videoTracks.count > 0) {
        videoTrack = [videoTracks objectAtIndex:0];
        
        _pixelFormat = [self needsCIContext] ? kVideoPixelFormatTypeForCI : kVideoPixelFormatTypeDefault;
        assetReaderVideoOutput = [self addReader:videoTrack withSettings:@{
                                                                 (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:_pixelFormat],
                                                                 (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
                                                                 }];
    } else {
        assetReaderVideoOutput = nil;
    }
    
    [self setupSettings:videoTrack error:&error];
    
    EnsureSuccess(error, completionHandler);
    
    if (assetReaderAudioOutput != nil) {
        assetWriterAudioInput = [self addWriter:AVMediaTypeAudio withSettings:self.audioSettings];
    } else {
        assetWriterAudioInput = nil;
    }
    
    if (assetReaderVideoOutput != nil) {
        assetWriterVideoInput = [self addWriter:AVMediaTypeVideo withSettings:self.videoSettings];
        if (_keepVideoTransform) {
            assetWriterVideoInput.transform = videoTrack.preferredTransform;
        } else {
            assetWriterVideoInput.transform = self.videoTransform;
        }
    } else {
        assetWriterVideoInput = nil;
    }
    
    [self setupCoreImage:videoTrack];
    
    [self setupPixelBufferAdaptor:videoTrack];
    
    if (![assetReader startReading]) {
        EnsureSuccess(assetReader.error, completionHandler);
    }
    
    if (![assetWriter startWriting]) {
        EnsureSuccess(assetWriter.error, completionHandler);
    }
    
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    [self beginReadWriteOnInput:assetWriterVideoInput fromOutput:assetReaderVideoOutput];
    [self beginReadWriteOnInput:assetWriterAudioInput fromOutput:assetReaderAudioOutput];
    
    dispatch_group_notify(_dispatchGroup, _dispatchQueue, ^{
        if (_error == nil) {
            [assetWriter finishWritingWithCompletionHandler:^{
                _error = assetWriter.error;
                [self callCompletionHandler:completionHandler];
            }];
        } else {
            [self callCompletionHandler:completionHandler];
        }
    });
}

- (NSError *)error {
    return _error;
}

- (dispatch_queue_t)dispatchQueue {
    return _dispatchQueue;
}

- (dispatch_group_t)dispatchGroup {
    return _dispatchGroup;
}

- (AVAssetWriterInput *)videoInput {
    return assetWriterVideoInput;
}

- (AVAssetWriterInput *)audioInput {
    return assetWriterAudioInput;
}

- (AVAssetReader *)reader {
    return assetReader;
}

@end
