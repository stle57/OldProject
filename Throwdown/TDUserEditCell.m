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

- (void)dealloc
{
    delegate = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib {
    self.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:19.0];
    self.middleLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:19.0];
    self.leftMiddleLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:19.0];
    self.textField.font = [UIFont fontWithName:@"ProximaNova-Regular" size:18.0];
    self.textView.font = [UIFont fontWithName:@"ProximaNova-Regular" size:18.0];
    self.textField.textColor = [UIColor colorWithRed:(22.0/255.0) green:(22.0/255.0) blue:(22.0/255.0) alpha:1.0];
    self.textView.textColor = [UIColor colorWithRed:(22.0/255.0) green:(22.0/255.0) blue:(22.0/255.0) alpha:1.0];
    self.leftMiddleLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c
    self.middleLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c
    CGRect lineRect = self.bottomLine.frame;
    lineRect.size.height = 0.5;
    self.bottomLine.frame = lineRect;
    lineRect = self.topLine.frame;
    lineRect.size.height = 0.5;
    self.topLine.frame = lineRect;
    self.userImageView.layer.cornerRadius = self.userImageView.layer.frame.size.width / 2;
    self.userImageView.clipsToBounds = YES;


    textViewdOrigRect = self.textView.frame;
    bottomLineOrigY = self.bottomLine.frame.origin.y;
}

@end
