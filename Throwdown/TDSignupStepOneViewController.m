//
//  TDSignupViewController.m
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSignupStepOneViewController.h"
#import "TDSignupStepTwoViewController.h"
#import "TDViewControllerHelper.h"
#import "TDAPIClient.h"
#import "TDConstants.h"
#import "NBPhoneNumberUtil.h"
#import <QuartzCore/QuartzCore.h>

@interface TDSignupStepOneViewController ()<UITextFieldDelegate>

//@property (nonatomic, weak) IBOutlet UITextField *phoneField;
//@property (nonatomic, weak) IBOutlet UITextField *nameField;
//@property (nonatomic, weak) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) NSRegularExpression *namePattern;
@property (nonatomic, copy) NSString *verifiedPhoneNumber;
@property (nonatomic, copy) NSString *validatingEmail;
@property (nonatomic) BOOL phoneIsVerified;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *firstLastName;

- (IBAction)backButtonPressed:(UIButton *)sender;
@end

@implementation TDSignupStepOneViewController

typedef NS_ENUM(NSInteger, TDSignupFields) {
    TDPhoneField,
    TDNameField,
    TDPasswordField
};

- (void)viewDidLoad {
    [super viewDidLoad];

    self.phoneIsVerified = NO;

    NSError *error = nil;
    self.namePattern = [NSRegularExpression regularExpressionWithPattern:@"\\w+\\s+\\w+"
                                                                 options:0
                                                                   error:&error];

    self.topLabel.font = [UIFont fontWithName:@"ProximaNova-Light" size:20.0];
    self.friendsLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:17.0];

    // Textfields
    [self.phoneNumberTextField setUpWithIconImageNamed:@"reg_ico_phone"
                                           placeHolder:@"Phone Number"
                                                  type:kTDTextFieldType_Phone
                                              delegate:self];
    [self.emailTextField setUpWithIconImageNamed:@"reg_ico_email"
                                     placeHolder:@"Email Address"
                                            type:kTDTextFieldType_Email
                                        delegate:self];
    [self.firstLastNameTextField setUpWithIconImageNamed:@"reg_ico_name"
                                             placeHolder:@"First and Last Name"
                                                    type:kTDTextFieldType_FirstLast
                                                delegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.phoneNumberTextField becomeFirstResponder];
}

- (void)dealloc
{
    self.verifiedPhoneNumber = nil;
    self.validatingEmail = nil;
    self.phoneNumber = nil;
    self.emailAddress = nil;
    self.firstLastName = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

# pragma mark - lazy instantiation

- (NSString *)verifiedPhoneNumber
{
    if (!_verifiedPhoneNumber) {
        _verifiedPhoneNumber = @"";
    }
    return _verifiedPhoneNumber;
}

#pragma mark - TDTextField delegates
-(void)textFieldDidChange:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_Phone:
        {
            self.phoneNumber = textField.text;
            [self validatePhoneField];
        }
        break;
        case kTDTextFieldType_Email:
        {
            self.emailAddress = textField.text;
            [self validateEmailField];
        }
        break;
        case kTDTextFieldType_FirstLast:
        {
            self.firstLastName = textField.text;
            [self validateNameField];
        }
        break;

        default:
        break;
    }

    [self validateAllFields];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_Phone:
        {
            self.phoneNumber = textField.text;
            [self validatePhoneField];
            [self.emailTextField becomeFirstResponder];
        }
        break;
        case kTDTextFieldType_Email:
        {
            self.emailAddress = textField.text;
            [self validateEmailField];
            [self.firstLastNameTextField becomeFirstResponder];
        }
        break;
        case kTDTextFieldType_FirstLast:
        {
            self.firstLastName = textField.text;
            [self validateNameField];
            [self.phoneNumberTextField becomeFirstResponder];
            if ([self validateAllFields]) {
                // TODO: might not trigger transition if the verification from server isn't complete
                [self transitionToStepTwoController];
            }
        }
        break;

        default:
        break;
    }

    [self validateAllFields];

    return NO;
}

# pragma mark - delegates

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonPressed:(id)sender {
    if ([self validateAllFields]) {
        [self transitionToStepTwoController];
    }
}

# pragma mark - navigation

- (void)transitionToStepTwoController
{
    [self performSegueWithIdentifier:@"signupStepTwo" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"signupStepTwo"]) {
        TDSignupStepTwoViewController *vc = [segue destinationViewController];
        [vc userParameters:@{@"phone_number": self.verifiedPhoneNumber, @"name": self.firstLastName, @"email": self.emailAddress}];
    }
}

# pragma mark - Validations

- (BOOL)validateAllFields
{
    BOOL valid = self.phoneNumberTextField.valid && self.emailTextField.valid && self.firstLastNameTextField.valid;
    self.nextButton.hidden = !valid;
    return valid;
}

- (void)validatePhoneField
{
    if (!self.phoneNumber) {
        return;
    }

    if (![self.phoneNumber isEqualToString:self.verifiedPhoneNumber]) {
        self.phoneIsVerified = NO;

        NSError *error = nil;
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        NBPhoneNumber *aPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:self.phoneNumber error:&error];
        if (!error && [phoneUtil isValidNumber:aPhoneNumber]) {
            NSString *phoneNumberString = [phoneUtil format:aPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
            self.verifiedPhoneNumber = phoneNumberString;
            [self.phoneNumberTextField startSpinner];
            [[TDAPIClient sharedInstance] validateCredentials:@{@"phone_number": phoneNumberString} callback:^(BOOL success) {
                self.phoneIsVerified = success;
                [self.phoneNumberTextField stopSpinner];
                [self.phoneNumberTextField status:success];
            }];
        } else {
            [self.phoneNumberTextField stopSpinner];
            [self.phoneNumberTextField status:NO];
            [self validateAllFields];
        }

        [self validateAllFields];
    }
}

- (BOOL)validateNameField
{
    if (!self.firstLastName) {
        return NO;
    }

    [self.firstLastNameTextField status:NO];
    NSString *name = self.firstLastName;
    NSRange match = [self.namePattern rangeOfFirstMatchInString:name
                                                        options:0
                                                          range:NSMakeRange(0, [name length])];
    BOOL returnValue = [name length] > 4 && match.location != NSNotFound;
    if (returnValue) {
        [self.firstLastNameTextField status:YES];
    }

    [self validateAllFields];

    return returnValue;
}

- (BOOL)validateEmailField
{
    NSString *email = self.emailAddress;
    if ([TDViewControllerHelper validateEmail:email] && ![email isEqualToString:self.validatingEmail]) {
        self.validatingEmail = email;
        [[TDAPIClient sharedInstance] validateCredentials:@{@"email": email} callback:^(BOOL valid) {

            if (valid) {
                [self.emailTextField status:valid];
            } else {
                [self.emailTextField status:NO];
            }
        }];
    } else {
        [self.emailTextField status:NO];
    }

    [self validateAllFields];

    return self.emailTextField.valid;
}

@end
