//
//  TDPushEditCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/30/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPushEditCell.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>

@implementation TDPushEditCell

- (void)dealloc {
    self.delegate = nil;
    self.indexPath = nil;
}

- (void)awakeFromNib {
    self.longTitleLabel.font = [TDConstants fontRegularSized:16];
    CGRect titleLabelFrame = self.longTitleLabel.frame;
    titleLabelFrame.origin.x = TD_MARGIN;
    self.longTitleLabel.frame = titleLabelFrame;
    
    CGRect cellFrame = self.frame;
    cellFrame.size.width = SCREEN_WIDTH;
    self.frame = cellFrame;
    
    CGRect lineRect = self.bottomLine.frame;
    lineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    lineRect.size.width = SCREEN_WIDTH;
    self.bottomLine.frame = lineRect;
    
    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.width = SCREEN_WIDTH;
    topLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.topLine.frame = topLineRect;
    
    self.bottomLineOrigY = self.bottomLine.frame.origin.y;
    
    CGRect switchFrame = self.aSwitch.frame;
    switchFrame.origin.x = SCREEN_WIDTH - switchFrame.size.width - TD_MARGIN;
    self.aSwitch.frame = switchFrame;
    
    CGRect frame = self.segmentControl.frame;
    frame.origin.x = SCREEN_WIDTH - frame.size.width - TD_MARGIN;
    self.segmentControl.frame = frame;
}

- (IBAction)segmentChanged:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchValue:forIndexPath:)]) {
        [self.delegate switchValue:[NSNumber numberWithInteger:self.segmentControl.selectedSegmentIndex] forIndexPath:self.indexPath];
    }
}

- (IBAction)switch:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchValue:forIndexPath:)]) {
        [self.delegate switchValue:[NSNumber numberWithBool:self.aSwitch.on] forIndexPath:self.indexPath];
    }
}

@end
