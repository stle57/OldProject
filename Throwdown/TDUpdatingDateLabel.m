//
//  TDUpdatingDateLabel.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/28/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUpdatingDateLabel.h"
#import "NSDate+TimeAgo.h"
#import "TDAppDelegate.h"

@implementation TDUpdatingDateLabel

@synthesize timeStampUpdateTimer;

- (void)dealloc
{
    self.labelDate = nil;
    [self.timeStampUpdateTimer invalidate];
    self.timeStampUpdateTimer = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    origFrame = self.frame;
}

-(void)setLabelDate:(NSDate *)date
{
    _labelDate = date;

    // Update Timer
    [self startUpdateTimer];
}

#pragma mark - Time Stamp
-(void)startUpdateTimer
{
    if (!self.labelDate || [self.labelDate isKindOfClass:[NSNull class]]) {
        return;
    }

    [self.timeStampUpdateTimer invalidate];
    self.timeStampUpdateTimer = nil;

    self.timeStampUpdateTimer = [NSTimer timerWithTimeInterval:[self workOutTimerGap]
                                                        target:self
                                                      selector:@selector(timeStampUpdate)
                                                      userInfo:nil
                                                       repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.timeStampUpdateTimer forMode:NSRunLoopCommonModes];
}

-(NSTimeInterval)workOutTimerGap
{
    NSTimeInterval interval = fabs([self.labelDate timeIntervalSinceNow]);
    NSTimeInterval seconds = 60.0;  // every minute
    if (interval >= (60*60*24)) {    // Every day
        seconds = (60*60*24);
    } else if (interval >= (60*60)) {    // Every hour
        seconds = (60*60);
    }
    return seconds;
}

-(void)timeStampUpdate
{
    self.frame = origFrame;

    self.text = [self.labelDate timeAgo];
    [TDAppDelegate fixWidthOfThisLabel:self];

    if (self.textAlignment == NSTextAlignmentRight) {
        CGRect timeFrame = self.frame;
        timeFrame.origin.x = CGRectGetMaxX(origFrame)-timeFrame.size.width;
        self.frame = timeFrame;
    }

    // Do again, adjusting interval as necessary
    [self startUpdateTimer];
}


@end
