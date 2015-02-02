//
//  TDResetPasswordViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/29/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDTextField.h"
#import "TDAppCoverBackgroundView.h"

@interface TDResetPasswordViewController : UIViewController <TDTextFieldDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
{

}

@property (weak, nonatomic) IBOutlet TDAppCoverBackgroundView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet TDTextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progress;
@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (nonatomic) UIGestureRecognizer *tapper;

@end
