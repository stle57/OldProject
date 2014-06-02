//
//  TDViewControllerHelper.h
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

@interface TDViewControllerHelper : NSObject

+ (UIButton *)navBackButton;
+ (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title;
+ (void)navigateToHomeFrom:(UIViewController *)fromController;
+ (BOOL)validateEmail:(NSString *)email;
+ (NSDate *)dateForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString;
+ (BOOL)textAttributeTapped:(NSString *)attribute inTap:(UITapGestureRecognizer *)recognizer action:(void (^)(id value))actionBlock;
+ (NSAttributedString *)makeParagraphedTextWithAttributedString:(NSAttributedString *)attributedString;
+ (NSAttributedString *)makeParagraphedTextWithAttributedString:(NSAttributedString *)attributedString withMultiple:(CGFloat)multiple;
+ (NSAttributedString *)makeParagraphedTextWithString:(NSString *)text;
+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label users:(NSArray *)users;
+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label users:(NSArray *)users pattern:(NSString *)pattern;

@end
