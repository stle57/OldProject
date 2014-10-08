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
    CGRect cellFrame = self.frame;
    cellFrame.size.width = SCREEN_WIDTH;
    self.frame = cellFrame;
    debug NSLog(@"social network cell=%@", NSStringFromCGRect(self.frame));
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.width = SCREEN_WIDTH;
    self.contentView.frame = contentViewFrame;

    self.titleLabel.font = [TDConstants fontRegularSized:16.0];
    self.titleLabel.textColor = [TDConstants headerTextColor];
    debug NSLog(@"titleLabel frame = %@", NSStringFromCGRect(self.titleLabel.frame));
    
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    CGRect lineRect = self.bottomLine.frame;
    lineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    lineRect.size.width = SCREEN_WIDTH;
    self.bottomLine.frame = lineRect;
    debug NSLog(@"bottomLine=%@", NSStringFromCGRect(self.bottomLine.frame));
    
    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.width = SCREEN_WIDTH;
    debug NSLog(@"SCREEN_WIDTH=%f", SCREEN_WIDTH);
    topLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.topLine.frame = topLineRect;
    debug NSLog(@"topLine=%@", NSStringFromCGRect(self.topLine.frame));
    
    debug NSLog(@"contentView=%@", NSStringFromCGRect(self.contentView.frame));

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated{
    [super setSelected:selected animated:animated];
}

@end
