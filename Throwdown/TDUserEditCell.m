//
//  TDUserEditCell.m
//  ;
//
//  Created by Andrew Bennett on 4/9/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserEditCell.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>

@implementation TDUserEditCell

@synthesize delegate;
@synthesize textViewdOrigRect;
@synthesize bottomLineOrigY;
@synthesize topLineOrigHeight;
@synthesize topLine;
@synthesize bottomLine;
@synthesize bottomLineOrigHeight;

- (void)dealloc
{
    delegate = nil;
}

- (void)awakeFromNib {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGRect cellFrame = self.frame;
    cellFrame.size.width = width;
    self.frame = cellFrame;
    self.contentView.frame = cellFrame;

    self.titleLabel.font      = [TDConstants fontRegularSized:16.0];
    self.titleLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c
    self.longTitleLabel.font  = [TDConstants fontRegularSized:16.0];
    self.longTitleLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c
    self.middleLabel.font     = [TDConstants fontRegularSized:16.0];
    self.leftMiddleLabel.font = [TDConstants fontRegularSized:16.0];
    self.textField.font       = [TDConstants fontRegularSized:16.0];
    self.textView.font        = [TDConstants fontRegularSized:16.0];
    self.textField.textColor  = [TDConstants headerTextColor]; //4c4c4c
    self.textView.textColor   = [TDConstants headerTextColor]; //4c4c4c
    self.leftMiddleLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c
    self.middleLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c

    CGRect lineRect = self.bottomLine.frame;
    lineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    lineRect.size.width = width;
    self.bottomLine.frame = lineRect;

    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.width = width;
    topLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.topLine.frame = topLineRect;

    self.userImageView.layer.cornerRadius = self.userImageView.layer.frame.size.width / 2;
    self.userImageView.clipsToBounds = YES;

    textViewdOrigRect = self.textView.frame;
    bottomLineOrigY = self.bottomLine.frame.origin.y ;
    topLineOrigHeight = self.topLine.frame.size.height;
    bottomLineOrigHeight = self.bottomLine.frame.size.height;

    self.topLine.backgroundColor = [TDConstants lightBorderColor];
    self.bottomLine.backgroundColor = [TDConstants lightBorderColor];
}

@end
