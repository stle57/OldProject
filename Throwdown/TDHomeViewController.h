//
//  TDHomeViewController.h
//  Throwdown
//
//  Created by Andrew C on 1/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPostsViewController.h"
#import "TDToastView.h"

@interface TDHomeViewController : TDPostsViewController<TDToastViewDelegate>
@property (nonatomic) BOOL newUser;
- (void)openPushNotification:(NSDictionary *)notification;
- (BOOL)openURL:(NSURL *)url;
- (void)fetchPostsWithCompletion:(void (^)(void))completion;
- (void)addOverlay;
+ (TDHomeViewController *)getHomeViewController;
@end
