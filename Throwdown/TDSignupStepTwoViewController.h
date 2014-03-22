//
//  TDSignupStepTwoViewController.h
//  Throwdown
//
//  Created by Andrew C on 2/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDTextField.h"

@interface TDSignupStepTwoViewController : UIViewController <TDTextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *privacyLabel1;
@property (weak, nonatomic) IBOutlet UIButton *privacyButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progress;
@property (weak, nonatomic) IBOutlet TDTextField *userNameTextField;
@property (weak, nonatomic) IBOutlet TDTextField *passwordTextField;

- (void)userParameters:(NSDictionary *)parameters;
- (IBAction)signupButtonPressed:(id)sender;
- (IBAction)privacyButtonPressed:(id)sender;
@end
