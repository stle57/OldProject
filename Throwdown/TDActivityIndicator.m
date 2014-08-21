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

@interface TDActivityIndicator()

@property (nonatomic) CGRect originalTextLocation;

@end

@implementation TDActivityIndicator

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"TDActivityIndicator" owner:self options:nil];
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:[nibContents lastObject]];

        self.backgroundView.layer.cornerRadius = 8;
        self.text.font = [TDConstants fontSemiBoldSized:20];
        self.originalTextLocation = self.text.frame;
        self.text.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    }
    return self;
}

- (void)startSpinner {
    self.hidden = NO;
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
}

- (void)stopSpinner {
    [self.spinner stopAnimating];
    self.hidden = YES;
}

- (void)setMessage:(NSString *)text {
    self.text.text = text;
}

- (void)startSpinnerWithMessage:(NSString *)text {
    self.text.text = text;
    [self startSpinner];
}

- (void)showMessage:(NSString *)text forSeconds:(NSUInteger)seconds {
    CGRect frame = self.backgroundView.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    self.text.frame = frame;
    self.text.text = text;
    self.spinner.hidden = YES;
    self.hidden = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.hidden = YES;
        self.text.frame = self.originalTextLocation;
    });
}

@end
