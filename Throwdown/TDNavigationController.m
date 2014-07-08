//
//  TDNavigationController.m
//  Throwdown
//
//  Created by Andrew C on 2/28/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDNavigationController.h"
#import "VideoCloseSegue.h"
#import "TDSlideUpSegue.h"
#import "TDSlideDownSegue.h"

@implementation TDNavigationController

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    debug NSLog(@"home view segue for unwinding with identifier %@", identifier);

    if ([@"VideoCloseSegue" isEqualToString:identifier]) {
        return [[VideoCloseSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else if ([@"OpenRecordViewSegue" isEqualToString:identifier]) {
        return [[TDSlideUpSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else if ([@"MediaCloseSegue" isEqualToString:identifier]) {
        return [[TDSlideDownSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else {
        return [super segueForUnwindingToViewController:toViewController
                                     fromViewController:fromViewController
                                             identifier:identifier];
    }
}


@end
