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
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
