//
//  TDSignupStepTwoViewController.h
//  Throwdown
//
//  Created by Andrew C on 2/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDTextField.h"
#import "TDAppCoverBackgroundView.h"

@interface TDSignupStepTwoViewController : UIViewController <TDTextFieldDelegate, UIGestureRecognizerDelegate>
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withImage:(UIImage*)withImage;

@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet TDAppCoverBackgroundView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *privacyLabel1;
@property (weak, nonatomic) IBOutlet UIButton *privacyButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progress;
@property (weak, nonatomic) IBOutlet TDTextField *userNameTextField;
@property (weak, nonatomic) IBOutlet TDTextField *passwordTextField;
@property (nonatomic) UIGestureRecognizer *tapper;
@property (nonatomic) UIImage *blurredImage;

- (void)userParameters:(NSDictionary *)parameters;
- (IBAction)signupButtonPressed:(id)sender;
- (IBAction)privacyButtonPressed:(id)sender;
@end
