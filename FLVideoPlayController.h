//
//  FLVideoPlayController.h
//  RecorderLibrary
//
//  Created by Ankur Kesharwani on 7/8/15.
//  Copyright (c) 2015 SumitGera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLVideoPlayController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong) IBOutlet UIButton *stopButton;

-(IBAction)togglePlay:(id)sender;

@end
