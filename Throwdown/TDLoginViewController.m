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

@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation TDLoginViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIButton *button = [TDViewControllerHelper navBackButton];
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    self.loginField.layer.cornerRadius = 4.0f;
    self.loginField.layer.borderWidth = 1.0f;
    self.loginField.clipsToBounds = YES;
    self.loginField.delegate = self;
    [self.loginField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    self.passwordField.layer.cornerRadius = 4.0f;
    self.passwordField.layer.borderWidth = 1.0f;
    self.passwordField.clipsToBounds = YES;
    self.passwordField.delegate = self;
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    // button is hidden to start
    self.loginButton.layer.cornerRadius = 4;
    self.loginButton.clipsToBounds = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.loginField becomeFirstResponder];
}

- (void)dealloc {
    [self.loginField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSString *email = self.loginField.text;
    if ([TDViewControllerHelper validateEmail:email] && [self.passwordField.text length] > 5) {
        self.loginButton.hidden = NO;
    } else {
        self.loginButton.hidden = YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self textFieldDidChange:textField];
}

- (void)backButtonPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)loginButtonPressed:(id)sender {
    self.loginButton.enabled = NO;
    [[TDUserAPI sharedInstance] loginUser:self.loginField.text withPassword:self.passwordField.text callback:^(BOOL success) {
        if (success) {
            [TDViewControllerHelper navigateToHomeFrom:self];
        } else {
            [TDViewControllerHelper showAlertMessage:@"Email or password is wrong, try again." withTitle:nil];
            self.loginButton.enabled = YES;
        }
    }];
}

@end
