//
//  FLSegmentProgressView.m
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/8/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import "FLCircularProgressView.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface FLCircularProgressView ()

@property (nonatomic) NSMutableArray *segments;
@property (nonatomic) NSMutableArray *colors;

@property NSNumber *totalValue;

- (CGFloat)translateDegrees:(int)degree;

@end

@implementation FLCircularProgressView

- (void)awakeFromNib {
	[[NSBundle mainBundle] loadNibNamed:@"FLCircularProgressView" owner:self options:nil];

	// The following is to make sure content view, extends out all the way to fill whatever our view size is even as our view's size is changed by autolayout
	[self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self addSubview:self.contentView];
	[self.contentView setBackgroundColor:[UIColor clearColor]];

	[[self class] addEdgeConstraint:NSLayoutAttributeLeft superview:self subview:self.contentView];
	[[self class] addEdgeConstraint:NSLayoutAttributeRight superview:self subview:self.contentView];
	[[self class] addEdgeConstraint:NSLayoutAttributeTop superview:self subview:self.contentView];
	[[self class] addEdgeConstraint:NSLayoutAttributeBottom superview:self subview:self.contentView];


	self.colors = [[NSMutableArray alloc] initWithCapacity:1];
	self.segments = [[NSMutableArray alloc] initWithCapacity:1];

	
	[self.colors addObject:[UIColor blueColor]];
	[self.colors addObject:[UIColor yellowColor]];
	[self.colors addObject:[UIColor magentaColor]];
	[self.colors addObject:[UIColor cyanColor]];
	[self.colors addObject:[UIColor greenColor]];
    [self.colors addObject:[UIColor redColor]];

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

+ (void)addEdgeConstraint:(NSLayoutAttribute)edge superview:(UIView *)superview subview:(UIView *)subview {
	[superview addConstraint:[NSLayoutConstraint constraintWithItem:subview
	                                                      attribute:edge
	                                                      relatedBy:NSLayoutRelationEqual
	                                                         toItem:superview
	                                                      attribute:edge
	                                                     multiplier:1
	                                                       constant:0]];
}

- (CGColorRef)colorForSegment:(int)segIndex {
	int totalColors = self.colors.count;

	return ((UIColor *)(self.colors[segIndex % totalColors])).CGColor;
}

- (int)currentSegmentIndex {
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
	NSLog(@"Draw Called");

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 6.0);

	for (int index = 0; index < self.segments.count; index++) {
		NSLog(@"Draw For Segment:%d, %f, %f", index, [self startAngleForSegment:index], [self toAngleForSegment:index]);

		CGContextSetStrokeColorWithColor(context, [self colorForSegment:index]);
		CGContextAddArc(context, 50, 50, 40, [self translateDegrees:[self startAngleForSegment:index]], [self translateDegrees:[self toAngleForSegment:index]], 0);
		CGContextStrokePath(context);
	}
}

@end
