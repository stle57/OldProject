//
//  TDSlideUpSegue.m
//  Throwdown
//
//  Created by Andrew C on 7/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSlideUpSegue.h"

@implementation TDSlideUpSegue

- (void)perform {
    debug NSLog(@"PERFORM-SlideUpSegue");

    [super perform];
    [super popDestination];

    // Set and start animations
    self.screenShotSource.transform = CGAffineTransformMakeScale(1, 1);
    CGPoint origDestinationCenter = self.screenShotDestination.center;
    CGPoint destinationCenter = self.screenShotDestination.center;
    destinationCenter.y = destinationCenter.y * 3;
    self.screenShotDestination.center = destinationCenter;

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.screenShotDestination.center = origDestinationCenter;
                         self.screenShotSource.transform = CGAffineTransformMakeScale(0.95, 0.95);
                     }
                     completion:^(BOOL finished){
                         [self.screenShotSource removeFromSuperview];
                         [self.screenShotDestination removeFromSuperview];
                         [self.destinationViewController view].hidden = NO;
                     }];
}

@end
