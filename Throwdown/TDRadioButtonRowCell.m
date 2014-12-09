//
//  TDRadioButtonRowCell.m
//  Throwdown
//
//  Created by Andrew C on 8/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDRadioButtonRowCell.h"
#import "TDConstants.h"

@implementation TDRadioButtonRowCell

- (void)awakeFromNib
{
    self.titleLabel.font = [TDConstants fontRegularSized:16.];
    self.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    CGRect checkmarkFrame = self.checkmark.frame;
    checkmarkFrame.origin.x = SCREEN_WIDTH - 15 - self.checkmark.frame.size.width;
    checkmarkFrame.origin.y = self.frame.size.height/2 - self.checkmark.frame.size.height/2;
    self.checkmark.frame = checkmarkFrame;
    
    CGRect labelFrame = self.titleLabel.frame;
    labelFrame.origin.y = self.frame.size.height/2 - self.titleLabel.frame.size.height/2;
    self.titleLabel.frame = labelFrame;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
