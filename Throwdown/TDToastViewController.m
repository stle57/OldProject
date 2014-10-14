//
//  TDToastViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 8/25/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//
#import "TDToastViewController.h"
#import "TDAnalytics.h"
#import "TDAPIClient.h"
#import "TDAppDelegate.h"

@implementation TDToastViewController

- (void)toastNotificationCloseButton{
    debug NSLog(@"inside TDRateUsDelegate:toastNotificationCloseButton");
    //ignore this version
    [iRate sharedInstance].declinedThisVersion = YES;
    [[TDAnalytics sharedInstance] logEvent:@"rating_closed"];

}
- (void)toastNotificationTappedRateUs{
    debug NSLog(@"inside TDRateUsDelegate:toastNotificationTappedRateUs");
    [[TDAnalytics sharedInstance] logEvent:@"rating_accepted"];
    //mark as rated
    [iRate sharedInstance].ratedThisVersion = YES;
    
    //launch app store
    [[iRate sharedInstance] openRatingsPageInAppStore];
}
   
- (void)toastNotificationSendInviteRetry:(NSDictionary *)payload {
    debug NSLog(@"retry toastNotifcationSendInviteRetry");
    NSString *senderName = [payload objectForKey:@"senderName"];
    NSArray *retryList = [payload objectForKey:@"retryList"];
    if ([payload objectForKey:@"retryList"]) {
        [[TDAPIClient sharedInstance] sendInvites:[payload objectForKey:@"senderName"] contactList:retryList callback:^(BOOL success, NSArray *contacts)
         {
             if (success) {
                 debug NSLog(@"successfully send to %@", contacts);
                 [[TDAppDelegate appDelegate] showToastWithText:@"Invites sent successfully!" type:kToastType_InviteSent payload:nil delegate:nil];
                 [[TDAnalytics sharedInstance] logEvent:@"invites_sent"];
             }
             else {
                 NSMutableArray *newList = [[NSMutableArray alloc] init];
                 for (id temp in contacts) {
                     if (![temp objectAtIndex:0]) {
                         for (id s in retryList) {
                             if ([s valueForKey:@"info"] == [temp objectAtIndex:1]) {
                                 [newList addObject:s];
                             }
                         }
                     }
                 }

                 [[TDAppDelegate appDelegate] showToastWithText:@"Invites failed.  Tap here to retry" type:kToastType_InviteWarning payload:@{@"senderName":senderName, @"retryList":newList} delegate:[TDAPIClient toastControllerDelegate]];
             }
         }];
    }
}

- (void)toastNotificationStopInvites {
    debug NSLog(@"Inside toastNotificationStopInvites");
    [[TDAnalytics sharedInstance] logEvent:@"sending_invites_stop"];

}
@end
