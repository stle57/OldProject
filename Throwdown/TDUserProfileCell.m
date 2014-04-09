//
//  TDUserProfileCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserProfileCell.h"
#import "TDAppDelegate.h"

@implementation TDUserProfileCell

@synthesize delegate;

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
    self.userNameLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:19.0];
}

@end
