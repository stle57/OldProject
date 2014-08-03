//
//  TDViewControllerHelper.m
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDViewControllerHelper.h"
#import "TDWelcomeViewController.h"
#import "TDConstants.h"

static const NSString *EMAIL_REGEX = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";

@implementation TDViewControllerHelper

+ (UIButton *)navBackButton {
    return [self navBarButton:@"nav_back" hit:@"nav_back_hit"];
}

+ (UIButton *)navCloseButton {
    return [self navBarButton:@"nav_close" hit:@"nav_close_hit"];
}

+ (UIButton *)navBarButton:(NSString *)normal hit:(NSString *)hit {
    UIImage *image = [UIImage imageNamed:normal];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);

    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:hit] forState:UIControlStateHighlighted];
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

+ (NSDate *)dateForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {

	NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];

	[rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
	[rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

	// Convert the RFC 3339 date time string to an NSDate.
	NSDate *result = [rfc3339DateFormatter dateFromString:rfc3339DateTimeString];
	return result;
}

+ (NSString *)getUTCFormatedDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}


+ (BOOL)textAttributeTapped:(NSString *)attribute inTap:(UITapGestureRecognizer *)recognizer action:(void (^)(id value))actionBlock {
    UITextView *textView = (UITextView *)recognizer.view;

    // Location of the tap in text-container coordinates
    NSLayoutManager *layoutManager = textView.layoutManager;
    CGPoint location = [recognizer locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;

    // Find the character that's been tapped on
    NSUInteger characterIndex;
    characterIndex = [layoutManager characterIndexForPoint:location
                                           inTextContainer:textView.textContainer
                  fractionOfDistanceBetweenInsertionPoints:NULL];

    if (characterIndex < textView.textStorage.length) {
        NSRange range;
        NSDictionary *attributes = [textView.textStorage attributesAtIndex:characterIndex effectiveRange:&range];
        if ([attributes objectForKey:attribute]) {
            if (actionBlock) {
                actionBlock([attributes objectForKey:attribute]);
            }
            return YES;
        }
    }
    return NO;
}

+ (NSAttributedString *)makeParagraphedTextWithAttributedString:(NSAttributedString *)attributedString {
    // 1 seems to work better than TDTextLineHeight on TTTAttributedLabels might have to change this if used for regular label
    return [self makeParagraphedTextWithAttributedString:attributedString withMultiple:1.0f];
}

+ (NSAttributedString *)makeParagraphedTextWithAttributedString:(NSAttributedString *)attributedString withMultiple:(CGFloat)multiple {
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 0;
    paragraphStyle.maximumLineHeight = 20;
    [paragraphStyle setLineHeightMultiple:multiple];
    [mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [attributedString length])];
    return mutableAttributedString;
}

+ (NSAttributedString *)makeParagraphedTextWithString:(NSString *)text {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:kTextLineHeight];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];
    return attributedString;
}

+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label users:(NSArray *)users {
    // Standard pattern with @-sign prefixed username
    [self linkUsernamesInLabel:label users:users pattern:@"\\B(@[a-zA-Z0-9_]+)\\b"];
}

+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label users:(NSArray *)users pattern:(NSString *)pattern {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    NSMutableDictionary *mutableLinkAttributes = [[NSMutableDictionary alloc] init];
    [mutableLinkAttributes setObject:[TDConstants brandingRedColor] forKey:(NSString *)kCTForegroundColorAttributeName];
    [mutableLinkAttributes setObject:paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];

    label.linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    label.activeLinkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    label.inactiveLinkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];

    NSMutableAttributedString *mutableAttributedString = [label.attributedText mutableCopy];
    NSRange range = NSMakeRange(0, [mutableAttributedString string].length);
    NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:nil];
    [usernameRegex enumerateMatchesInString:[mutableAttributedString string] options:kNilOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange usernameRange = [result rangeAtIndex:1];
        NSString *username = [[mutableAttributedString string] substringWithRange:usernameRange];
        if ([@"@" isEqualToString:[username substringToIndex:1]]) {
            username = [username substringFromIndex:1];
        }
        for (NSDictionary *user in users) {
            if ([username isEqualToString:[user objectForKey:@"username"]]) {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [user objectForKey:@"id"]]];
                [label addLinkToURL:url withRange:usernameRange];
            }
        }
    }];
}

+ (CGFloat)heightForComment:(NSString *)text withMentions:(NSArray *)mentions {
    // Slow but the most accurate way to calculate the size
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, COMMENT_MESSAGE_WIDTH, 18)];
    label.font = COMMENT_MESSAGE_FONT;
    label.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    [TDViewControllerHelper linkUsernamesInLabel:label users:mentions];
    label.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:label.attributedText];
    label.numberOfLines = 0;

    // Adding 2 covers an edge case where emoji would get cut off
    CGSize size = [label sizeThatFits:CGSizeMake(COMMENT_MESSAGE_WIDTH, MAXFLOAT)];
    return size.height == 0. ? 0 : size.height + 2;
}

@end
