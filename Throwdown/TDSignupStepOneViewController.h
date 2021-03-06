//
//  TDSignupViewController.h
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDTextField.h"
#import "TDAppCoverBackgroundView.h"

@interface TDSignupStepOneViewController : UIViewController <TDTextFieldDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet TDAppCoverBackgroundView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *friendsLabel;
@property (weak, nonatomic) IBOutlet TDTextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet TDTextField *emailTextField;
@property (weak, nonatomic) IBOutlet TDTextField *firstLastNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (nonatomic) UIGestureRecognizer *tapper;
@property (nonatomic) UIImage *blurredImage;

@end
