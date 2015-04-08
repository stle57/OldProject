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
#import "UIAlertView+TDBlockAlert.h"
#import "NBPhoneNumberUtil.h"

static const NSString *EMAIL_REGEX = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";

@implementation TDViewControllerHelper

+ (UIButton *)navBackButton {
    return [self navBarButton:@"nav-back" hit:@"nav-back-hit"];
}

+ (UIButton *)navCloseButton {
    return [self navBarButton:@"nav-close" hit:@"nav-close-hit"];
}

+ (UIButton *)navShareButton {
    return [self navBarButton:@"nav_share_white" hit:@"nav_share_white_hit"];
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
    // This fixes iOS8 turning the message into title (which is huge and ughly) when there's not title.
    if (title == nil) {
        title = @"";
    }
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

+ (void)navigateToGuestFrom:(UIViewController *)fromController guestPosts:(NSDictionary*)guestPosts {
    UINavigationController *nav = (UINavigationController*) fromController.view.window.rootViewController;
    TDWelcomeViewController *root = (TDWelcomeViewController *)[nav.viewControllers objectAtIndex:0];
    [root showGuestController:guestPosts];
}
+ (BOOL)validateEmail:(NSString *)email {
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", EMAIL_REGEX];
    return [emailTest evaluateWithObject:email];
}

+ (NSString*)validatePhone:(NSString *)phone {
    NSError *error = nil;
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NBPhoneNumber *parsedPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:phone error:&error];
    
    NSString *formattedPhoneNum = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
    
    if (!error && [phoneUtil isValidNumber:parsedPhoneNumber]) {
        return formattedPhoneNum;
    } else {
        return @"";
    }
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

+ (NSAttributedString *)makeParagraphedTextWithBioString:(NSString *)text {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:kTextLineHeight];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];
    [paragraphStyle setMinimumLineHeight:19];
    [paragraphStyle setMaximumLineHeight:19];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.firstLineHeadIndent = 10.0f;
    paragraphStyle.headIndent = 10.0f;
    paragraphStyle.tailIndent = -10.0f;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];
    [attributedString addAttribute:NSFontAttributeName value:BIO_FONT range:NSMakeRange(0, text.length)];

    return attributedString;
}

+ (NSAttributedString *)makeParagraphedTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineHeight];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, text.length)];
    return attributedString;
}

+ (NSAttributedString *)makeParagraphedTextForTruncatedBio:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle setAlignment:NSTextAlignmentLeft];
    
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, text.length)];
    return attributedString;
}

+ (NSAttributedString *)makeParagraphedTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight lineHeightMultipler:(CGFloat)lineHeightMultiplier{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:lineHeightMultiplier];
    [paragraphStyle setMinimumLineHeight:lineHeight];
    [paragraphStyle setMaximumLineHeight:lineHeight];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, text.length)];
    return attributedString;
}

+ (NSAttributedString *)makeLeftAlignedTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight lineHeightMultipler:(CGFloat)lineHeightMultiplier{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:lineHeightMultiplier];
    [paragraphStyle setMinimumLineHeight:lineHeight];
    [paragraphStyle setMaximumLineHeight:lineHeight];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, text.length)];
    return attributedString;
}

+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label users:(NSArray *)users withHashtags:(BOOL)linkHashtags {
    // Standard pattern with @-sign prefixed username
    [self linkUsernamesInLabel:label users:users pattern:@"\\B(@[a-zA-Z0-9_]+)\\b" withHashtags:linkHashtags];
}

+ (void)linkUsernamesInLabel:(TTTAttributedLabel *)label users:(NSArray *)users pattern:(NSString *)pattern withHashtags:(BOOL)linkHashtags {

    NSMutableDictionary *linkStyle = [TDViewControllerHelper linkStyle:label.font];

    label.linkAttributes = nil;
    label.activeLinkAttributes = nil;
    label.inactiveLinkAttributes = nil;

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
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://user/%@", [TDConstants appScheme], [user objectForKey:@"id"]]];
                NSTextCheckingResult *link = [NSTextCheckingResult linkCheckingResultWithRange:usernameRange URL:url];
                [label addLinkWithTextCheckingResult:link attributes:linkStyle];
            }
        }
    }];

    [TDViewControllerHelper colorLinksInLabel:label centerText:NO];

    if (linkHashtags) {
        NSMutableDictionary *hashtagStyle = [TDViewControllerHelper hashTagStyle];
        NSArray *matches = [TDViewControllerHelper hashtagMatchesForString:[mutableAttributedString string]];
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match rangeAtIndex:1];
            NSString *tag = [[mutableAttributedString string] substringWithRange:matchRange];
            if ([@"#" isEqualToString:[tag substringToIndex:1]]) {
                tag = [tag substringFromIndex:1];
            }
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://tag/%@", [TDConstants appScheme], tag]];
            NSTextCheckingResult *link = [NSTextCheckingResult linkCheckingResultWithRange:matchRange URL:url];
            [label addLinkWithTextCheckingResult:link attributes:hashtagStyle];
        }
        
    }
}

+ (void)colorLinksInLabel:(TTTAttributedLabel *)label centerText:(BOOL)centerText{
    // This runs through any automatically detected links/url/numbers/email etc and sets the red color
    if (label.enabledTextCheckingTypes) {
        NSMutableDictionary *linkStyle = [TDViewControllerHelper linkStyle:label.font];
        NSMutableAttributedString *mutableAttributedString = [label.attributedText mutableCopy];
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:label.enabledTextCheckingTypes error:nil]; ;
        if (dataDetector && [dataDetector respondsToSelector:@selector(matchesInString:options:range:)]) {
            NSArray *results = [dataDetector matchesInString:[(NSAttributedString *)mutableAttributedString string] options:0 range:NSMakeRange(0, [(NSAttributedString *)mutableAttributedString length])];
            for (NSTextCheckingResult *match in results) {
                [mutableAttributedString setAttributes:linkStyle range:match.range];
            }
        }

        if (centerText) {
            // Center the text again
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            [mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [label.attributedText length])];
        }
        label.attributedText = mutableAttributedString;
    }
}

