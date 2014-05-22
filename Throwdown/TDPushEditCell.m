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

@synthesize delegate;
@synthesize bottomLineOrigY;
@synthesize rowNumber;

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
    self.longTitleLabel.font = [UIFont fontWithName:TDFontProximaNovaRegular size:15.5];
    CGRect lineRect = self.bottomLine.frame;
    lineRect.size.height = 0.5;
    self.bottomLine.frame = lineRect;
    lineRect = self.topLine.frame;
    lineRect.size.height = 0.5;
    self.topLine.frame = lineRect;
    bottomLineOrigY = self.bottomLine.frame.origin.y;
}

-(IBAction)switch:(id)sender
{
    NSLog(@"SW");

    if (self.aSwitch.on) {
        if (delegate) {
            if ([delegate respondsToSelector:@selector(switchOnFromRow:)]) {
                [delegate switchOnFromRow:rowNumber];
            }
        }
    } else {
        if (delegate) {
            if ([delegate respondsToSelector:@selector(switchOffFromRow:)]) {
                [delegate switchOffFromRow:rowNumber];
            }
        }
    }
}

@end
