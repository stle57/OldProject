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

@property (nonatomic, weak) IBOutlet UITextField *phoneField;
@property (nonatomic, weak) IBOutlet UITextField *nameField;
@property (nonatomic, weak) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) NSRegularExpression *namePattern;
@property (nonatomic, copy) NSString *verifiedPhoneNumber;
@property (nonatomic) BOOL phoneIsVerified;

@end

@implementation TDSignupStepOneViewController

typedef NS_ENUM(NSInteger, TDSignupFields) {
    TDPhoneField,
    TDNameField,
    TDPasswordField
};

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *button = [TDViewControllerHelper navBackButton];
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    self.phoneIsVerified = NO;

    self.phoneField.layer.cornerRadius = 4.0f;
    self.phoneField.layer.borderWidth = 1.0f;
    self.phoneField.clipsToBounds = YES;
    self.phoneField.delegate = self;

    self.nameField.layer.cornerRadius = 4.0f;
    self.nameField.layer.borderWidth = 1.0f;
    self.nameField.clipsToBounds = YES;
    self.nameField.delegate = self;

    self.passwordField.layer.cornerRadius = 4.0f;
    self.passwordField.layer.borderWidth = 1.0f;
    self.passwordField.clipsToBounds = YES;
    self.passwordField.delegate = self;

    [self.phoneField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.nameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    // button is hidden to start
    self.nextButton.layer.cornerRadius = 4;
    self.nextButton.clipsToBounds = YES;

    NSError *error = nil;
    self.namePattern = [NSRegularExpression regularExpressionWithPattern:@"\\w+\\s+\\w+"
                                                                 options:0
                                                                   error:&error];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.phoneField becomeFirstResponder];
}

- (void)dealloc
{
    [self.phoneField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.nameField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

# pragma mark - lazy instantiation

- (NSString *)verifiedPhoneNumber
{
    if (!_verifiedPhoneNumber) {
        _verifiedPhoneNumber = @"";
    }
    return _verifiedPhoneNumber;
}

# pragma mark - delegates

- (IBAction)nextButtonPressed:(id)sender {
    if ([self validateAllFields]) {
        [self transitionToStepTwoController];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    switch(textField.tag) {
        case TDPhoneField:
            [self validatePhoneField];
            break;
        case TDNameField:
            [self validateNameField];
            break;
        case TDPasswordField:
            // calls validate password implicitly:
            if ([self validateAllFields]) {
                // TODO: might not trigger transition if the verification from server isn't complete
                [self transitionToStepTwoController];
            }
            break;
    }

    UIResponder* nextResponder = [textField.superview viewWithTag:(textField.tag + 1)];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    }
    return NO;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    switch(textField.tag) {
        case TDPhoneField:
            [self validatePhoneField];
            break;
        case TDNameField:
            [self updateField:textField withStatus:[self validateNameField]];
            [self validateAllFields];
            break;
        case TDPasswordField:
            [self updateField:textField withStatus:[self validatePasswordField]];
            [self validateAllFields];
            break;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self textFieldDidChange:textField];
}

# pragma mark - navigation

- (void)backButtonPressed
{
    // TODO: confirm navigating back if fields are edited.
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)transitionToStepTwoController
{
    [self performSegueWithIdentifier:@"signupStepTwo" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"signupStepTwo"]) {
        TDSignupStepTwoViewController *vc = [segue destinationViewController];
        [vc userParameters:@{@"phone_number": self.verifiedPhoneNumber, @"name": self.nameField.text, @"password": self.passwordField.text}];
    }
}

# pragma mark - Validations

- (BOOL)validateAllFields
{
    BOOL valid = self.phoneIsVerified && [self validateNameField] && [self validatePasswordField];
    self.nextButton.hidden = !valid;
    return valid;
}

- (void)validatePhoneField
{
    if (![self.phoneField.text isEqualToString:self.verifiedPhoneNumber]) {
        self.phoneIsVerified = NO;

        NSError *error = nil;
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        NBPhoneNumber *phoneNumber = [phoneUtil parseWithPhoneCarrierRegion:self.phoneField.text error:&error];
        if (!error && [phoneUtil isValidNumber:phoneNumber]) {
            NSString *phoneNumberString = [phoneUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
            self.verifiedPhoneNumber = phoneNumberString;
            [[TDAPIClient sharedInstance] validateCredentials:@{@"phone_number": phoneNumberString} callback:^(BOOL success) {
                self.phoneIsVerified = success;
                [self updateField:self.phoneField withStatus:success];
                [self validateAllFields];
            }];
        } else {
            [self updateField:self.phoneField withStatus:NO];
            [self validateAllFields];
        }
    }
}

- (BOOL)validateNameField
{
    NSString *name = self.nameField.text;
    NSRange match = [self.namePattern rangeOfFirstMatchInString:name
                                                        options:0
                                                          range:NSMakeRange(0, [name length])];
    return [name length] > 4 && match.location != NSNotFound;
}

- (BOOL)validatePasswordField
{
    return [self.passwordField.text length] > 5;
}

# pragma mark - view helpers

- (void)updateField:(UITextField *)textField withStatus:(BOOL)status
{
    if (status) {
        textField.layer.borderColor = [[UIColor blackColor] CGColor];
    } else {
        textField.layer.borderColor = [[TDConstants brandingRedColor] CGColor];
    }
}

@end
