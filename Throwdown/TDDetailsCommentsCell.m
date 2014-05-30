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
@synthesize origTimeFrame;

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
    origRectOfUserButton = self.userButton.frame;
}

- (void)makeText:(NSString *)text mentions:(NSArray *)mentions {
    CGRect messagesFrame = self.messageLabel.frame;
    messagesFrame.size.width = COMMENT_MESSAGE_WIDTH;
    self.messageLabel.frame = messagesFrame;
    self.messageLabel.font = COMMENT_MESSAGE_FONT;
    self.messageLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;

    [self.messageLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    [TDViewControllerHelper linkUsernamesInLabel:self.messageLabel users:mentions];
    self.messageLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:self.messageLabel.attributedText];

    CGSize size = [self.messageLabel sizeThatFits:CGSizeMake(COMMENT_MESSAGE_WIDTH, MAXFLOAT)];
    self.messageLabel.frame = CGRectMake(self.messageLabel.frame.origin.x, self.messageLabel.frame.origin.y, size.width, size.height);
}

- (void)makeTime:(NSDate *)time name:(NSString *)name {

    self.timeLabel.labelDate = time;
    self.timeLabel.text = [time timeAgo];

    // Fix widths for name and time
    [TDAppDelegate fixWidthOfThisLabel:self.timeLabel];
    CGRect timeFrame = self.timeLabel.frame;
    timeFrame.origin.x = CGRectGetMaxX(origTimeFrame)-timeFrame.size.width;
    self.timeLabel.frame = timeFrame;
    CGRect nameFrame = self.usernameLabel.frame;
    nameFrame.size.width = CGRectGetMaxX(self.timeLabel.frame)-nameFrame.origin.x-self.timeLabel.frame.size.width-1.0;
    self.usernameLabel.frame = nameFrame;
    self.usernameLabel.text = name;
    self.userButton.frame = origRectOfUserButton;
    self.userButton.frame = CGRectMake(origRectOfUserButton.origin.x,
                                           origRectOfUserButton.origin.y,
                                           [TDAppDelegate minWidthOfThisLabel:self.usernameLabel],
                                           origRectOfUserButton.size.height);
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
