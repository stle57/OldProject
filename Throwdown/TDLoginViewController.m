//
//  TDLoginViewController.m
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLoginViewController.h"
#import "TDViewControllerHelper.h"
#import "TDUserAPI.h"

@interface TDLoginViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *resetPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic, copy) NSString *userEmail;
@property (nonatomic, copy) NSString *password;

- (IBAction)backButtonPressed:(UIButton *)sender;
- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)resetPasswordButtonPressed:(id)sender;
@end

@implementation TDLoginViewController

-(void)viewDidLoad
{
    [super viewDidLoad];

    self.topLabel.font = [UIFont fontWithName:@"ProximaNova-Light" size:20.0];

    // Textfields
    [self.userNameTextField setUpWithIconImageNamed:@"reg_ico_email"
                                        placeHolder:@"Email Address"
                                       keyboardType:UIKeyboardTypeEmailAddress
                                               type:kTDTextFieldType_Email
                                           delegate:self];
    [self.passwordTextField setUpWithIconImageNamed:@"reg_ico_pass"
                                        placeHolder:@"Password"
                                       keyboardType:UIKeyboardTypeDefault
                                               type:kTDTextFieldType_Password
                                           delegate:self];
    [self.passwordTextField secure];

    // Small fix if 3.5" screen
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        // move up log in button slightly
        self.loginButton.center = CGPointMake(self.loginButton.center.x,
                                                self.loginButton.center.y+2.0);
        self.passwordTextField.center = CGPointMake(self.passwordTextField.center.x,
                                                    self.passwordTextField.center.y+2.0);
        UIImage *backgroundImage = [UIImage imageNamed:@"reg_bg2_480"];
        self.backgroundImageView.image = backgroundImage;
        backgroundImage = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.userNameTextField becomeFirstResponder];
}

- (void)dealloc {
    self.userEmail = nil;
    self.password = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - TDTextField delegates
-(void)textFieldDidChange:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_Email:
        {
            self.userEmail = textField.text;
        }
        break;
        case kTDTextFieldType_Password:
        {
            self.password = textField.text;
        }
        break;
        default:
        break;
    }

    if ([TDViewControllerHelper validateEmail:self.userEmail] && [self.password length] > 5) {
        self.loginButton.enabled = YES;
    } else {
        self.loginButton.enabled = NO;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_Email:
        {
            self.userEmail = textField.text;
            [self.passwordTextField becomeFirstResponder];
        }
        break;
        case kTDTextFieldType_Password:
        {
            self.password = textField.text;
            [self.userNameTextField becomeFirstResponder];
        }
        break;
        default:
        break;
    }

    if ([TDViewControllerHelper validateEmail:self.userEmail] && [self.password length] > 5) {
        self.loginButton.enabled = YES;
    } else {
        self.loginButton.enabled = NO;
    }

    return NO;
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)loginButtonPressed:(id)sender {

    // Resign
    [self.userNameTextField resignFirst];
    [self.passwordTextField resignFirst];

    self.backButton.enabled = NO;
    self.loginButton.hidden = YES;
    self.loginButton.enabled = NO;
    self.resetPasswordButton.enabled = NO;
    self.resetPasswordButton.hidden = YES;

    self.progress.alpha = 0.0;
    self.progress.hidden = NO;
    [self.progress startAnimating];

    [UIView animateWithDuration: 0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{

                         self.progress.alpha = 1.0;

                     }
                     completion:^(BOOL animDone){

                         if (animDone)
                         {
                             [[TDUserAPI sharedInstance] loginUser:self.userEmail withPassword:self.password callback:^(BOOL success) {
                                 if (success) {
                                     [TDViewControllerHelper navigateToHomeFrom:self];
                                     self.resetPasswordButton.enabled = YES;
                                     self.resetPasswordButton.hidden = NO;
                                 } else {
                                     [TDViewControllerHelper showAlertMessage:@"Incorrect login info provided. Please try again." withTitle:nil];
                                     self.loginButton.enabled = YES;
                                     self.loginButton.hidden = NO;
                                     self.resetPasswordButton.enabled = YES;
                                     self.resetPasswordButton.hidden = NO;
                                     self.backButton.enabled = YES;
                                     [self.progress stopAnimating];
                                     [self.userNameTextField becomeFirstResponder];
                                 }
                             }];
                         }
                     }];
}


@end
