//
//  TDInviteCell.m
//  Throwdown
//
//  Created by Stephanie Le on 9/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDInviteCell.h"
#import "TDConstants.h"
#import "NBPhoneNumberUtil.h"

@implementation TDInviteCell

- (void)awakeFromNib
{
    // Initialization code
    self.layer.borderColor = [[TDConstants cellBorderColor] CGColor];
    self.layer.borderWidth = TD_CELL_BORDER_WIDTH;
    self.contactTextField.font = [TDConstants fontRegularSized:16];
    self.contactTextField.textColor = [TDConstants headerTextColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
