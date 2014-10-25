//
//  TDSlideLeftSegue.m
//  Throwdown
//
//  Created by Andrew C on 2/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSlideLeftSegue.h"

@implementation TDSlideLeftSegue

- (void)perform {

    debug NSLog(@"PERFORM-SlideLeftSegue");

    [super perform];
    [super presentDestination];

    UIView *sourceView = [self.sourceViewController view];
    self.screenShotDestination.center = CGPointMake(sourceView.center.x + sourceView.frame.size.width, sourceView.center.y);
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.screenShotDestination.center = CGPointMake(sourceView.center.x, sourceView.center.y);
                         self.screenShotSource.center = CGPointMake(sourceView.center.x - sourceView.frame.size.width, sourceView.center.y);

                     }
                     completion:^(BOOL finished){
                         [self.screenShotSource removeFromSuperview];
                         [self.screenShotDestination removeFromSuperview];
                         [self.destinationViewController view].hidden = NO;
                     }];
}

@end
