//
//  TDUserProfileCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserProfileCell.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>

@implementation TDUserProfileCell

@synthesize delegate;

- (void)dealloc {
    delegate = nil;
}

- (void)awakeFromNib {
    self.userNameLabel.font = TITLE_FONT;
    self.bioLabel.font = BIO_FONT;
    self.userImageView.layer.cornerRadius = 30;
    self.userImageView.layer.masksToBounds = YES;
}

@end
