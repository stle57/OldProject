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
@property (nonatomic) BOOL keyboardUp;

- (IBAction)loginButtonPressed:(id)sender;

@end

@implementation TDLoginViewController
static NSString *buttonLoginStr = @"btn_login";
static NSString *buttonLoginHitStr = @"btn_login_hit";
static NSString *buttonBackStr = @"btn_back";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withCloseButton:(BOOL)yes withImage:(UIImage *)withImage{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        self.useCloseButton = yes;
        self.blurredImage = [[UIImage alloc] initWithCGImage:withImage.CGImage];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

    if (self.blurredImage) {
        [self.backgroundImageView setBlurredImage:self.blurredImage editingViewOnly:YES];
    } else {
        [self.backgroundImageView setBackgroundImage:YES editingViewOnly:YES];
    }

    self.alphaView.frame = self.view.frame;
    self.alphaView.backgroundColor = [UIColor clearColor];

    if (self.useCloseButton) {
        [self.backButton setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateNormal];
        [self.backButton setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateSelected];
        [self.backButton setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateHighlighted];

        self.backButton.frame = CGRectMake(20,
                                           ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - [UIImage imageNamed:@"btn_x"].size.height/2,
                                           [UIImage imageNamed:@"btn_x"].size.width,
                                           [UIImage imageNamed:@"btn_x"].size.height);

        [self.backButton addTarget:self action:@selector(closeThisView) forControlEvents:UIControlEventTouchUpInside];

    } else {
        [self.backButton setImage:[UIImage imageNamed:buttonBackStr] forState:UIControlStateNormal];
        [self.backButton setImage:[UIImage imageNamed:buttonBackStr] forState:UIControlStateSelected];
        [self.backButton setImage:[UIImage imageNamed:buttonBackStr] forState:UIControlStateHighlighted];

        self.backButton.frame = CGRectMake(20,
                                           ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - [UIImage imageNamed:buttonBackStr].size.height/2,
                                           [UIImage imageNamed:buttonBackStr].size.width,
                                           [UIImage imageNamed:buttonBackStr].size.height);
        [self.backButton addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//        [self.resetPasswordButton addTarget:self action:@selector(resetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    }


    [self.resetPasswordButton addTarget:self action:@selector(showResetPasswordView) forControlEvents:UIControlEventTouchUpInside];
    //- Adjust the size of the button to have a larger tap area
    self.backButton.frame = CGRectMake(self.backButton.frame.origin.x -10,
                                       self.backButton.frame.origin.y -10,
                                       self.backButton.frame.size.width + 20,
                                       self.backButton.frame.size.height + 20);

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

    self.resetPasswordButton.frame =
        CGRectMake(SCREEN_WIDTH/2 - self.resetPasswordButton.frame.size.width/2,
                   self.passwordTextField.frame.origin.y +self.passwordTextField.frame.size.height+ 40 + [UIImage imageNamed:buttonLoginStr].size.height + 15,
                   self.resetPasswordButton.frame.size.width,
                   self.resetPasswordButton.frame.size.height);

    self.progress.center = [TDViewControllerHelper centerPosition];
    CGPoint centerFrame = self.progress.center;
    centerFrame.y = self.loginButton.frame.origin.y;
    self.progress.center = centerFrame;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeView) name:TDDismissLoginViewController object:nil];

    self.tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.tapper setCancelsTouchesInView:NO];
    self.tapper.delegate = self;
    [self.view addGestureRecognizer:self.tapper];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.userNameTextField becomeFirstResponder];
    self.keyboardUp = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.userNameTextField resignFirst];
    [self.passwordTextField resignFirst];
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    self.userEmail = nil;
    self.password = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - TDTextField delegates
- (void)textFieldDidBeginEditing:(UITextField *)textField type:(kTDTextFieldType)type {
    self.keyboardUp = YES;
}

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
            self.keyboardUp = YES;
        }
        break;
        case kTDTextFieldType_Password:
        {
            self.password = textField.text;
            [self.userNameTextField becomeFirstResponder];
            self.keyboardUp = YES;
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
    self.keyboardUp = NO;

    [self.navigationController popViewControllerAnimated:YES];
}

- (void)closeThisView {
    [self.userNameTextField resignFirst];
    [self.passwordTextField resignFirst];

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
                                     self.keyboardUp = YES;
                                 }
                             }];
                         }
                     }];
}

- (void)showResetPasswordView {
    [self.userNameTextField resignFirst];
    [self.passwordTextField resignFirst];

    TDResetPasswordViewController *controller = [[TDResetPasswordViewController alloc] initWithNibName:@"TDResetPasswordViewController" bundle:nil withImage:self.backgroundImageView.image];

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

- (void)removeView {
    [self dismissViewControllerAnimated:NO completion:nil];
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
