//
//  TDFollowProfileCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/9/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDFollowProfileCell.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "TDViewControllerHelper.h"

@implementation TDFollowProfileCell

@synthesize delegate;
@synthesize userId;
//@synthesize textViewdOrigRect;
@synthesize bottomLineOrigY;
@synthesize descriptionLabelOrigWidth;

- (void)dealloc
{
    delegate = nil;
    for (UIGestureRecognizer *g in self.nameLabel.gestureRecognizers) {
        [self.nameLabel removeGestureRecognizer:g];
    }
    for (UIGestureRecognizer *g in self.userImageView.gestureRecognizers) {
        [self.userImageView removeGestureRecognizer:g];
    }
    self.nameLabel = nil;
}

- (void)awakeFromNib {
    self.userInteractionEnabled = YES;
    
    self.descriptionLabel.font  = [TDConstants fontRegularSized:13];
    self.descriptionLabel.textColor = [TDConstants headerTextColor];
    
    UITapGestureRecognizer *usernameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernameTapped:)];
    [self.nameLabel addGestureRecognizer:usernameTap];

    self.userImageView.layer.cornerRadius = self.userImageView.layer.frame.size.width / 2;
    self.userImageView.clipsToBounds = YES;
    UITapGestureRecognizer *userProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernameTapped:)];

    [self.userImageView addGestureRecognizer:userProfileTap];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self modifyFrames];
    
    descriptionLabelOrigWidth = self.descriptionLabel.frame.size.width;
    
}

- (IBAction)actionButtonPressed:(UIButton*)sender{
    if (delegate && [delegate respondsToSelector:@selector(actionButtonPressedFromRow:tag:userId:)]) {
        [delegate actionButtonPressedFromRow:self.row tag:sender.tag userId:self.userId];
    }
}

- (IBAction)unFollowActionButtonPressed:(UIButton *)sender {
    
}

- (IBAction)followActionButtonPressed:(UIButton *)sender {
    
}

- (void) modifyFrames {
    CGRect cellFrame = self.frame;
    cellFrame.size.width = SCREEN_WIDTH;
    self.frame = cellFrame;
    
    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    topLineRect.size.width = SCREEN_WIDTH;
    self.topLine.frame = topLineRect;
    
    CGRect bottomLineRect = self.bottomLine.frame;
    bottomLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    bottomLineRect.size.width = SCREEN_WIDTH;
    self.bottomLine.frame = bottomLineRect;
    
    CGRect actionButtonRect = self.actionButton.frame;
    actionButtonRect.origin.x = SCREEN_WIDTH - self.actionButton.frame.size.width - TD_MARGIN;
    self.actionButton.frame = actionButtonRect;
    
    CGRect descriptionLabelRect = self.descriptionLabel.frame;
    descriptionLabelRect.size.width = actionButtonRect.origin.x - descriptionLabelRect.origin.x - TD_MARGIN;
    self.descriptionLabel.frame = descriptionLabelRect;
    
}

#pragma mark - User Name Button

- (void)usernameTapped:(UITapGestureRecognizer *)g {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedWithId:)]) {
        [self.delegate userProfilePressedWithId:self.userId];
    }
}
@end
