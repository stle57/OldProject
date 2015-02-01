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
#import "TDConstants.h"
#import "TDAnalytics.h"
#import "TDResetPasswordViewController.h"

@interface TDLoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet TDAppCoverBackgroundView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *alphaView;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *resetPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic, copy) NSString *userEmail;
@property (nonatomic, copy) NSString *password;
@property (nonatomic) BOOL useCloseButton;

- (IBAction)loginButtonPressed:(id)sender;

@end

@implementation TDLoginViewController
static NSString *buttonLoginStr = @"btn_login";
static NSString *buttonLoginHitStr = @"btn_login_hit";
static NSString *buttonBackStr = @"btn_back";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withCloseButton:(BOOL)yes {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.useCloseButton = yes;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

    [self.backgroundImageView setBackgroundImage:YES editingViewOnly:YES];
    debug NSLog(@"self.backgroundImageView.frame = %@", NSStringFromCGRect(self.backgroundImageView.frame));
    
    self.alphaView.frame = self.view.frame;
    self.alphaView.backgroundColor = [UIColor clearColor];
    debug NSLog(@"alphaView.frame = %@", NSStringFromCGRect(self.alphaView.frame));

    //NSInteger yPosition = 25-([UIImage imageNamed:buttonBackStr].size.height/2);
    NSInteger yPosition = 25 - [UIApplication sharedApplication].statusBarFrame.size.height;
    debug NSLog(@"yPosition-%ld", (long)yPosition);
    if (self.useCloseButton) {
        [self.backButton setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateNormal];
        [self.backButton setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateSelected];
        [self.backButton setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateHighlighted];

        self.backButton.frame = CGRectMake(20,
                                           ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - [UIImage imageNamed:@"btn_x"].size.height/2,
                                           [UIImage imageNamed:@"btn_x"].size.width,
                                           [UIImage imageNamed:@"btn_x"].size.height);

        [self.backButton addTarget:self action:@selector(closeThisView) forControlEvents:UIControlEventTouchUpInside];

        [self.resetPasswordButton addTarget:self action:@selector(resetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    } else {
        [self.backButton setImage:[UIImage imageNamed:buttonBackStr] forState:UIControlStateNormal];
        [self.backButton setImage:[UIImage imageNamed:buttonBackStr] forState:UIControlStateSelected];
        [self.backButton setImage:[UIImage imageNamed:buttonBackStr] forState:UIControlStateHighlighted];

        self.backButton.frame = CGRectMake(20,
                                           ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - [UIImage imageNamed:buttonBackStr].size.height/2,
                                           [UIImage imageNamed:buttonBackStr].size.width,
                                           [UIImage imageNamed:buttonBackStr].size.height);
        [self.backButton addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];

    }

    //- Adjust the size of the button to have a larger tap area
    self.backButton.frame = CGRectMake(self.backButton.frame.origin.x -10,
                                       self.backButton.frame.origin.y -10,
                                       self.backButton.frame.size.width + 20,
                                       self.backButton.frame.size.height + 20);
    debug NSLog(@"backButton frame = %@", NSStringFromCGRect(self.backButton.frame));
    [[TDAnalytics sharedInstance] logEvent:@"login_opened"];
    self.topLabel.text = @"Log In";
    self.topLabel.font = [TDConstants fontSemiBoldSized:18];
    self.topLabel.textColor = [TDConstants
                               headerTextColor];
    [self.topLabel sizeToFit];
    CGRect topLabelFrame = self.topLabel.frame;
    topLabelFrame.origin.x = SCREEN_WIDTH/2 - self.topLabel.frame.size.width/2;
    topLabelFrame.origin.y = ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - self.topLabel.frame.size.height/2;
    self.topLabel.frame = topLabelFrame;

    debug NSLog(@"self.topLabel.frame = %@", NSStringFromCGRect(self.topLabel.frame));
    [self.resetPasswordButton.titleLabel setFont:[TDConstants fontRegularSized:14]];
    [self.resetPasswordButton setTitleColor:[TDConstants headerTextColor] forState:(UIControlStateNormal)];
    [self.resetPasswordButton sizeToFit];
    
    // Textfields
    [self.userNameTextField setUpWithIconImageNamed:@"icon_name"
                                        placeHolder:@"Username or Email"
                                       keyboardType:UIKeyboardTypeEmailAddress
                                               type:kTDTextFieldType_Email
                                           delegate:self];
    CGRect usernameFrame = self.userNameTextField.frame;
    usernameFrame.origin.x = 20;
    usernameFrame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height + 50;
    usernameFrame.size.width = SCREEN_WIDTH - 40;
    self.userNameTextField.frame = usernameFrame;
    
    debug NSLog(@"icon view=%@", NSStringFromCGRect( self.userNameTextField.iconImageView.frame));
    debug NSLog(@"usernametextfield = %@", NSStringFromCGRect(self.userNameTextField.frame));
    [self.passwordTextField setUpWithIconImageNamed:@"icon_password"
                                        placeHolder:@"Password"
                                       keyboardType:UIKeyboardTypeDefault
                                               type:kTDTextFieldType_Password
                                           delegate:self];
    [self.passwordTextField secure];
    CGRect passwordFrame = self.passwordTextField.frame;
    passwordFrame.origin.x = 20;
    passwordFrame.origin.y =self.userNameTextField.frame.origin.y + self.userNameTextField.frame.size.height;
    passwordFrame.size.width = SCREEN_WIDTH - 40;
    self.passwordTextField.frame = passwordFrame;
    
    self.loginButton.frame =
    CGRectMake(SCREEN_WIDTH/2 -[UIImage imageNamed:buttonLoginStr].size.width/2,
               self.passwordTextField.frame.origin.y + self.passwordTextField.frame.size.height+ 40,
               [UIImage imageNamed:buttonLoginStr].size.width,
               [UIImage imageNamed:buttonLoginStr].size.height);
    debug NSLog(@"button=%@", NSStringFromCGRect(self.loginButton.frame));
    
    self.resetPasswordButton.frame =
        CGRectMake(SCREEN_WIDTH/2 - self.resetPasswordButton.frame.size.width/2,
                   self.passwordTextField.frame.origin.y +self.passwordTextField.frame.size.height+ 40 + [UIImage imageNamed:buttonLoginStr].size.height + 15,
                   self.resetPasswordButton.frame.size.width,
                   self.resetPasswordButton.frame.size.height);

    self.progress.center = [TDViewControllerHelper centerPosition];
    CGPoint centerFrame = self.progress.center;
    centerFrame.y = self.loginButton.frame.origin.y;
    self.progress.center = centerFrame;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.userNameTextField becomeFirstResponder];
}

- (void)dealloc {
    self.userEmail = nil;
    self.password = nil;
   // self.backgroundImageView = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - TDTextField delegates
-(void)textFieldDidChange:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_Email:
        {
            self.userEmail = textField.text;
        }
        break;
        case kTDTextFieldType_Password:
        {
            self.password = textField.text;
        }
        break;
        default:
        break;
    }

    if ([self.userEmail length] > 0 && [self.password length] > 5) {
        self.loginButton.enabled = YES;
    } else {
        self.loginButton.enabled = NO;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_Email:
        {
            self.userEmail = textField.text;
            [self.passwordTextField becomeFirstResponder];
        }
        break;
        case kTDTextFieldType_Password:
        {
            self.password = textField.text;
            [self.userNameTextField becomeFirstResponder];
        }
        break;
        default:
        break;
    }

    if ([self.userEmail length] > 0 && [self.password length] > 5) {
        self.loginButton.enabled = YES;
    } else {
        self.loginButton.enabled = NO;
    }

    return NO;
}

