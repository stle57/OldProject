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

    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;

    // Create screenshot for animation
    UIGraphicsBeginImageContextWithOptions(sourceViewController.view.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [sourceViewController.view.layer renderInContext:context];
    UIImageView *screenShotSource = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(destinationViewController.view.bounds.size, NO, 0.0);
    context = UIGraphicsGetCurrentContext();
    [destinationViewController.view.layer renderInContext:context];
    UIImageView *screenShotDestination = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();

    // Put destination view controller and screen shot in place
    UIView *sourceView = sourceViewController.view;
    UIWindow *window = sourceViewController.view.window;
    [window addSubview:screenShotDestination];
    [window addSubview:screenShotSource];
    destinationViewController.view.hidden = YES;
    [destinationViewController dismissViewControllerAnimated:NO completion:nil];

    // Set and start animations
    screenShotDestination.center = CGPointMake(sourceView.center.x - sourceView.frame.size.width, sourceView.center.y);
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         screenShotDestination.center = CGPointMake(sourceView.center.x, sourceView.center.y);
                         screenShotSource.center = CGPointMake(sourceView.center.x + sourceView.frame.size.width, sourceView.center.y);
                     }
                     completion:^(BOOL finished){
                         [screenShotSource removeFromSuperview];
                         [screenShotDestination removeFromSuperview];
                         destinationViewController.view.hidden = NO;
                     }];
}

@end
