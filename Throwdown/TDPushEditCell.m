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
    
    CGRect emailButtonFrame = self.emailButton.frame;
    emailButtonFrame.origin.x = SCREEN_WIDTH - TD_MARGIN - self.emailButton.frame.size.width-5;
    emailButtonFrame.origin.y = 10;
    self.emailButton.frame = emailButtonFrame;
    CGSize origSizeEmail = self.emailButton.frame.size;
    
    CGRect rect1 = CGRectMake(self.emailButton.frame.origin.x -10,
                              self.emailButton.frame.origin.y - 10,
                              self.emailButton.frame.size.width +20,
                              self.emailButton.frame.size.height+20);
    self.emailButton.frame = rect1;
    [self addSubview:self.emailButton];
    
    CGRect pushButtonFrame = self.pushButton.frame;
    pushButtonFrame.origin.x = SCREEN_WIDTH - TD_MARGIN - origSizeEmail.width - self.pushButton.frame.size.width - 30-5;
    pushButtonFrame.origin.y = 10;
    self.pushButton.frame = pushButtonFrame;
    
    CGRect rect2 = CGRectMake(self.pushButton.frame.origin.x -5,
                              self.pushButton.frame.origin.y - 2.5,
                              self.pushButton.frame.size.width +10,
                              self.pushButton.frame.size.height+5);
    self.pushButton.frame = rect2;
    [self addSubview:self.pushButton];

    CGRect segmentControlFrame = self.segmentControl.frame;
    segmentControlFrame.origin.x = SCREEN_WIDTH -TD_MARGIN -self.segmentControl.frame.size.width;
    segmentControlFrame.origin.y = 10;
    self.segmentControl.frame = segmentControlFrame;
    [self addSubview:self.segmentControl];
    
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
    
}

- (IBAction)segmentChanged:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchValue:forIndexPath:)]) {
        [self.delegate switchValue:[NSNumber numberWithInteger:self.segmentControl.selectedSegmentIndex] forIndexPath:self.indexPath];
    }
}

- (IBAction)switch:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchValue:forIndexPath:)]) {
//        [self.delegate switchValue:[NSNumber numberWithBool:self.aSwitch.on] forIndexPath:self.indexPath];
    }
}

- (IBAction)emailButtonPressed:(UIButton*)sender {
    self.emailValue = !self.emailValue;
    if (self.delegate && [self.delegate respondsToSelector:@selector(emailValue:forIndexPath:)]) {
        [self.delegate emailValue:self.emailValue forIndexPath:self.indexPath];
    }
}

- (IBAction)pushButtonPressed:(UIButton*)sender {
    self.pushValue = !self.pushValue;
    if (self.delegate && [self.delegate respondsToSelector:@selector(pushValue:forIndexPath:)]) {
        [self.delegate pushValue:self.pushValue forIndexPath:self.indexPath];
    }}
@end
