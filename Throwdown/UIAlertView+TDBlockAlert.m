//
//  UIAlertView+TDBlockAlert.m
//  Throwdown
//
//  Created by Andrew C on 4/9/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <objc/runtime.h>
#import "UIAlertView+TDBlockAlert.h"

@interface TDBlockAlert : NSObject

@property (copy) void(^completionBlock)(UIAlertView *alertView, NSInteger buttonIndex);

@end


@implementation TDBlockAlert

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.completionBlock) {
        self.completionBlock(alertView, buttonIndex);
    }
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    // Simulate a cancel click
    if (self.completionBlock) {
        self.completionBlock(alertView, alertView.cancelButtonIndex);
    }
}

@end


static const char kTDBlockAlertKey;
@implementation UIAlertView (TDBlockAlert)

- (void)showWithCompletionBlock:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion {
    TDBlockAlert *alertWrapper = [[TDBlockAlert alloc] init];
    alertWrapper.completionBlock = completion;
    self.delegate = alertWrapper;

    // Set the wrapper as an associated object
    objc_setAssociatedObject(self, &kTDBlockAlertKey, alertWrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [self show];
}


@end
