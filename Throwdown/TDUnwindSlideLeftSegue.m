//
//  TDUnwindSlideLeftSegue.m
//  Throwdown
//
//  Created by Andrew C on 3/2/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUnwindSlideLeftSegue.h"

@implementation TDUnwindSlideLeftSegue

- (void)perform {

    debug NSLog(@"PERFORM-UnwindSlideLeftSegue");

    [super perform];
    [super dismissSource];

    UIView *sourceView = [self.sourceViewController view];
    self.screenShotDestination.center = CGPointMake(sourceView.center.x - sourceView.frame.size.width, sourceView.center.y);

    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                        self.screenShotDestination.center = CGPointMake(sourceView.center.x, sourceView.center.y);
                        self.screenShotSource.center = CGPointMake(sourceView.center.x + sourceView.frame.size.width, sourceView.center.y);
                     }
                     completion:^(BOOL finished) {
                         [self.screenShotSource removeFromSuperview];
                         [self.screenShotDestination removeFromSuperview];
                         [self.destinationViewController view].hidden = NO;
                     }];
}

@end
