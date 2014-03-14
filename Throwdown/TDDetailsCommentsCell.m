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
@synthesize origTimeFrame;

- (void)dealloc
{
    delegate = nil;
    self.comment = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib {

    // Round off profile pic
    self.profileImage.layer.cornerRadius = 16.0;
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.profileImage.layer.borderWidth = 1.0;

    // Colors
    self.messageLabel.textColor = [TDConstants commentTextColor];
    self.timeLabel.textColor = [TDConstants commentTimeTextColor];

    // Fonts
    self.usernameLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:16.0];
    self.timeLabel.font = [UIFont fontWithName:@"ProximaNova-Light" size:13.0];
    self.messageLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:16.0];
}

-(void)makeText:(NSString *)text
{
    CGRect messagesFrame = self.messageLabel.frame;
    messagesFrame.size.width = COMMENT_MESSAGE_WIDTH;
    self.messageLabel.frame = messagesFrame;
    self.messageLabel.font = COMMENT_MESSAGE_FONT;
    self.messageLabel.text = text;
    [TDAppDelegate fixHeightOfThisLabel:self.messageLabel];
}

-(void)makeTime:(NSDate *)time name:(NSString *)name
{
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

@end
