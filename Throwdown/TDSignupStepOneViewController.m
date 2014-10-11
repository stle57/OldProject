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
#import "TDAnalytics.h"

@interface TDSignupStepOneViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) NSRegularExpression *namePattern;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *firstLastName;
@property (nonatomic, copy) NSString *username;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextButtonOffset;

- (IBAction)backButtonPressed:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *numberLabelOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameOffset;
@end

@implementation TDSignupStepOneViewController

typedef NS_ENUM(NSInteger, TDSignupFields) {
    TDPhoneField,
    TDNameField,
    TDPasswordField
};

- (void)viewDidLoad {
    [super viewDidLoad];

    [[TDAnalytics sharedInstance] logEvent:@"signup_step_one"];

    NSError *error = nil;
    self.namePattern = [NSRegularExpression regularExpressionWithPattern:@"\\w+"
                                                                 options:0
                                                                   error:&error];

    self.topLabel.font = [UIFont fontWithName:@"ProximaNova-Light" size:20.0];
    self.friendsLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:17.0];

    // Textfields
    [self.phoneNumberTextField setUpWithIconImageNamed:@"reg_ico_phone"
                                           placeHolder:@"Phone Number"
                                          keyboardType:UIKeyboardTypePhonePad
                                                  type:kTDTextFieldType_Phone
                                              delegate:self];
    [self.emailTextField setUpWithIconImageNamed:@"reg_ico_email"
                                     placeHolder:@"Email Address"
                                    keyboardType:UIKeyboardTypeEmailAddress
                                            type:kTDTextFieldType_Email
                                        delegate:self];
    [self.firstLastNameTextField setUpWithIconImageNamed:@"reg_ico_name"
                                             placeHolder:@"First and Last Name"
                                            keyboardType:UIKeyboardTypeNamePhonePad
                                                    type:kTDTextFieldType_FirstLast
                                                delegate:self];

    // Small fix if 3.5" screen
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.nextButtonOffset.constant += 54;
        self.numberLabelOffset.constant += 10;
        self.nameOffset.constant -= 20;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.firstLastNameTextField becomeFirstResponder];
}

- (void)dealloc {
    self.phoneNumber = nil;
    self.emailAddress = nil;
    self.firstLastName = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

# pragma mark - lazy instantiation

- (NSString *)firstLastName {
    if (!_firstLastName) {
        _firstLastName = @"";
    }
    return _firstLastName;
}

- (NSString *)emailAddress {
    if (!_emailAddress) {
        _emailAddress = @"";
    }
    return _emailAddress;
}

- (NSString *)phoneNumber {
    if (!_phoneNumber) {
        _phoneNumber = @"";
    }
    return _phoneNumber;
}

- (NSString *)username {
    if (!_username) {
        _username = @"";
    }
    return _username;
}



#pragma mark - TDTextField delegates
- (void)textFieldDidBeginEditing:(UITextField *)textField type:(kTDTextFieldType)type {
    [self validateAllFields];
}

- (void)textFieldDidChange:(UITextField *)textField type:(kTDTextFieldType)type {
    switch (type) {
        case kTDTextFieldType_Phone:
            self.phoneNumber = textField.text;
            [self validatePhoneField];
        break;
        case kTDTextFieldType_Email:
            self.emailAddress = textField.text;
            [self validateEmailField];
        break;
        case kTDTextFieldType_FirstLast:
            self.firstLastName = textField.text;
            [self validateNameField];
        break;
    }

    [self validateAllFields];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField type:(kTDTextFieldType)type {
    [self textFieldDidChange:textField type:type];
    switch (type) {
        case kTDTextFieldType_Phone:
            [self.emailTextField becomeFirstResponder];
        break;

        case kTDTextFieldType_Email:
            [self.firstLastNameTextField becomeFirstResponder];
        break;

        case kTDTextFieldType_FirstLast:
            [self.phoneNumberTextField becomeFirstResponder];
        break;
    }
    return NO;
}

# pragma mark - delegates

- (IBAction)backButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonPressed:(id)sender {
    if ([self validateAllFields]) {
        [self transitionToStepTwoController];
    }
}

# pragma mark - navigation

- (void)transitionToStepTwoController {
    [self performSegueWithIdentifier:@"signupStepTwo" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"signupStepTwo"]) {
        TDSignupStepTwoViewController *vc = [segue destinationViewController];
        [vc userParameters:[self userParameters]];
    }
}

# pragma mark - Validations

- (BOOL)validateAllFields {
    BOOL valid = self.phoneNumberTextField.valid && self.emailTextField.valid && self.firstLastNameTextField.valid;
    self.nextButton.enabled = valid;
    return valid;
}

- (void)validatePhoneField {
    NSError *error = nil;
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NBPhoneNumber *parsedPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:self.phoneNumber error:&error];
    self.phoneNumber = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
    if (!error && [phoneUtil isValidNumber:parsedPhoneNumber]) {
        [self.phoneNumberTextField startSpinner];
        [self validateField:kTDTextFieldType_Phone];
    } else {
        [self.phoneNumberTextField status:NO];
    }
}

- (void)validateNameField {
    [self.firstLastNameTextField status:NO];
    NSString *name = self.firstLastName;
    NSRange match = [self.namePattern rangeOfFirstMatchInString:name
                                                        options:0
                                                          range:NSMakeRange(0, [name length])];
    BOOL returnValue = [name length] >= 2 && match.location != NSNotFound;
    if (returnValue) {
        [self.firstLastNameTextField status:YES];
    } else {
        [self.firstLastNameTextField status:NO];
    }
    [self.firstLastNameTextField startSpinner];
    [self validateField:kTDTextFieldType_FirstLast];
    [self validateAllFields];
}

- (void)validateEmailField {
    if ([TDViewControllerHelper validateEmail:self.emailAddress]) {
        [self.emailTextField startSpinner];
        [self validateField:kTDTextFieldType_Email];
    } else {
        [self.emailTextField status:NO];
    }
}

- (NSDictionary *)userParameters {
    return @{@"phone_number":self.phoneNumber, @"name":self.firstLastName, @"email":self.emailAddress, @"username":self.username};
}

- (void)validateField:(kTDTextFieldType)field {
    [[TDAPIClient sharedInstance] validateCredentials:[self userParameters] success:^(NSDictionary *response) {

        switch (field) {
            case kTDTextFieldType_Phone:
                [self.phoneNumberTextField status:[[response objectForKey:@"phone_number"] boolValue]];
                break;

            case kTDTextFieldType_Email:
                [self.emailTextField status:[[response objectForKey:@"email"] boolValue]];
                break;

            case kTDTextFieldType_FirstLast:
                [self.firstLastNameTextField status:[[response objectForKey:@"name"] boolValue]];
                [self.firstLastNameTextField stopSpinner];
                break;
        }
        self.username = (NSString *)[response objectForKey:@"suggested_username"];
        [self validateAllFields];

    } failure:^{
        switch (field) {
            case kTDTextFieldType_Phone:
                [self.phoneNumberTextField status:NO];
                break;

            case kTDTextFieldType_Email:
                [self.emailTextField status:NO];
                break;

            case kTDTextFieldType_FirstLast:
                [self.firstLastNameTextField status:NO];
                [self.firstLastNameTextField stopSpinner];
                break;
        }
        [self validateAllFields];
    }];
}

@end
