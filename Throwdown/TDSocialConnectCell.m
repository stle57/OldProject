//
//  TDSocialConnectCell.m
//  Throwdown
//
//  Created by Andrew C on 8/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSocialConnectCell.h"
#import "TDConstants.h"
@implementation TDSocialConnectCell

- (void)awakeFromNib
{
    // Initialization code
    self.layer.borderColor = [[TDConstants lightBorderColor] CGColor];
    self.layer.borderWidth = TD_CELL_BORDER_WIDTH;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
