//
//  TDSignupStepTwoViewController.m
//  Throwdown
//
//  Created by Andrew C on 2/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSignupStepTwoViewController.h"
#import "TDSignupStepThreeViewController.h"
#import "TDViewControllerHelper.h"
#import "TDAPIClient.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>

@interface TDSignupStepTwoViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (copy, nonatomic) NSDictionary *userParameters;
@property (strong, nonatomic) NSRegularExpression *usernamePattern;
@property (strong, nonatomic) NSString *validatingUsername;

@end

@implementation TDSignupStepTwoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *button = [TDViewControllerHelper navBackButton];
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    self.usernameField.layer.cornerRadius = 4.0f;
    self.usernameField.layer.borderWidth = 1.0f;
    self.usernameField.clipsToBounds = YES;
    self.usernameField.delegate = self;
    [self.usernameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    // button is hidden to start
    self.nextButton.layer.cornerRadius = 4;
    self.nextButton.clipsToBounds = YES;

    NSError *error = nil;
    self.usernamePattern = [NSRegularExpression regularExpressionWithPattern:@"[^\\w+\\d++_]"
                                                                 options:0
                                                                   error:&error];

    NSMutableString *username = [[self.userParameters objectForKey:@"name"] mutableCopy];
    [self.usernamePattern replaceMatchesInString:username options:0 range:NSMakeRange(0, [username length]) withTemplate:@""];
    self.usernameField.text = username;
    [self validateUsernameField];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.usernameField becomeFirstResponder];
}

- (void)dealloc
{
    [self.usernameField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)backButtonPressed
{
    // TODO: confirm navigating back if fields are edited.
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)transitionToStepThreeController
{
    [self performSegueWithIdentifier:@"signupStepThree" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"signupStepThree"]) {
        TDSignupStepThreeViewController *vc = [segue destinationViewController];
        NSMutableDictionary *parameters = [self.userParameters mutableCopy];
        [parameters addEntriesFromDictionary:@{@"username": self.usernameField.text}];
        [vc userParameters:parameters];
    }
}

- (void)userParameters:(NSDictionary *)parameters
{
    self.userParameters = parameters;
}

- (IBAction)nextButtonPressed:(id)sender {
    [self transitionToStepThreeController];
}

- (void)textFieldDidChange:(UITextField *)textField
{
    [self validateUsernameField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self validateUsernameField];
}

- (void)validateUsernameField
{
    NSString *username = self.usernameField.text;
    NSRange match = [self.usernamePattern rangeOfFirstMatchInString:username
                                                        options:0
                                                          range:NSMakeRange(0, [username length])];

    if (match.location == NSNotFound && ![username isEqualToString:self.validatingUsername]) {
        self.validatingUsername = username;
        [[TDAPIClient sharedInstance] validateCredentials:@{@"username": username} callback:^(BOOL valid) {
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
        self.nextButton.hidden = NO;
        self.usernameField.layer.borderColor = [[UIColor blackColor] CGColor];
    } else {
        self.nextButton.hidden = YES;
        self.usernameField.layer.borderColor = [[TDConstants brandingRedColor] CGColor];
    }
}


@end
