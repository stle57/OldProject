//
//  UIAlertView+TDBlockAlert.h
//  Throwdown
//
//  Created by Andrew C on 4/9/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (TDBlockAlert)

- (void)showWithCompletionBlock:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion;

@end
