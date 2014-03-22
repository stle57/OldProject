//
//  TDSignupStepTwoViewController.m
//  Throwdown
//
//  Created by Andrew C on 2/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSignupStepTwoViewController.h"
#import "TDViewControllerHelper.h"
#import "TDAPIClient.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "TDUserAPI.h"

@interface TDSignupStepTwoViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) NSMutableDictionary *userParameters;
@property (strong, nonatomic) NSRegularExpression *usernamePattern;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *password;

- (IBAction)backButtonPressed:(UIButton *)sender;
@end

@implementation TDSignupStepTwoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSError *error = nil;
    self.usernamePattern = [NSRegularExpression regularExpressionWithPattern:@"[^\\w+\\d++_]"
                                                                 options:0
                                                                   error:&error];

    [self.userNameTextField textfieldText:self.userName];
    [self validateUsernameField];

    self.topLabel.font = [UIFont fontWithName:@"ProximaNova-Light" size:20.0];
    self.privacyLabel1.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:14.0];
    self.privacyButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:14.0];

    // Textfields
    [self.userNameTextField setUpWithIconImageNamed:@"reg_ico_username"
                                        placeHolder:@"User Name"
                                       keyboardType:UIKeyboardTypeTwitter
                                               type:kTDTextFieldType_UserName
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
        self.privacyLabel1.center = CGPointMake(self.privacyLabel1.center.x,
                                                self.privacyLabel1.center.y-12.0);
        self.privacyButton.center = CGPointMake(self.privacyButton.center.x,
                                                self.privacyButton.center.y-14.0);
        self.signUpButton.center = CGPointMake(self.signUpButton.center.x,
                                               self.signUpButton.center.y-28.0);
        UIImage *backgroundImage = [UIImage imageNamed:@"reg_bg3_480"];
        self.backgroundImageView.image = backgroundImage;
        backgroundImage = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.userNameTextField becomeFirstResponder];
}

- (void)dealloc {
    self.userName = nil;
    self.password = nil;
    self.userParameters = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)backButtonPressed {
    // TODO: confirm navigating back if fields are edited.
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)signupButtonPressed:(id)sender {
    [self signup];
}

- (IBAction)privacyButtonPressed:(id)sender {
    // Goto privacy
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://throwdown.us/tos"]];
}

- (void)signup {

    [self.userParameters addEntriesFromDictionary:@{ @"password":self.password, @"username":self.userName }];

    // Resign
    [self.userNameTextField resignFirst];
    [self.passwordTextField resignFirst];

    // No back or singup until we're back from server
    self.backButton.enabled = NO;

    self.progress.alpha = 0.0;
    self.signUpButton.hidden = YES;
    self.signUpButton.enabled = NO;
    self.progress.hidden = NO;
    [self.progress startAnimating];

    [UIView animateWithDuration: 0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.progress.alpha = 1.0;
                     }
                     completion:^(BOOL animDone){
                         if (animDone) {
                             [[TDUserAPI sharedInstance] signupUser:self.userParameters callback:^(BOOL success) {
                                 if (success) {
                                     self.progress.hidden = YES;
                                     [TDViewControllerHelper navigateToHomeFrom:self];
                                 } else {
                                     [TDViewControllerHelper showAlertMessage:@"There was an error, please try again." withTitle:@"Error"];
                                     self.signUpButton.enabled = YES;
                                     self.backButton.enabled = YES;
                                     self.progress.hidden = YES;
                                     self.signUpButton.hidden = NO;
                                     [self.userNameTextField becomeFirstResponder];
                                 }
                             }];
                         }
                     }];
}

- (void)userParameters:(NSDictionary *)parameters {
    self.userParameters = [parameters mutableCopy];
    self.userName = [self.userParameters objectForKey:@"username"];
}

#pragma mark - TDTextField delegates
- (void)textFieldDidBeginEditing:(UITextField *)textField type:(kTDTextFieldType)type {
    [self validateAllFields];
}

- (void)textFieldDidChange:(UITextField *)textField type:(kTDTextFieldType)type {
    switch (type) {
        case kTDTextFieldType_UserName:
            self.userName = textField.text;
            [self validateUsernameField];
        break;

        case kTDTextFieldType_Password:
            self.password = textField.text;
            [self validatePassword];
        break;
    }

    [self validateAllFields];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField type:(kTDTextFieldType)type {
    [self textFieldDidChange:textField type:type];
    switch (type) {
        case kTDTextFieldType_UserName:
            [self.passwordTextField becomeFirstResponder];
        break;

        case kTDTextFieldType_Password:
            [self.userNameTextField becomeFirstResponder];
        break;
    }

    return NO;
}

#pragma mark - Validations

- (BOOL)validateAllFields {
    BOOL valid = self.userNameTextField.valid && self.passwordTextField.valid;
    self.signUpButton.enabled = valid;
    return valid;
}

- (void)validateUsernameField {
    if (!self.userName || [self.userName length] == 0) {
        return;
    }

    NSString *username = self.userName;
    NSRange match = [self.usernamePattern rangeOfFirstMatchInString:username
                                                        options:0
                                                          range:NSMakeRange(0, [username length])];

    if (match.location == NSNotFound) {
        [self.userNameTextField startSpinner];
        [[TDAPIClient sharedInstance] validateCredentials:@{ @"username":username } success:^(NSDictionary *response) {
            [self.userNameTextField status:[[response objectForKey:@"username"] boolValue]];
            [self validateAllFields];
        } failure:^{
            [self.userNameTextField status:NO];
            [self validateAllFields];
        }];
    } else {
        [self.userNameTextField status:NO];
        [self validateAllFields];
    }
}

- (void)validatePassword {
    if ([self.password length] < 6) {
        [self.passwordTextField status:NO];
    } else {
        [self.passwordTextField status:YES];
    }
    [self validateAllFields];
}

@end
