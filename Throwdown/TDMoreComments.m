//
//  TDMoreComments.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDMoreComments.h"
#import "TDAppDelegate.h"

@implementation TDMoreComments

@synthesize delegate;
@synthesize row;

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
    origMoreLabelRect = self.moreLabel.frame;
    self.moreLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:14.0];
}

-(void)moreCount:(NSInteger)count
{
    self.moreImageView.hidden = YES;
    self.moreLabel.hidden = YES;

    // more label
    self.moreLabel.frame = origMoreLabelRect;
    self.moreLabel.text = [NSString stringWithFormat:@"%lu more", (long)(count-2)];
    [TDAppDelegate fixWidthOfThisLabel:self.moreLabel];
    self.moreLabel.center = CGPointMake(CGRectGetMaxX(self.moreImageView.frame)+self.moreLabel.frame.size.width/2.0+4.0,
                                        self.moreLabel.center.y);
    self.moreLabel.hidden = NO;

    // more image
    self.moreImageView.hidden = NO;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

@end
