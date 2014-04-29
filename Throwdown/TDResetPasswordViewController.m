//
//  TDResetPasswordViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/29/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDResetPasswordViewController.h"
#import "TDViewControllerHelper.h"
#import "TDUserAPI.h"
#import "NBPhoneNumberUtil.h"

@interface TDResetPasswordViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic, copy) NSString *emailOrPhoneNumber;

- (IBAction)backButtonPressed:(UIButton *)sender;
@end

@implementation TDResetPasswordViewController

-(void)viewDidLoad
{
    [super viewDidLoad];

    self.topLabel.font = [UIFont fontWithName:@"ProximaNova-Light" size:20.0];

    // Textfields
    [self.userNameTextField setUpWithIconImageNamed:@"reg_ico_email"
                                        placeHolder:@"Email Address"//@"Email or Phone Number"
                                       keyboardType:UIKeyboardTypeEmailAddress
                                               type:kTDTextFieldType_UsernameOrPhoneNumber
                                           delegate:self];

    // Small fix if 3.5" screen
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        // move up log in button slightly
        self.resetButton.center = CGPointMake(self.resetButton.center.x,
                                              self.resetButton.center.y+2.0);
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
    self.emailOrPhoneNumber = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - TDTextField delegates
-(void)textFieldDidChange:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_UsernameOrPhoneNumber:
        {
            self.emailOrPhoneNumber = textField.text;
        }
        break;
        default:
        break;
    }

    //    if ([self validatePhoneField] || [self validateEmailField]) {
    if ([self validateEmailField]) {
        self.resetButton.enabled = YES;
    } else {
        self.resetButton.enabled = NO;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_UsernameOrPhoneNumber:
        {
            self.emailOrPhoneNumber = textField.text;
        }
        break;
        default:
        break;
    }

//    if ([self validatePhoneField] || [self validateEmailField]) {
    if ([self validateEmailField]) {
        self.resetButton.enabled = YES;
    } else {
        self.resetButton.enabled = NO;
    }

    return NO;
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)resetButtonPressed:(id)sender {

    // Resign
    [self.userNameTextField resignFirst];

    self.backButton.enabled = NO;
    self.resetButton.hidden = YES;
    self.resetButton.enabled = NO;

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
                             [[TDUserAPI sharedInstance] resetPassword:self.emailOrPhoneNumber callback:^(BOOL success, NSDictionary *dict) {

                                 if (success) {
                                     [TDViewControllerHelper showAlertMessage:@"Password Reset Information has been sent to you." withTitle:nil];
                                     [TDViewControllerHelper navigateToHomeFrom:self];
                                 } else {
                                     [TDViewControllerHelper showAlertMessage:@"Incorrect reset info provided.\nPlease try again." withTitle:nil];
                                     self.resetButton.enabled = YES;
                                     self.resetButton.hidden = NO;
                                     self.backButton.enabled = YES;
                                     [self.progress stopAnimating];
                                     [self.userNameTextField becomeFirstResponder];
                                 }
                             }];
                         }
                     }];
}

- (BOOL)validatePhoneField {

    NSError *error = nil;
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NBPhoneNumber *parsedPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:self.emailOrPhoneNumber error:&error];
    if (!error && [phoneUtil isValidNumber:parsedPhoneNumber]) {
        self.emailOrPhoneNumber = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
        return YES;

//        [self.phoneNumberTextField startSpinner];
//        [self validateField:kTDTextFieldType_Phone];
    } else {
        return NO;
//        [self.phoneNumberTextField status:NO];
    }
}

- (BOOL)validateEmailField {
    if ([TDViewControllerHelper validateEmail:self.emailOrPhoneNumber]) {
//        [self.emailTextField startSpinner];
//        [self validateField:kTDTextFieldType_Email];
        return YES;
    } else {
        return NO;
//        [self.userNameTextField status:NO];
    }
}

@end
