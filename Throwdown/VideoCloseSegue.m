//
//  VideoCloseSegue.m
//  Throwdown
//
//  Created by Andrew Bennett on 2/25/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "VideoCloseSegue.h"

@implementation VideoCloseSegue

- (void)perform {
    
    NSLog(@"PERFORM-VideoCloseSegue");
    
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;

    // Create screenshots for animation
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
    UIWindow *window = sourceViewController.view.window;
    [window addSubview:screenShotDestination];
    [window addSubview:screenShotSource];
    [window setBackgroundColor:[UIColor blackColor]];
    destinationViewController.view.hidden = YES;
    [destinationViewController dismissViewControllerAnimated:NO completion:nil];
    [destinationViewController.navigationController popToRootViewControllerAnimated:NO];

    // Set and start animations
    screenShotDestination.transform = CGAffineTransformMakeScale(0.95, 0.95);
    screenShotSource.alpha = 1;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         screenShotSource.alpha = 0;
                         screenShotDestination.transform = CGAffineTransformMakeScale(1, 1);
                     }
                     completion:^(BOOL finished){
                         [screenShotSource removeFromSuperview];
                         [screenShotDestination removeFromSuperview];
                         destinationViewController.view.hidden = NO;
                     }];
}

@end
