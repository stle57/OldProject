//
//  TDStoryboardSegue.m
//  Throwdown
//
//  Created by Andrew C on 7/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDStoryboardSegue.h"

@implementation TDStoryboardSegue

- (void)perform {
    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;

    // Create screenshots for animation
    UIGraphicsBeginImageContextWithOptions(sourceViewController.view.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [sourceViewController.view.layer renderInContext:context];
    _screenShotSource = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(destinationViewController.view.bounds.size, NO, 0.0);
    context = UIGraphicsGetCurrentContext();
    [destinationViewController.view.layer renderInContext:context];
    _screenShotDestination = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
}

- (void)presentDestination {
    UIWindow *window = [self.sourceViewController view].window;
    [window addSubview:self.screenShotDestination];
    [window addSubview:self.screenShotSource];
    [window setBackgroundColor:[UIColor blackColor]];
    [self.destinationViewController view].hidden = YES;

    [self.sourceViewController presentViewController:self.destinationViewController animated:NO completion:NULL];
}

- (void)popDestination {
    UIWindow *window = [self.sourceViewController view].window;
    [window addSubview:self.screenShotSource];
    [window addSubview:self.screenShotDestination];
    [window setBackgroundColor:[UIColor blackColor]];
    [self.destinationViewController view].hidden = YES;

    [[self.destinationViewController navigationController] dismissViewControllerAnimated:self.sourceViewController completion:nil];
//    [self.destinationViewController dismissViewControllerAnimated:NO completion:nil];
//    [[self.destinationViewController navigationController] popToRootViewControllerAnimated:NO];
}

@end
