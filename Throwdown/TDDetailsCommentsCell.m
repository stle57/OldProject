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

@implementation TDDetailsCommentsCell

@synthesize delegate;
@synthesize row;
@synthesize comment;
@synthesize commentNumber;
@synthesize origTimeFrame;

- (void)dealloc {
    delegate = nil;
    self.comment = nil;
}

- (void)awakeFromNib {

    // Colors
    self.messageLabel.textColor = [TDConstants commentTextColor];
    self.timeLabel.textColor = [TDConstants commentTimeTextColor];

    // Fonts
    self.usernameLabel.font = [TDConstants fontBoldSized:16.0];
    self.timeLabel.font     = [TDConstants fontLightSized:13.0];
    self.messageLabel.font  = COMMENT_MESSAGE_FONT;
}

- (void)makeText:(NSString *)text {
    CGRect messagesFrame = self.messageLabel.frame;
    messagesFrame.size.width = COMMENT_MESSAGE_WIDTH;
    self.messageLabel.frame = messagesFrame;
    self.messageLabel.font = COMMENT_MESSAGE_FONT;
    self.messageLabel.text = text;
    [TDAppDelegate fixHeightOfThisLabel:self.messageLabel];
}

- (void)makeTime:(NSDate *)time name:(NSString *)name {
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
}

- (IBAction)userButtonPressed:(id)sender {
    if (delegate) {
        if ([delegate respondsToSelector:@selector(userButtonPressedFromRow:commentNumber:)]) {
            [delegate userButtonPressedFromRow:self.row commentNumber:self.commentNumber];
        }
    }
}

@end
