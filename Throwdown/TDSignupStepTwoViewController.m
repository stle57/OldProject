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
#import "TDAnalytics.h"

@interface TDSignupStepTwoViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) NSMutableDictionary *userParameters;
@property (strong, nonatomic) NSRegularExpression *usernamePattern;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *password;
@property (nonatomic) BOOL keyboardUp;

- (IBAction)backButtonPressed:(UIButton *)sender;
@end

@implementation TDSignupStepTwoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withImage:(UIImage*)withImage{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.blurredImage = [[UIImage alloc] initWithCGImage:withImage.CGImage];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [[TDAnalytics sharedInstance] logEvent:@"signup_step_two"];
    
    if (self.blurredImage) {
        [self.backgroundImageView setBlurredImage:self.blurredImage editingViewOnly:YES];
    } else {
        [self.backgroundImageView setBackgroundImage:YES editingViewOnly:YES];
    }

    self.alphaView.frame = self.view.frame;
    self.alphaView.backgroundColor = [UIColor clearColor];
    
    self.topLabel.text = @"Choose a username";
    self.topLabel.font = [TDConstants fontSemiBoldSized:18];
    self.topLabel.textColor = [TDConstants headerTextColor];
    [self.topLabel sizeToFit];
    CGRect topLabelFrame = self.topLabel.frame;
    topLabelFrame.origin.x = SCREEN_WIDTH/2 - self.topLabel.frame.size.width/2;
    topLabelFrame.origin.y = ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - self.topLabel.frame.size.height/2;
    self.topLabel.frame = topLabelFrame;
    
    self.backButton.frame = CGRectMake(20,
                                        ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - [UIImage imageNamed:@"btn_back"].size.height/2,
                                        [UIImage imageNamed:@"btn_back"].size.width,
                                        [UIImage imageNamed:@"btn_back"].size.height);
    
    //- Adjust the size of the button to have a larger tap area
    self.backButton.frame = CGRectMake(self.backButton.frame.origin.x -10,
                                       self.backButton.frame.origin.y -10,
                                       self.backButton.frame.size.width + 20,
                                       self.backButton.frame.size.height + 20);

    NSError *error = nil;
    self.usernamePattern = [NSRegularExpression regularExpressionWithPattern:@"[^\\w+\\d++_]"
                                                                     options:0
                                                                       error:&error];

    [self.userNameTextField textfieldText:self.userName];
    [self validateUsernameField];

    self.topLabel.font = [TDConstants fontSemiBoldSized:18];

    self.privacyLabel1.frame = CGRectMake(0, 0, SCREEN_WIDTH, 100);
    self.privacyButton.frame = CGRectMake(0, 0, SCREEN_WIDTH, 100);

    NSString *text = @"By creating an account, you agree to the";
    NSAttributedString *attStr = [TDViewControllerHelper makeParagraphedTextWithString:text font:[TDConstants fontRegularSized:14] color:[TDConstants headerTextColor] lineHeight:15. lineHeightMultipler:(15./12.)];
    self.privacyLabel1.attributedText = attStr;
    [self.privacyLabel1 setNumberOfLines:0];
    [self.privacyLabel1 sizeToFit];
    
    CGRect privacyFrame = self.privacyLabel1.frame;
    privacyFrame.origin.x = SCREEN_WIDTH/2 - self.privacyLabel1.frame.size.width/2;
    privacyFrame.origin.y = self.passwordTextField.frame.origin.y + self.passwordTextField.frame.size.height + 20;
    self.privacyLabel1.frame = privacyFrame;

    NSString *text2 = @"Terms of Service & Privacy Policy";
    NSAttributedString *attStr2 = [TDViewControllerHelper makeParagraphedTextWithString:text2 font:[TDConstants fontSemiBoldSized:14] color:[TDConstants headerTextColor] lineHeight:15. lineHeightMultipler:15./12.];
    [self.privacyButton setAttributedTitle:attStr2 forState:UIControlStateNormal];
    [self.privacyButton addTarget:self action:@selector(privacyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.privacyButton.titleLabel setNumberOfLines:1];
    [self.privacyButton sizeToFit];

    CGRect privateButton = self.privacyButton.frame;
    privateButton.origin.x = SCREEN_WIDTH/2 - self.privacyButton.frame.size.width/2;
    privateButton.origin.y = self.privacyLabel1.frame.origin.y + self.privacyLabel1.frame.size.height;
    self.privacyButton.frame = privateButton;

    // Textfields
    [self.userNameTextField setUpWithIconImageNamed:@"icon_username"
                                        placeHolder:@"User Name"
                                       keyboardType:UIKeyboardTypeTwitter
                                               type:kTDTextFieldType_UserName
                                           delegate:self];
    [self.passwordTextField setUpWithIconImageNamed:@"icon_password"
                                        placeHolder:@"Password"
                                       keyboardType:UIKeyboardTypeDefault
                                               type:kTDTextFieldType_Password
                                           delegate:self];
    [self.passwordTextField secure];
    
    CGRect nameFrame = self.userNameTextField.frame;
    nameFrame.origin.x = 20;
    nameFrame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height +50;
    nameFrame.size.width = SCREEN_WIDTH - 40;
    nameFrame.size.height = 44;
    self.userNameTextField.frame = nameFrame;
    
    CGRect passwordFrame = self.passwordTextField.frame;
    passwordFrame.origin.x = 20;
    passwordFrame.origin.y = self.userNameTextField.frame.origin.y + self.userNameTextField.frame.size.height;
    passwordFrame.size.width = SCREEN_WIDTH - 40;
    passwordFrame.size.height = 44;
    self.passwordTextField.frame = passwordFrame;

    self.signUpButton.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"btn_finish"].size.width/2,
                                         self.privacyButton.frame.origin.y + self.privacyButton.frame.size.height + 20,
                                         [UIImage imageNamed:@"btn_finish"].size.width,
                                         [UIImage imageNamed:@"btn_finish"].size.height);
    
    self.progress.center = [TDViewControllerHelper centerPosition];
    
    CGPoint centerFrame = self.progress.center;
    centerFrame.y = self.progress.center.y - self.progress.frame.size.height/2;
    self.progress.center = centerFrame;

    self.tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.tapper setCancelsTouchesInView:NO];
    self.tapper.delegate = self;
    [self.view addGestureRecognizer:self.tapper];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.userNameTextField becomeFirstResponder];
    self.keyboardUp = YES;
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
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    //[self.navigationController popViewControllerAnimated:YES];
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
                                     [[TDAnalytics sharedInstance] logEvent:@"signup_completed"];
                                     [[TDCurrentUser sharedInstance] didAskForGoalsInitially:YES];
                                     [[TDCurrentUser sharedInstance] didAskForGoalsFinal:YES];
                                     [TDViewControllerHelper navigateToHomeFrom:self];
                                 } else {
                                     [TDViewControllerHelper showAlertMessage:@"There was an error, please try again." withTitle:@"Error"];
                                     self.signUpButton.enabled = YES;
                                     self.backButton.enabled = YES;
                                     self.progress.hidden = YES;
                                     self.signUpButton.hidden = NO;
                                     [self.userNameTextField becomeFirstResponder];
                                     self.keyboardUp = YES;
                                 }
                             }];
                         }
                     }];
}

- (void)userParameters:(NSDictionary *)parameters {
    debug NSLog(@"param:%@", parameters);

    self.userParameters = [parameters mutableCopy];
    self.userName = [self.userParameters objectForKey:@"username"];
}

#pragma mark - TDTextField delegates
- (void)textFieldDidBeginEditing:(UITextField *)textField type:(kTDTextFieldType)type {
    [self validateAllFields];
    self.keyboardUp = YES;
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
        self.keyboardUp = YES;
        break;

        case kTDTextFieldType_Password:
        [self.userNameTextField becomeFirstResponder];
            self.keyboardUp  = YES;
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
        [self.userParameters addEntriesFromDictionary:@{ @"username":username }];
        [[TDAPIClient sharedInstance] validateCredentials:self.userParameters success:^(NSDictionary *response) {
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

- (void)handleSingleTap:(UITapGestureRecognizer *) sender {
    [self.passwordTextField resignFirst];
    [self.userNameTextField resignFirst];
    self.keyboardUp = NO;
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return self.keyboardUp;
}
@end
