//
//  TDActivityCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/28/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDActivityCell.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"

@implementation TDActivityCell

- (void)dealloc
{
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.layer.borderColor = [[TDConstants lightBorderColor] CGColor];
        self.layer.borderWidth = TD_CELL_BORDER_WIDTH;

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

-(void)startSpinner
{
    [self.spinner startAnimating];
}

@end
