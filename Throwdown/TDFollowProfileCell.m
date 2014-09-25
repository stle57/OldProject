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
//@synthesize bottomLineOrigY;

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
    debug NSLog(@"inside TDFollowProfileCell awakeFromNib");
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
    
    self.layer.borderColor = [[TDConstants cellBorderColor] CGColor];
    self.layer.borderWidth = TD_CELL_BORDER_WIDTH;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (IBAction)actionButtonPressed:(UIButton*)sender{
    debug NSLog(@"TDFollowProfileCell-actionButtonPressed w/ userId=%@", self.userId);
    if (delegate && [delegate respondsToSelector:@selector(actionButtonPressedFromRow:tag:)]) {
        [delegate actionButtonPressedFromRow:self.row tag:sender.tag];
    }
}

- (IBAction)unFollowActionButtonPressed:(UIButton *)sender {
    
}

- (IBAction)followActionButtonPressed:(UIButton *)sender {
    
}

#pragma mark - User Name Button

- (void)usernameTapped:(UITapGestureRecognizer *)g {
    debug NSLog(@"====>inside usernameTapped with userid=%@", self.userId);
    if (self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedWithId:)]) {
        [self.delegate userProfilePressedWithId:self.userId];
    }
}
@end
