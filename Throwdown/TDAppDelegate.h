//
//  TDAppDelegate.h
//  Throwdown
//
//  Created by Andrew C on 1/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPost.h"
#import "TDConstants.h"
#import "TDToastView.h"
#import "iRate.h"
#import "TDToastViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@interface TDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (TDAppDelegate*)appDelegate;
+ (UIColor *)randomColor;
+ (void)fixHeightOfThisLabel:(UILabel *)aLabel;
+ (void)fixWidthOfThisLabel:(UILabel *)aLabel;
+ (CGFloat)heightOfTextForString:(NSString *)aString andFont:(UIFont *)aFont maxSize:(CGSize)aSize;
+ (CGFloat)minWidthOfThisLabel:(UILabel *)aLabel;
+ (UIImage *)squareImageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIViewController *)topMostController;
+ (CGFloat)widthOfTextForString:(NSString *)aString andFont:(UIFont *)aFont maxSize:(CGSize)aSize;
- (void)showToastWithText:(NSString *)text type:(kToastType)type payload:(NSDictionary *)payload delegate:(id<TDToastViewDelegate>)delegate;

#pragma mark - Facebook
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error;
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error success:(void (^)(void))success failure:(void (^)(NSString *error))failure;

@end
