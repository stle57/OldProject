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
    CGRect cellFrame = self.frame;
    cellFrame.size.width = SCREEN_WIDTH;
    self.frame = cellFrame;
    
    CGRect connectLabelFrame = self.connectLabel.frame;
    connectLabelFrame.size.width = SCREEN_WIDTH;
    self.connectLabel.frame = connectLabelFrame;
    self.layer.borderColor = [[TDConstants lightBorderColor] CGColor];
    self.layer.borderWidth = TD_CELL_BORDER_WIDTH;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
