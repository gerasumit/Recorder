//
//  FLSegmentProgressView.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/8/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLCircularProgressBar.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define PROGRESS_TO_DEGREES(progress) ((progress * 360)/100)
#define DEGREES_TO_PROGRESS(degrees) ((degrees * 100)/360)

@interface Segment : NSObject

@property float angle;
@property float cumulativeSum;

@end

@implementation Segment

@end

@interface FLCircularProgressBar ()
{
    float width;
    float height;
    float centerX;
    float centerY;
    float radius;
}

@property (nonatomic) NSMutableArray *segments;
@property (nonatomic, getter=currentSegmentIndex) unsigned long currentSegmentIndex;


- (CGFloat)translateDegrees:(int)degree;

@end

@implementation FLCircularProgressBar


#pragma mark- Initialization

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }
    [self baseInit];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }
    [self baseInit];
    return self;
}

-(void) baseInit{
    self.segmentColors = [[NSMutableArray alloc] initWithCapacity:1];
    self.segments = [[NSMutableArray alloc] initWithCapacity:1];
    
    [self.segmentColors addObject:[UIColor blueColor]];
    [self.segmentColors addObject:[UIColor yellowColor]];
    [self.segmentColors addObject:[UIColor magentaColor]];
    [self.segmentColors addObject:[UIColor cyanColor]];
    [self.segmentColors addObject:[UIColor greenColor]];
    [self.segmentColors addObject:[UIColor redColor]];
    [self setProgressbarColor:[UIColor greenColor]];
    
    width = self.frame.size.width;
    height = self.frame.size.height;
    centerX = width/2;
    centerY = width/2;
    radius = (width<height?width/2:height/2) - 10;
    
    // Create a first empty segment.
    self.progress = 0;
    Segment *emptySegment  = [[Segment alloc] init];
    emptySegment.angle = PROGRESS_TO_DEGREES(self.progress);
    emptySegment.cumulativeSum = PROGRESS_TO_DEGREES(self.progress);
    [self.segments addObject:emptySegment];

    [self setDrawMode:PROGRESS];
}


#pragma mark- Progress and Segments

-(void)setProgress:(float)progress{
    if(progress>self.progress){
        Segment *currentSegment = self.segments[self.currentSegmentIndex];
        currentSegment.angle = PROGRESS_TO_DEGREES(progress) - currentSegment.cumulativeSum;
        _progress = progress;
    }
    if(self.progress >=100 && [self.delegate respondsToSelector:@selector(progressMaxedOut)]){
        [self.delegate progressMaxedOut];
    }
    
}

-(void)markSegment{
    Segment *currentSegment = self.segments[self.currentSegmentIndex];
    Segment *newSegment = [[Segment alloc] init];
    newSegment.angle = 0;
    newSegment.cumulativeSum = currentSegment.angle + currentSegment.cumulativeSum;
    [self.segments addObject:newSegment];
}

-(void)popSegment{
    Segment *currentSegment = self.segments[self.currentSegmentIndex];
    if(self.currentSegmentIndex==0){
        currentSegment.angle = 0;
        currentSegment.cumulativeSum = 0;
        self.progress = 0;
        return;
    }
    self.progress-=DEGREES_TO_PROGRESS(currentSegment.angle);
    [self.segments removeLastObject];
}


# pragma mark- Helpers

- (CGColorRef)colorForSegment:(int)segIndex {
	unsigned long totalColors = self.segmentColors.count;

	return ((UIColor *)(self.segmentColors[segIndex % totalColors])).CGColor;
}

- (unsigned long)currentSegmentIndex {
	return self.segments.count - 1;
}

- (CGFloat)translateDegrees:(int)degree {
	return (degree - 90);
}

- (CGFloat)startAngleForSegment:(int)segIndex {
	float angle = 0;

	for (int index = 0; index < segIndex; index++) {
		angle += ((NSNumber *)(self.segments[index])).integerValue;
	}
	return angle;
}

- (CGFloat)toAngleForSegment:(int)segIndex {
    float angle = 0;
    
    for (int index = 0; index <= segIndex; index++) {
        angle += ((NSNumber *)(self.segments[index])).integerValue;
    }
    return angle;
}


#pragma mark- Drawing
- (void)drawRect:(CGRect)rect {
    if(self.drawMode == PROGRESS){
        [self drawProgress];
    }
    else{
        [self drawSegments];
    }
}

-(void) drawProgress{
   	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 6.0);

    CGContextSetStrokeColorWithColor(context, self.progressbarColor.CGColor);
    CGContextAddArc(context,
                    centerX,
                    centerY,
                    radius,
                    DEGREES_TO_RADIANS([self translateDegrees: 0]),
                    DEGREES_TO_RADIANS([self translateDegrees:PROGRESS_TO_DEGREES(self.progress)]), 0);
    CGContextStrokePath(context);
}

-(void) drawSegments{
   	CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 6.0);
    
    for (int index = 0; index < self.segments.count; index++) {
        Segment *thisSegment = self.segments[index];

        CGContextSetStrokeColorWithColor(context, [self colorForSegment:index]);
        CGContextAddArc(context,
                        centerX,
                        centerY,
                        radius,
                        DEGREES_TO_RADIANS([self translateDegrees:thisSegment.cumulativeSum]),
                        DEGREES_TO_RADIANS([self translateDegrees:(thisSegment.cumulativeSum + thisSegment.angle)]), 0);
        CGContextStrokePath(context);
    }
}

@end
