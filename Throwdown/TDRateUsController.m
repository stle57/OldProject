//
//  TDRateUsController.m
//  Throwdown
//
//  Created by Stephanie Le on 8/25/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//
#import "TDRateUsController.h"

@implementation TDRateUsController

- (void)toastNotificationCloseButton{
    debug NSLog(@"inside TDRateUsDelegate:toastNotificationCloseButton");
    //ignore this version
    [iRate sharedInstance].declinedThisVersion = YES;

}
- (void)toastNotificationTappedRateUs{
    debug NSLog(@"inside TDRateUsDelegate:toastNotificationTappedRateUs");
    //mark as rated
    [iRate sharedInstance].ratedThisVersion = YES;
    
    //launch app store
    [[iRate sharedInstance] openRatingsPageInAppStore];
}
   

@end
