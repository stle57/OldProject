//
//  TDEditVideoSegue.m
//  Throwdown
//
//  Created by Andrew C on 2/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDEditVideoSegue.h"

@implementation TDEditVideoSegue

- (void)perform {

    NSLog(@"PERFORM-EditVideoSegue");

    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;

    UIView *sourceView = sourceViewController.view;
    UIView *destinationView = destinationViewController.view;

    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    destinationView.center = CGPointMake(sourceView.center.x + sourceView.frame.size.width, destinationView.center.y);
    [window insertSubview:destinationView aboveSubview:sourceView];

    [UIView animateWithDuration:0.4
                     animations:^{
                         sourceView.center = CGPointMake(window.center.x - window.frame.size.width, window.center.y);
                         destinationView.center = CGPointMake(window.center.x, window.center.y);}
                     completion:^(BOOL finished){
                         debug NSLog(@"edit video segue complete");
                         [destinationView removeFromSuperview]; // remove from temp super view
                         [sourceViewController presentViewController:destinationViewController animated:NO completion:NULL];
                     }];
}

@end
