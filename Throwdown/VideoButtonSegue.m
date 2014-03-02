//
//  VideoButtonSegue.m
//  Throwdown
//
//  Created by Andrew Bennett on 2/25/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "VideoButtonSegue.h"
#import "TDRecordVideoViewController.h"

@implementation VideoButtonSegue

- (void)perform {
    
    debug NSLog(@"PERFORM-VideoButtonSegue");

    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;

    // Create screenshot for animation
    UIGraphicsBeginImageContextWithOptions(sourceViewController.view.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [sourceViewController.view.layer renderInContext:context];
    UIImageView *screenShot = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();

    // Put destination view controller and screen shot in place
    UIWindow *window = sourceViewController.view.window;
    [window addSubview:screenShot];
    [sourceViewController presentViewController:destinationViewController animated:NO completion:NULL];

    // Set and start animations
    screenShot.transform = CGAffineTransformMakeScale(1.0, 1.0);
    screenShot.alpha = 1;
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         screenShot.alpha = 0;
                         screenShot.transform = CGAffineTransformMakeScale(0.95, 0.95);
                     }
                     completion:^(BOOL finished){
                         debug NSLog(@"record video button segue complete");
                         [screenShot removeFromSuperview]; // remove from temp super view
                     }];
}

@end
