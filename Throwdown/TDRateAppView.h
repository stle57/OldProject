//
//  TDRateAppView.h
//  Throwdown
//
//  Created by Stephanie Le on 11/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDFeedbackViewController.h"

#define TD_BUTTON_HEIGHT 49.
@protocol CustomAlertDelegate
@end

@interface TDRateAppView : UIView
{
    id delegate;
    UIView *AlertView;
}

@property (weak, nonatomic) IBOutlet UIImageView *tdIcon;
@property (weak, nonatomic) IBOutlet UIButton *rateButton;
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UIView *divider;
@property (weak, nonatomic) IBOutlet UIView *divider2;
@property (weak, nonatomic) IBOutlet UIView *divider3;
@property (nonatomic, retain) TDFeedbackViewController *feedbackVC;

+ (id)rateView;
- (void)showInView;

- (IBAction)dismissButtonPressed:(UIButton *)sender;
- (IBAction)feedbackButtonPressed:(UIButton *)sender;
- (IBAction)rateButtonPressed:(UIButton *)sender;

@end
