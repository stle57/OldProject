//
//  TDSlideDownSegue.m
//  Throwdown
//
//  Created by Andrew C on 7/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSlideDownSegue.h"

@implementation TDSlideDownSegue

- (void)perform {
    debug NSLog(@"PERFORM-SlideDownSegue");

    [super perform];
    [super presentDestination];

    // Set and start animations
    self.screenShotDestination.transform = CGAffineTransformMakeScale(0.95, 0.95);
    CGPoint sourceCenter = self.screenShotSource.center;
    sourceCenter.y = sourceCenter.y * 3;

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.screenShotSource.center = sourceCenter;
                         self.screenShotDestination.transform = CGAffineTransformMakeScale(1, 1);
                     }
                     completion:^(BOOL finished){
                         [self.screenShotSource removeFromSuperview];
                         [self.screenShotDestination removeFromSuperview];
                         [self.destinationViewController view].hidden = NO;
                     }];
}

@end
