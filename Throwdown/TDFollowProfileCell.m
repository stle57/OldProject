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

@implementation TDFollowProfileCell

@synthesize delegate;
@synthesize userId;
//@synthesize textViewdOrigRect;
@synthesize bottomLineOrigY;

- (void)dealloc
{
    delegate = nil;
    for (UIGestureRecognizer *g in self.usernameLabel.gestureRecognizers) {
        [self.nameLabel removeGestureRecognizer:g];
    }
    for (UIGestureRecognizer *g in self.userImageView.gestureRecognizers) {
        [self.userImageView removeGestureRecognizer:g];
    }
    self.nameLabel = nil;
}

- (void)awakeFromNib {
    self.userInteractionEnabled = YES;
    
    self.nameLabel.font      = [TDConstants fontSemiBoldSized:16.0];
    self.nameLabel.textColor = [TDConstants brandingRedColor];
    self.usernameLabel.font  = [TDConstants fontRegularSized:13];
    self.usernameLabel.textColor = [TDConstants headerTextColor];
    
    UITapGestureRecognizer *usernameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernameTapped:)];
    [self.nameLabel addGestureRecognizer:usernameTap];

    self.userImageView.layer.cornerRadius = self.userImageView.layer.frame.size.width / 2;
    self.userImageView.clipsToBounds = YES;
    UITapGestureRecognizer *userProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(usernameTapped:)];

    [self.userImageView addGestureRecognizer:userProfileTap];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CGRect lineRect = self.bottomLine.frame;
    lineRect.size.height = 0.5;
    self.bottomLine.frame = lineRect;
    lineRect = self.topLine.frame;
    lineRect.size.height = 0.5;
    self.topLine.frame = lineRect;
}

- (IBAction)actionButtonPressed:(UIButton*)sender{
    if (delegate && [delegate respondsToSelector:@selector(actionButtonPressedFromRow:tag:userId:)]) {
        [delegate actionButtonPressedFromRow:self.row tag:sender.tag userId:self.userId];
    }
}

#pragma mark - User Name Button

- (void)usernameTapped:(UITapGestureRecognizer *)g {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedWithId:)]) {
        [self.delegate userProfilePressedWithId:self.userId];
    }
}
@end
