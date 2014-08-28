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
    self.titleLabel.font = [TDConstants fontRegularSized:19.0];
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];
}

@end
