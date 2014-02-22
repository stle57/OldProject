//
//  TDViewControllerHelper.m
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDViewControllerHelper.h"
#import "TDWelcomeViewController.h"

static const NSString *EMAIL_REGEX = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";

@implementation TDViewControllerHelper

+ (UIButton *)navBackButton {
    UIImage *image = [UIImage imageNamed:@"nav_back.png"];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);

    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"nav_back_hit.png"] forState:UIControlStateHighlighted];
    return button;
}

+ (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [alert show];
}

+ (void)navigateToHomeFrom:(UIViewController *)fromController {
    UINavigationController *nav = (UINavigationController*) fromController.view.window.rootViewController;
    TDWelcomeViewController *root = (TDWelcomeViewController *)[nav.viewControllers objectAtIndex:0];
    [root performSelector:@selector(showHomeController)];
}

+ (BOOL)validateEmail:(NSString *)email {
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", EMAIL_REGEX];
    return [emailTest evaluateWithObject:email];
}

@end
