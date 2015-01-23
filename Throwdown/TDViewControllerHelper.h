//
//  TDViewControllerHelper.h
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "TDGuestUserProfileViewController.h"

@interface TDViewControllerHelper : NSObject

+ (UIButton *)navBackButton;
+ (UIButton *)navCloseButton;
+ (UIButton *)navShareButton;

+ (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title;
+ (void)navigateToHomeFrom:(UIViewController *)fromController;
+ (void)navigateToGuestFrom:(UIViewController *)fromController guestPosts:(NSDictionary*)guestPosts;
+ (BOOL)validateEmail:(NSString *)email;
+ (NSString*)validatePhone:(NSString *)phone;
+ (NSDate *)dateForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString;
+ (NSString *)getUTCFormatedDate:(NSDate *)date;
+ (BOOL)textAttributeTapped:(NSString *)attribute inTap:(UITapGestureRecognizer *)recognizer action:(void (^)(id value))actionBlock;
+ (NSAttributedString *)makeParagraphedTextWithAttributedString:(NSAttributedString *)attributedString;
+ (NSAttributedString *)makeParagraphedTextWithAttributedString:(NSAttributedString *)attributedString withMultiple:(CGFloat)multiple;
+ (NSAttributedString *)makeParagraphedTextWithString:(NSString *)text;
+ (NSAttributedString *)makeParagraphedTextWithBioString:(NSString *)text;
+ (NSAttributedString *)makeParagraphedTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight lineHeightMultipler:(CGFloat)lineHeightMultiplier;
+ (NSAttributedString *)makeParagraphedTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight;
+ (NSAttributedString *)makeParagraphedTextForTruncatedBio:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight;
+ (NSAttributedString *)makeLeftAlignedTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight lineHeightMultipler:(CGFloat)lineHeightMultiplier;
+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label users:(NSArray *)users;
+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label users:(NSArray *)users pattern:(NSString *)pattern;
+ (CGFloat)heightForComment:(NSString *)text withMentions:(NSArray *)mentions;
+ (CGFloat)heightForText:(NSString *)text withMentions:(NSArray *)mentions withFont:(UIFont *)font inWidth:(CGFloat)width;
+ (BOOL)isThrowdownURL:(NSURL *)url;
+ (BOOL)isSafariURL:(NSURL *)url;
+ (BOOL)askUserToOpenInSafari:(NSURL *)url;
+ (CGFloat)heightForText:(NSString*)bodyText font:(UIFont*)font;
+ (CGPoint)centerPosition;
+ (NSString*)getAddressFormat:(NSDictionary*)data;
@end