- (void)backButtonPressed {
    [self.userNameTextField resignFirst];
    [self.passwordTextField resignFirst];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)closeThisView {
    [self.userNameTextField resignFirst];
    [self.passwordTextField resignFirst];

    CATransition *transition = [CATransition animation];
    transition.duration = .45;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.subtype = kCATransitionFromTop;
    [self.view.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)loginButtonPressed:(id)sender {

    // Resign
    [self.userNameTextField resignFirst];
    [self.passwordTextField resignFirst];

    self.backButton.enabled = NO;
    self.loginButton.hidden = YES;
    self.loginButton.enabled = NO;
    self.resetPasswordButton.enabled = NO;
    self.resetPasswordButton.hidden = YES;

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
                             [[TDUserAPI sharedInstance] loginUser:self.userEmail withPassword:self.password callback:^(BOOL success) {
                                 if (success) {
                                     [[TDAnalytics sharedInstance] logEvent:@"login_completed"];
                                     [TDViewControllerHelper navigateToHomeFrom:self];
                                     self.resetPasswordButton.enabled = YES;
                                     self.resetPasswordButton.hidden = NO;
                                 } else {
                                     [TDViewControllerHelper showAlertMessage:@"Incorrect login info provided. Please try again." withTitle:nil];
                                     self.loginButton.enabled = YES;
                                     self.loginButton.hidden = NO;
                                     self.resetPasswordButton.enabled = YES;
                                     self.resetPasswordButton.hidden = NO;
                                     self.backButton.enabled = YES;
                                     [self.progress stopAnimating];
                                     [self.userNameTextField becomeFirstResponder];
                                 }
                             }];
                         }
                     }];
}

- (IBAction)resetButtonPressed:(id)sender {
    TDResetPasswordViewController *vc = [[TDResetPasswordViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
@end
