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
    self.titleLabel.font = [TDConstants fontRegularSized:18.];
    self.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
