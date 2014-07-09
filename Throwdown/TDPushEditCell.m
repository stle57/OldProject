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
    CGRect lineRect = self.bottomLine.frame;
    lineRect.size.height = 0.5;
    self.bottomLine.frame = lineRect;
    lineRect = self.topLine.frame;
    lineRect.size.height = 0.5;
    self.topLine.frame = lineRect;
    self.bottomLineOrigY = self.bottomLine.frame.origin.y;
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
