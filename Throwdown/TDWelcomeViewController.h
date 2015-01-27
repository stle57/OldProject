//
//  TDWelcomeViewController.h
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDGuestUserProfileViewController.h"

@interface TDWelcomeViewController : UIViewController
{

}

@property (nonatomic, assign, readwrite) BOOL editViewOnly;

- (void)showHomeController;
- (void)showGuestController:(NSDictionary*)guestPosts;
@end
