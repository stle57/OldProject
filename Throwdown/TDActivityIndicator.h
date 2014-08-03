//
//  TDActivityIndicator.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDActivityIndicator : UIView
{
}

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

- (void)startSpinner;
- (void)stopSpinner;
- (void)setMessage:(NSString *)text;
- (void)startSpinnerWithMessage:(NSString *)text;

@end
