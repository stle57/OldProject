//
//  TDUserEditCell.m
//  Throwdown
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
    lineRect.size.height = 0.25;
    self.bottomLine.frame = lineRect;
    lineRect = self.topLine.frame;
    lineRect.size.height = 0.25;
    self.topLine.frame = lineRect;
    self.userImageView.layer.cornerRadius = self.userImageView.layer.frame.size.width / 2;
    self.userImageView.clipsToBounds = YES;

    textViewdOrigRect = self.textView.frame;
    bottomLineOrigY = self.bottomLine.frame.origin.y ;
    topLineOrigHeight = self.topLine.frame.size.height;
    bottomLineOrigHeight = self.bottomLine.frame.size.height;
    
    CALayer * postLayer = [self layer];
    [postLayer setMasksToBounds:YES];
    [postLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle
    
    self.topLine.layer.borderColor = [[TDConstants brandingRedColor] CGColor];
    
    self.layer.borderColor = [[TDConstants cellBorderColor] CGColor];
    self.layer.borderWidth = .25;
}

@end
