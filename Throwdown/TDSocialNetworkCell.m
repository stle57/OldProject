//
//  TDSocialNetworkCell.m
//  Throwdown
//
//  Created by Andrew C on 8/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSocialNetworkCell.h"
#import "TDConstants.h"

@implementation TDSocialNetworkCell

- (void)awakeFromNib {
    self.titleLabel.font = [TDConstants fontRegularSized:16.0];
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    CGRect lineRect = self.bottomLine.frame;
    lineRect.size.height = TD_CELL_BORDER_WIDTH;
    self.bottomLine.frame = lineRect;
    lineRect = self.topLine.frame;
    lineRect.size.height = TD_CELL_BORDER_WIDTH;
    self.topLine.frame = lineRect;
    
    self.topLine.layer.borderColor = [[TDConstants cellBorderColor] CGColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];
}

@end
