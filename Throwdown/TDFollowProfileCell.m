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
}

- (void)awakeFromNib {
    self.nameLabel.font      = [TDConstants fontSemiBoldSized:16.0];
    self.nameLabel.textColor = [TDConstants brandingRedColor];
    self.usernameLabel.font  = [TDConstants fontRegularSized:13];
    self.usernameLabel.textColor = [TDConstants headerTextColor];
    self.userImageView.layer.cornerRadius = self.userImageView.layer.frame.size.width / 2;
    self.userImageView.clipsToBounds = YES;
    
    self.layer.borderColor = [[TDConstants cellBorderColor] CGColor];
    self.layer.borderWidth = .5f;
    
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
@end
