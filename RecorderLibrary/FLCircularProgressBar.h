//
//  FLSegmentProgressView.h
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/8/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DrawMode) {
    PROGRESS,
    SEGMENTS,
};

@protocol FLCircularProgressBarDelegate <NSObject>

-(void)progressMaxedOut;

@end

@interface FLCircularProgressBar : UIView

@property (nonatomic, weak) id<FLCircularProgressBarDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, strong) NSMutableArray *segmentColors;
@property (nonatomic, strong) UIColor *progressbarColor;
@property (nonatomic, setter=setProgress:) float progress; // Measured in percentage.
@property (nonatomic) DrawMode *drawMode;

-(void)baseInit;
-(void)markSegment;
-(void)popSegment;

@end
