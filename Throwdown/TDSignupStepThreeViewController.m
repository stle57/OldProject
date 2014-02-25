//
//  TDSignupStepThreeViewController.m
//  Throwdown
//
//  Created by Andrew C on 2/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSignupStepThreeViewController.h"
#import "TDWelcomeViewController.h"
#import "TDViewControllerHelper.h"
#import "TDAPIClient.h"
#import "TDUserAPI.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>

@interface TDSignupStepThreeViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (copy, nonatomic) NSDictionary *userParameters;
@property (strong, nonatomic) NSString *validatingEmail;

@end

@implementation TDSignupStepThreeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *button = [TDViewControllerHelper navBackButton];
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    self.emailField.layer.cornerRadius = 4.0f;
    self.emailField.layer.borderWidth = 1.0f;
    self.emailField.clipsToBounds = YES;
    self.emailField.delegate = self;
    [self.emailField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    // button is hidden to start
    self.signupButton.layer.cornerRadius = 4;
    self.signupButton.clipsToBounds = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.emailField becomeFirstResponder];
}

- (void)dealloc
{
    [self.emailField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)backButtonPressed
{
    // TODO: confirm navigating back if fields are edited.
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)signup
{
    NSMutableDictionary *parameters = [self.userParameters mutableCopy];
    [parameters addEntriesFromDictionary:@{@"email": self.emailField.text}];
    self.signupButton.enabled = NO;
    [[TDUserAPI sharedInstance] signupUser:parameters callback:^(BOOL success) {
        if (success) {
            [TDViewControllerHelper navigateToHomeFrom:self];
        } else {
            [TDViewControllerHelper showAlertMessage:@"There was an error, please try again." withTitle:@"Error"];
            self.signupButton.enabled = YES;
        }
    }];
}

- (void)userParameters:(NSDictionary *)parameters
{
    self.userParameters = parameters;
}

- (IBAction)signupButtonPressed:(id)sender {
    [self signup];
}

- (void)textFieldDidChange:(UITextField *)textField
{
    [self validateEmailField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self validateEmailField];
}

- (void)validateEmailField
{
    NSString *email = self.emailField.text;
    if ([TDViewControllerHelper validateEmail:email] && ![email isEqualToString:self.validatingEmail]) {
        self.validatingEmail = email;
        [[TDAPIClient sharedInstance] validateCredentials:@{@"email": email} callback:^(BOOL valid) {
            debug NSLog(@"callback with %hhd", valid);
            [self setStatus:valid];
        }];
    } else {
        [self setStatus:NO];
    }
}

# pragma mark - view helpers

- (void)setStatus:(BOOL)status
{
    if (status) {
        self.signupButton.hidden = NO;
        self.emailField.layer.borderColor = [[UIColor blackColor] CGColor];
    } else {
        self.signupButton.hidden = YES;
        self.emailField.layer.borderColor = [[TDConstants brandingRedColor] CGColor];
    }
}


@end
