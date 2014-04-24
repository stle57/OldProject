//
//  TDUploadMoreCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUploadMoreCell.h"
#import "TDAppDelegate.h"

@implementation TDUploadMoreCell

- (void)dealloc
{
}

- (void)awakeFromNib {
    self.uploadMoreLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:18.0];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

@end
