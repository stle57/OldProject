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

@implementation TDDetailsCommentsCell

@synthesize delegate;
@synthesize row;
@synthesize commentNumber;

- (void)dealloc {
    delegate = nil;
    self.messageLabel.delegate = nil;
}

- (void)awakeFromNib {
    // Colors
    self.messageLabel.textColor = [TDConstants commentTextColor];
    self.timeLabel.textColor = [TDConstants commentTimeTextColor];

    // Fonts
    self.usernameLabel.font = USERNAME_FONT;
    self.timeLabel.font     = TIME_FONT;
    self.messageLabel.font  = COMMENT_MESSAGE_FONT;
    self.messageLabel.delegate = self;
}

- (void)updateWithComment:(TDComment *)comment {
    self.timeLabel.labelDate = comment.createdAt;
    self.timeLabel.text = [comment.createdAt timeAgo];
    self.usernameLabel.text = comment.user.username;

    // Make the button the size of username text
    CGRect frame = self.usernameLabel.frame;
    frame.size = [self.usernameLabel sizeThatFits:frame.size];
    self.userButton.frame = frame;

    // Comment body
    CGRect messagesFrame = self.messageLabel.frame;
    messagesFrame.size.width = COMMENT_MESSAGE_WIDTH;
    self.messageLabel.frame = messagesFrame;
    self.messageLabel.font = COMMENT_MESSAGE_FONT;
    self.messageLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;

    [self.messageLabel setText:comment.body afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    [TDViewControllerHelper linkUsernamesInLabel:self.messageLabel users:comment.mentions];
    self.messageLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:self.messageLabel.attributedText];
    self.messageLabel.frame = CGRectMake(self.messageLabel.frame.origin.x, self.messageLabel.frame.origin.y, COMMENT_MESSAGE_WIDTH, comment.messageHeight);
}

- (IBAction)userButtonPressed:(id)sender {
    if (delegate && [delegate respondsToSelector:@selector(userButtonPressedFromRow:commentNumber:)]) {
        [delegate userButtonPressedFromRow:self.row commentNumber:self.commentNumber];
    }
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedWithId:)]) {
        [self.delegate userProfilePressedWithId:[NSNumber numberWithInteger:[[url path] integerValue]]];
    }
}

@end
