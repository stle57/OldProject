//
//  TDActivityIndicator.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDActivityIndicator.h"
#import <QuartzCore/QuartzCore.h>
#import "TDConstants.h"

@implementation TDActivityIndicator

- (void)dealloc
{
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"TDActivityIndicator" owner:self options:nil];
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:[nibContents lastObject]];

        self.backgroundView.layer.cornerRadius = 8;
        self.text.font = [TDConstants fontSemiBoldSized:20];
    }
    return self;
}

-(void)startSpinner
{
    [self.spinner startAnimating];
}

-(void)stopSpinner
{
    [self.spinner stopAnimating];
}

@end
