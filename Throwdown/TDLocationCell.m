//
//  TDLocationCellTableViewCell.m
//  Throwdown
//
//  Created by Stephanie Le on 12/2/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLocationCell.h"
#import "TDConstants.h"

@implementation TDLocationCell
@synthesize locationName;

- (void)awakeFromNib {
    self.topLine.hidden = YES;
    
    CGRect locationFrame = CGRectMake(10,10,SCREEN_WIDTH, 22);
    self.locationName.frame = locationFrame;
    
    locationName.font = [TDConstants fontSemiBoldSized:16];
    locationName.textColor = [TDConstants headerTextColor];
    
    CGRect bottomLineRect = self.bottomLine.frame;
    bottomLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    bottomLineRect.size.width = SCREEN_WIDTH;
    self.bottomLine.frame = bottomLineRect;
    self.bottomLine.backgroundColor = [TDConstants lightBorderColor];
    
    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    topLineRect.size.width = SCREEN_WIDTH;
    self.topLine.frame = bottomLineRect;
    self.topLine.backgroundColor = [TDConstants lightBorderColor];

    CGRect descriptionFrame = CGRectMake(10,40,SCREEN_WIDTH, 22);
    self.descriptionLabel.frame = descriptionFrame;
    
    self.descriptionLabel.font = [TDConstants fontRegularSized:14];
    self.descriptionLabel.textColor = [TDConstants headerTextColor];
}

- (void)prepareForReuse {
    debug NSLog(@"inside TDLocationCell - prepareForReuse");
    CGRect bottomLineRect = self.bottomLine.frame;
    bottomLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    bottomLineRect.size.width = SCREEN_WIDTH;
    self.bottomLine.frame = bottomLineRect;
    self.bottomLine.backgroundColor = [TDConstants lightBorderColor];
    
    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    topLineRect.size.width = SCREEN_WIDTH;
    self.topLine.frame = bottomLineRect;
    self.topLine.backgroundColor = [TDConstants lightBorderColor];
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
