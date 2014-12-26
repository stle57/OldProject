//
//  TDResetPasswordViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/29/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDResetPasswordViewController.h"
#import "TDViewControllerHelper.h"
#import "TDUserAPI.h"
#import "NBPhoneNumberUtil.h"
#import "TDConstants.h"
#import "TDAppDelegate.h"

@interface TDResetPasswordViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic, copy) NSString *emailOrPhoneNumber;

- (IBAction)backButtonPressed:(UIButton *)sender;
@end

@implementation TDResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.topLabel.font = [TDConstants fontSemiBoldSized:18];
    self.topLabel.textColor = [TDConstants headerTextColor];

    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    //UINavigationBar *navigationBar = self.navigationController.navigationBar;
    //    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    //    [navigationBar setBarStyle:UIBarStyleBlack];
//    navigationBar.translucent = NO;
//    
//    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];     // 'X'
//    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    self.backButton.frame = CGRectMake(20, [UIApplication sharedApplication].statusBarFrame.size.height, [UIImage imageNamed:@"btn_x"].size.width, [UIImage imageNamed:@"btn_x"].size.height);
    
    self.topLabel.text = @"Reset Password";
    self.topLabel.font = [TDConstants fontSemiBoldSized:18];
    self.topLabel.textColor = [TDConstants
                               headerTextColor];
    [self.topLabel sizeToFit];
    CGRect topLabelFrame = self.topLabel.frame;
    topLabelFrame.origin.x = SCREEN_WIDTH/2 - self.topLabel.frame.size.width/2;
    topLabelFrame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
    self.topLabel.frame = topLabelFrame;
    
    [self.backgroundImageView setBackgroundImage];
    [self.backgroundImageView applyBlurOnImage];
    debug NSLog(@"self.backgroundImageView.frame = %@", NSStringFromCGRect(self.backgroundImageView.frame));
    // Textfields
    
    self.alphaView.frame = self.view.frame;
    self.alphaView.backgroundColor = [UIColor whiteColor];
    [self.alphaView setAlpha:.92];
    
    [self.userNameTextField setUpWithIconImageNamed:@"icon_email"
                                        placeHolder:@"Email Address"//@"Email or Phone Number"
                                       keyboardType:UIKeyboardTypeEmailAddress
                                               type:kTDTextFieldType_UsernameOrPhoneNumber
                                           delegate:self];
    self.userNameTextField.frame = CGRectMake(20, 50 + [UIApplication sharedApplication].statusBarFrame.size.height, SCREEN_WIDTH-40, 44);

    self.userNameTextField.textfield.font = [TDConstants fontRegularSized:16];
    self.userNameTextField.textfield.textColor = [TDConstants headerTextColor];
    
    self.resetButton.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"btn_reset_password" ].size.width/2, self.userNameTextField.frame.origin.y + self.userNameTextField.frame.size.height + 40, [UIImage imageNamed:@"btn_reset_password"].size.width, [UIImage imageNamed:@"btn_reset_password"].size.height);
    

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.userNameTextField becomeFirstResponder];
}

- (void)dealloc {
    self.emailOrPhoneNumber = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - TDTextField delegates
-(void)textFieldDidChange:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_UsernameOrPhoneNumber:
            self.emailOrPhoneNumber = textField.text;
        break;
        default:
        break;
    }

    if ([self validateEmailField]) {
        self.resetButton.enabled = YES;
    } else {
        self.resetButton.enabled = NO;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField type:(kTDTextFieldType)type
{
    switch (type) {
        case kTDTextFieldType_UsernameOrPhoneNumber:
            self.emailOrPhoneNumber = textField.text;
        break;
        default:
        break;
    }

    if ([self validateEmailField]) {
        self.resetButton.enabled = YES;
    } else {
        self.resetButton.enabled = NO;
    }

    return NO;
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)resetButtonPressed:(id)sender {

    // Resign
    [self.userNameTextField resignFirst];

    self.backButton.enabled = NO;
    self.resetButton.hidden = YES;
    self.resetButton.enabled = NO;

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
                             [[TDUserAPI sharedInstance] resetPassword:self.emailOrPhoneNumber callback:^(BOOL success, NSDictionary *dict) {

                                 if (success) {
                                     [TDViewControllerHelper showAlertMessage:@"Check your email for a link to reset your password." withTitle:nil];
                                     [self showWelcomeController];
                                 } else {
                                     [TDViewControllerHelper showAlertMessage:@"No account found with that email.\nPlease try again." withTitle:nil];
                                     self.resetButton.enabled = YES;
                                     self.resetButton.hidden = NO;
                                     self.backButton.enabled = YES;
                                     [self.progress stopAnimating];
                                     [self.userNameTextField becomeFirstResponder];
                                 }
                             }];
                         }
                     }];
}

- (BOOL)validatePhoneField {

    NSError *error = nil;
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NBPhoneNumber *parsedPhoneNumber = [phoneUtil parseWithPhoneCarrierRegion:self.emailOrPhoneNumber error:&error];
    if (!error && [phoneUtil isValidNumber:parsedPhoneNumber]) {
        self.emailOrPhoneNumber = [phoneUtil format:parsedPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)validateEmailField {
    if ([TDViewControllerHelper validateEmail:self.emailOrPhoneNumber]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)showWelcomeController {
    [self dismissViewControllerAnimated:NO completion:nil];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *welcomeViewController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];
    
    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = welcomeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}
@end
