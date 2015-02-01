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
#import "TDSignupStepTwoViewController.h"

@interface TDSignupStepOneViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton *continueButton;
@property (nonatomic, strong) NSRegularExpression *namePattern;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *firstLastName;
@property (nonatomic, copy) NSString *username;

- (IBAction)closeButtonPressed:(UIButton *)sender;
- (IBAction)continueButtonPressed:(id)sender;
@end

@implementation TDSignupStepOneViewController

typedef NS_ENUM(NSInteger, TDSignupFields) {
    TDPhoneField,
    TDNameField,
    TDPasswordField
};

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [[TDAnalytics sharedInstance] logEvent:@"signup_step_one"];

    [self.backgroundImageView setBackgroundImage:YES editingViewOnly:YES];
    
    self.alphaView.frame = self.view.frame;
    self.alphaView.backgroundColor = [UIColor clearColor];
    
    self.topLabel.text = @"Sign Up";
    self.topLabel.font = [TDConstants fontSemiBoldSized:18];
    self.topLabel.textColor = [TDConstants headerTextColor];
    [self.topLabel sizeToFit];
    
    CGRect topLabelFrame = self.topLabel.frame;
    topLabelFrame.origin.x = SCREEN_WIDTH/2 - self.topLabel.frame.size.width/2;
    topLabelFrame.origin.y = ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - self.topLabel.frame.size.height/2;
    self.topLabel.frame = topLabelFrame;
    
    self.closeButton.frame = CGRectMake(20,
                                        ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - [UIImage imageNamed:@"btn_x"].size.height/2,
                                        [UIImage imageNamed:@"btn_x"].size.width,
                                        [UIImage imageNamed:@"btn_x"].size.height);
    
    //- Adjust the size of the button to have a larger tap area
    self.closeButton.frame = CGRectMake(self.closeButton.frame.origin.x -10,
                                        self.closeButton.frame.origin.y -10,
                                        self.closeButton.frame.size.width + 20,
                                        self.closeButton.frame.size.height + 20);
    
    NSError *error = nil;
    self.namePattern = [NSRegularExpression regularExpressionWithPattern:@"\\w+"
                                                                 options:0
                                                                   error:&error];

    self.topLabel.font = [TDConstants fontSemiBoldSized:18];
    self.topLabel.textColor = [TDConstants headerTextColor];
    
    self.friendsLabel.font = [TDConstants fontRegularSized:14];
    self.friendsLabel.textColor = [TDConstants headerTextColor];
    [self.friendsLabel sizeToFit];
    CGRect friendsLabelFrame = self.friendsLabel.frame;
    friendsLabelFrame.origin.x = SCREEN_WIDTH/2 - self.friendsLabel.frame.size.width/2;
    friendsLabelFrame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height +50;
    self.friendsLabel.frame = friendsLabelFrame;
    
    // Textfields
    [self.phoneNumberTextField setUpWithIconImageNamed:@"icon_phone"
                                           placeHolder:@"Phone Number"
                                          keyboardType:UIKeyboardTypePhonePad
                                                  type:kTDTextFieldType_Phone
                                              delegate:self];
    [self.emailTextField setUpWithIconImageNamed:@"icon_email"
                                     placeHolder:@"Email Address"
                                    keyboardType:UIKeyboardTypeEmailAddress
                                            type:kTDTextFieldType_Email
                                        delegate:self];
    [self.firstLastNameTextField setUpWithIconImageNamed:@"icon_name"
                                             placeHolder:@"First and Last Name"
                                            keyboardType:UIKeyboardTypeNamePhonePad
                                                    type:kTDTextFieldType_FirstLast
                                                delegate:self];
    
    CGRect firstNameFrame = self.firstLastNameTextField.frame;
    firstNameFrame.origin.x = 20;
    firstNameFrame.origin.y = self.friendsLabel.frame.origin.y + self.friendsLabel.frame.size.height + 10;
    firstNameFrame.size.width = SCREEN_WIDTH - 40;
    self.firstLastNameTextField.frame = firstNameFrame;
    
    CGRect phoneFrame = self.phoneNumberTextField.frame;
    phoneFrame.origin.x = 20;
    phoneFrame.origin.y = self.firstLastNameTextField.frame.origin.y + self.firstLastNameTextField.frame.size.height;
    phoneFrame.size.width = SCREEN_WIDTH - 40;
    self.phoneNumberTextField.frame = phoneFrame;
    
    CGRect emailFrame = self.emailTextField.frame;
    emailFrame.origin.x = 20;
    emailFrame.origin.y = self.phoneNumberTextField.frame.origin.y + self.phoneNumberTextField.frame.size.height;
    emailFrame.size.width = SCREEN_WIDTH - 40;
    self.emailTextField.frame = emailFrame;
    
    self.continueButton.frame = CGRectMake(
                                           SCREEN_WIDTH/2 - [UIImage imageNamed:@"btn_continue"].size.width/2,
                                           self.emailTextField.frame.origin.y + self.emailTextField.frame.size.height + 20,
                                           [UIImage imageNamed:@"btn_continue"].size.width,
                                           [UIImage imageNamed:@"btn_continue"].size.height);
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
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

- (IBAction)closeButtonPressed:(UIButton *)sender {

    [self.emailTextField resignFirst];

    [self.firstLastNameTextField resignFirst];

    [self.phoneNumberTextField resignFirst];
    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    //transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromBottom;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)continueButtonPressed:(id)sender {
    if ([self validateAllFields]) {
        [self transitionToStepTwoController];
    }
}

# pragma mark - navigation

- (void)transitionToStepTwoController {
    TDSignupStepTwoViewController *controller = [[TDSignupStepTwoViewController alloc] init];
    [controller userParameters:[self userParameters]] ;
    
    UIViewController *srcViewController = (UIViewController *) self;
    UIViewController *destViewController = (UIViewController *) controller;
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [srcViewController.view.window.layer addAnimation:transition forKey:nil];
    
    [srcViewController presentViewController:destViewController animated:NO completion:nil];
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
    self.continueButton.enabled = valid;
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
    debug NSLog(@"parameters=%@", [self userParameters]);
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
