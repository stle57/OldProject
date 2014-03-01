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
    
    [sourceViewController.view.superview insertSubview:destinationViewController.view atIndex:0];
    
    sourceViewController.view.transform = CGAffineTransformMakeScale(1.00, 1.00);

    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         sourceViewController.view.transform = CGAffineTransformMakeScale(0.05, 0.05);
                     }
                     completion:^(BOOL finished) {
                         debug NSLog(@"video close segue complete");
                         [destinationViewController.view removeFromSuperview];
                         [sourceViewController dismissViewControllerAnimated:NO completion:nil];
                         [destinationViewController.navigationController popToRootViewControllerAnimated:NO];
                     }];
}

@end
