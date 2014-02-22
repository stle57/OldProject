//
//  TDViewControllerHelper.h
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDViewControllerHelper : NSObject

+ (UIButton *)navBackButton;
+ (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title;
+ (void)navigateToHomeFrom:(UIViewController *)fromController;
+ (BOOL)validateEmail:(NSString *)email;

@end
