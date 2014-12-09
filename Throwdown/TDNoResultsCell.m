//
//  TDNoResultsCell.m
//  Throwdown
//
//  Created by Stephanie Le on 12/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDNoResultsCell.h"
#import "TDConstants.h"

@implementation TDNoResultsCell

- (void)awakeFromNib {
    CGRect cellFrame = self.frame;
    cellFrame.size.width = SCREEN_WIDTH;
    cellFrame.size.height = SCREEN_HEIGHT;
    self.frame = cellFrame;

    self.noMatchesLabel.font = [TDConstants fontSemiBoldSized:17];
    self.noMatchesLabel.textColor = [TDConstants headerTextColor];
    
    self.noMatchesLabel.frame= CGRectMake(0, 30, SCREEN_WIDTH, 29);
    [self addSubview:self.noMatchesLabel];
    
    [self.descriptionLabel setNumberOfLines:0];
    [self.descriptionLabel sizeToFit];
    CGRect descriptionFrame = self.descriptionLabel.frame;
    descriptionFrame.origin.x = SCREEN_WIDTH/2 - self.descriptionLabel.frame.size.width/2;
    descriptionFrame.origin.y = SCREEN_HEIGHT/2;
    self.descriptionLabel.frame = descriptionFrame;
    
    [self addSubview:self.descriptionLabel];}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
