//
//  TDShareViewCell.m
//  Throwdown
//
//  Created by Andrew C on 8/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDShareViewCell.h"
#import "TDConstants.h"

@implementation TDShareViewCell

- (void)awakeFromNib {
    self.titleLabel.font = [TDConstants fontRegularSized:16.];
    
    CGRect buttonViewFrame = self.buttonView.frame;
    buttonViewFrame.origin.x = SCREEN_WIDTH - 10 - self.buttonView.frame.size.width;
    buttonViewFrame.origin.y = self.frame.size.height/2 - self.buttonView.frame.size.height/2;
    self.buttonView.frame = buttonViewFrame;

    CGRect iconViewFrame = self.iconView.frame;
    iconViewFrame.origin.y = self.frame.size.height/2 - self.iconView.frame.size.height/2;
    self.iconView.frame = iconViewFrame;
    
    CGRect labelFrame = self.titleLabel.frame;
    labelFrame.origin.y = self.frame.size.height/2 - self.titleLabel.frame.size.height/2;
    labelFrame.origin.x = self.iconView.frame.origin.x + self.iconView.frame.size.width + 18;
    self.titleLabel.frame = labelFrame;
    

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
