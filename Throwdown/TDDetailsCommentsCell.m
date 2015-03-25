//
//  TDDetailsCommentsCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDDetailsCommentsCell.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"
#import "NSDate+TimeAgo.h"
#import "TDViewControllerHelper.h"

static CGFloat const kMaxUsernameWidth = 230;

@implementation TDDetailsCommentsCell

- (void)dealloc {
    self.delegate = nil;
    self.messageLabel.delegate = nil;
    for (UIGestureRecognizer *g in self.usernameLabel.gestureRecognizers) {
        [self.usernameLabel removeGestureRecognizer:g];
    }
}

- (void)awakeFromNib {
    // Colors
    self.messageLabel.textColor = [TDConstants commentTextColor];
    self.timeLabel.textColor = [TDConstants commentTimeTextColor];

    // Fonts
    self.usernameLabel.font = [TDConstants fontSemiBoldSized:15.0];
    self.timeLabel.font     = TIME_FONT;
    self.messageLabel.font  = COMMENT_MESSAGE_FONT;
    self.messageLabel.delegate = self;

    self.usernameLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *usernameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userButtonPressed:)];
    [self.usernameLabel addGestureRecognizer:usernameTap];
}

- (void)updateWithComment:(TDComment *)comment showIcon:(BOOL)showIcon showDate:(BOOL)showDate {
    self.timeLabel.labelDate = comment.createdAt;
    self.timeLabel.text = [comment.createdAt timeAgo];
    self.usernameLabel.text = comment.user.username;

    // Make the button the size of username text
    CGRect frame = self.usernameLabel.frame;
    frame.size = [self.usernameLabel sizeThatFits:CGSizeMake(kMaxUsernameWidth, self.usernameLabel.frame.size.height + 2)];
    self.usernameLabel.frame = frame;

    // Comment body
    self.messageLabel.font = COMMENT_MESSAGE_FONT;
    self.messageLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.messageLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;

    if (comment.updated) {
        NSString *editedString = @" (edited)";
        NSString *bodyString = [NSString stringWithFormat:@"%@%@", comment.body, @" (edited)"];

        [self.messageLabel setText:bodyString afterInheritingLabelAttributesAndConfiguringWithBlock:^(NSMutableAttributedString *mutableAttributedString) {
            NSRange range = [bodyString rangeOfString:editedString];
            if (range.location != NSNotFound) {
                // Core Text APIs use C functions without a direct bridge to UIFont. See Apple's "Core Text Programming Guide" to learn how to configure string attributes.
                [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[TDConstants commentTimeTextColor] range:range];
            }
            
            return mutableAttributedString;
        }];
    } else {
        [self.messageLabel setText:comment.body afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    }

    [TDViewControllerHelper linkUsernamesInLabel:self.messageLabel users:comment.mentions withHashtags:YES];
    self.messageLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:self.messageLabel.attributedText];

    self.commentIcon.hidden = !showIcon;
    self.timeLabel.hidden = !showDate;
}

- (IBAction)userButtonPressed:(UITapGestureRecognizer *)g {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userButtonPressedFromRow:commentNumber:)]) {
        [self.delegate userButtonPressedFromRow:self.row commentNumber:self.commentNumber];
    }
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([TDViewControllerHelper isThrowdownURL:url] && self.delegate && [self.delegate respondsToSelector:@selector(userTappedURL:)]) {
        [self.delegate userTappedURL:url];
    } else {
        [TDViewControllerHelper askUserToOpenInSafari:url];
    }
}

@end