+ (NSMutableDictionary *)linkStyle:(UIFont *)font {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    NSMutableDictionary *userMentionLinkAttributes = [[NSMutableDictionary alloc] init];
    [userMentionLinkAttributes setObject:font forKey:(NSString *)NSFontAttributeName];
    [userMentionLinkAttributes setObject:[TDConstants brandingRedColor] forKey:(NSString *)kCTForegroundColorAttributeName];
    [userMentionLinkAttributes setObject:paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];

    return userMentionLinkAttributes;
}

+ (NSMutableAttributedString *)boldHashtagsInText:(NSMutableAttributedString *)text fontSize:(CGFloat)fontSize {
    NSMutableDictionary *hashtagStyle = [TDViewControllerHelper hashTagStyle];
    [hashtagStyle setObject:[TDConstants fontSemiBoldSized:fontSize] forKey:(NSString *)NSFontAttributeName];
    [hashtagStyle setObject:[TDConstants headerTextColor] forKey:(NSString *)kCTForegroundColorAttributeName];
    NSArray *matches = [TDViewControllerHelper hashtagMatchesForString:[text string]];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        [text setAttributes:hashtagStyle range:matchRange];
    }
    return text;
}

+ (NSMutableDictionary *)hashTagStyle {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

    NSMutableDictionary *hashtagLinkAttributes = [[NSMutableDictionary alloc] init];
    [hashtagLinkAttributes setObject:[TDConstants hashtagColor] forKey:(NSString *)kCTForegroundColorAttributeName];
    [hashtagLinkAttributes setObject:paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
    return hashtagLinkAttributes;
}

+ (NSRegularExpression *)hashtagRegex {
    return [NSRegularExpression regularExpressionWithPattern:@"(#[a-zA-Z0-9_]+)\\b" options:kNilOptions error:nil];
}

+ (NSArray *)hashtagMatchesForString:(NSString *)string {
    return [[TDViewControllerHelper hashtagRegex] matchesInString:string options:kNilOptions range:NSMakeRange(0, string.length)];
}

+ (CGFloat)heightForComment:(NSString *)text withMentions:(NSArray *)mentions {
    CGFloat width = [UIScreen mainScreen].bounds.size.width - 20;  // 20 is standard margin
    return [self heightForText:text withMentions:mentions withFont:COMMENT_MESSAGE_FONT inWidth:width];
}

+ (CGFloat)heightForText:(NSString *)text withMentions:(NSArray *)mentions withFont:(UIFont *)font inWidth:(CGFloat)width {
    // Slow but the most accurate way to calculate the size
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, width, 18)];
    label.font = font;
    label.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    [TDViewControllerHelper linkUsernamesInLabel:label users:mentions withHashtags:NO];
    label.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:label.attributedText];
    label.numberOfLines = 0;

    // Adding 2 covers an edge case where emoji would get cut off
    CGSize size = [label sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return size.height == 0. ? 0 : size.height + 2;
}


+ (BOOL)isThrowdownURL:(NSURL *)url {
    return [[url scheme] caseInsensitiveCompare:[TDConstants appScheme]] == NSOrderedSame;
}

+ (BOOL)isSafariURL:(NSURL *)url {
    return (([[url scheme] caseInsensitiveCompare:@"http"] == NSOrderedSame || [[url scheme] caseInsensitiveCompare:@"https"] == NSOrderedSame) && [[UIApplication sharedApplication] canOpenURL:url]);
}

+ (BOOL)isEmailURL:(NSURL *)url {
    return [[url scheme] isEqualToString:@"mailto"];
}

+ (BOOL)askUserToOpenInSafari:(NSURL *)url {
    BOOL isSafariURL = [self isSafariURL:url];
    if (isSafariURL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open link in Safari?"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }];
    }
    return isSafariURL;
}

+ (CGFloat)heightForText:(NSString*)bodyText font:(UIFont*)font{
    CGSize constraingSize = CGSizeMake(300, MAXFLOAT);
    CGRect textRect = [bodyText boundingRectWithSize:constraingSize options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:font} context:nil];
    
    return textRect.size.height;
}

+ (CGPoint)centerPosition {
    
    return CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);

}

+ (NSString*)getAddressFormat:(NSDictionary*)data {
    NSString* formatedAddress = @"";
    NSDictionary *locationData = [data objectForKey:@"location"];
    
    if (![[locationData objectForKey:@"address"] isEqual:@""] ||
        (![[locationData objectForKey:@"address"] isEqual:[NSNull null]])) {
        formatedAddress = [locationData objectForKey:@"address"];
    }
    
    NSString * city =[locationData objectForKey:@"city"];
    if (city != nil && city.length) {
        if (formatedAddress.length) {
            formatedAddress = [NSString stringWithFormat:@"%@\n%@",formatedAddress, city ];
        } else {
            formatedAddress = [NSString stringWithFormat:@"%@", city];
        }
    }
    
    NSString *state = [locationData objectForKey:@"state"];
    if (state != nil && state.length) {
        if (formatedAddress.length) {
            formatedAddress = [NSString stringWithFormat:@"%@, %@", formatedAddress, state ];
        } else {
            formatedAddress = [NSString stringWithFormat:@"%@", state];
        }
    }
    return formatedAddress;
}
@end
