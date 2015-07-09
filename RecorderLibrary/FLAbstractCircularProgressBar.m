//
//  FLSegmentProgressView.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/8/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLAbstractCircularProgressBar.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface FLAbstractCircularProgressBar ()
{
    float width;
    float height;
    float centerX;
    float centerY;
    float radius;
}

@property (nonatomic) NSMutableArray *segments;
@property (nonatomic) NSMutableArray *colors;

- (CGFloat)translateDegrees:(int)degree;

@end

@implementation FLAbstractCircularProgressBar

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
    self.colors = [[NSMutableArray alloc] initWithCapacity:1];
    self.segments = [[NSMutableArray alloc] initWithCapacity:1];
    
    [self.colors addObject:[UIColor blueColor]];
    [self.colors addObject:[UIColor yellowColor]];
    [self.colors addObject:[UIColor magentaColor]];
    [self.colors addObject:[UIColor cyanColor]];
    [self.colors addObject:[UIColor greenColor]];
    [self.colors addObject:[UIColor redColor]];
    
    width = self.frame.size.width;
    height = self.frame.size.height;
    centerX = width/2;
    centerY = width/2;
    radius = (width<height?width/2:height/2) - 10;
    
    [self.segments addObject:[NSNumber numberWithInt:30]];
    [self.segments addObject:[NSNumber numberWithInt:10]];
    [self.segments addObject:[NSNumber numberWithInt:5]];
    [self.segments addObject:[NSNumber numberWithInt:15]];
    [self.segments addObject:[NSNumber numberWithInt:30]];
    [self.segments addObject:[NSNumber numberWithInt:10]];
    [self.segments addObject:[NSNumber numberWithInt:5]];
    [self.segments addObject:[NSNumber numberWithInt:15]];
    [self.segments addObject:[NSNumber numberWithInt:30]];
    [self.segments addObject:[NSNumber numberWithInt:10]];
    [self.segments addObject:[NSNumber numberWithInt:5]];
    [self.segments addObject:[NSNumber numberWithInt:15]];
    [self.segments addObject:[NSNumber numberWithInt:30]];
    [self.segments addObject:[NSNumber numberWithInt:10]];
    [self.segments addObject:[NSNumber numberWithInt:5]];
    [self.segments addObject:[NSNumber numberWithInt:15]];
    [self.segments addObject:[NSNumber numberWithInt:5]];
    [self.segments addObject:[NSNumber numberWithInt:15]];
    [self.segments addObject:[NSNumber numberWithInt:30]];
    [self.segments addObject:[NSNumber numberWithInt:10]];
    [self.segments addObject:[NSNumber numberWithInt:5]];
    [self.segments addObject:[NSNumber numberWithInt:15]];
}

- (CGColorRef)colorForSegment:(int)segIndex {
	unsigned long totalColors = self.colors.count;

	return ((UIColor *)(self.colors[segIndex % totalColors])).CGColor;
}

- (unsigned long)currentSegmentIndex {
	return self.segments.count - 1;
}

- (CGFloat)translateDegrees:(int)degree {
	return DEGREES_TO_RADIANS(degree - 90);
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

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 6.0);

	for (int index = 0; index < self.segments.count; index++) {
		CGContextSetStrokeColorWithColor(context, [self colorForSegment:index]);
		CGContextAddArc(context, centerX, centerY, radius, [self translateDegrees:[self startAngleForSegment:index]], [self translateDegrees:[self toAngleForSegment:index]], 0);
		CGContextStrokePath(context);
	}
}

@end
