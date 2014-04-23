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

+ (NSDate *)dateForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {

	NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];

	[rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
	[rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

	// Convert the RFC 3339 date time string to an NSDate.
	NSDate *result = [rfc3339DateFormatter dateFromString:rfc3339DateTimeString];
	return result;
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

+ (NSAttributedString *)makeParagraphedText:(NSString *)text {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:TDTextLineHeight];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];
    return attributedString;
}


+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label text:(NSString *)text users:(NSArray *)users pattern:(NSString *)pattern fontSize:(NSUInteger)fontSize {
    NSDictionary *userAttributes = @{ NSForegroundColorAttributeName:[TDConstants brandingRedColor], NSFontAttributeName: [TDConstants fontBoldSized:fontSize] };
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {

        NSRange range = NSMakeRange(0, [mutableAttributedString string].length);
        NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:nil];
        [usernameRegex enumerateMatchesInString:[mutableAttributedString string] options:kNilOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            [mutableAttributedString addAttributes:userAttributes range:[result rangeAtIndex:1]];
        }];

        return mutableAttributedString;
    }];

    for (NSDictionary *user in users) {
        NSString *pattern = [NSString stringWithFormat:@"(\\b%@\\b)", [user objectForKey:@"username"]];
        NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:nil];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [user objectForKey:@"id"]]];
        NSRange linkRange = [usernameRegex rangeOfFirstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
        [label addLinkToURL:url withRange:linkRange];
    }
}


@end
