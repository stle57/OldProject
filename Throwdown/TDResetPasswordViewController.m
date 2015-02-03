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
@property (nonatomic) BOOL keyboardUp;
- (IBAction)backButtonPressed:(UIButton *)sender;
@end

@implementation TDResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.topLabel.font = [TDConstants fontSemiBoldSized:18];
    self.topLabel.textColor = [TDConstants headerTextColor];

    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

    self.backButton.frame = CGRectMake(20,
                                       ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - [UIImage imageNamed:@"btn_back"].size.height/2,
                                       [UIImage imageNamed:@"btn_back"].size.width,
                                       [UIImage imageNamed:@"btn_back"].size.height);
    //- Adjust the size of the button to have a larger tap area
    self.backButton.frame = CGRectMake(self.backButton.frame.origin.x -10,
                                       self.backButton.frame.origin.y -10,
                                       self.backButton.frame.size.width + 20,
                                       self.backButton.frame.size.height + 20);
    
    self.topLabel.text = @"Reset Password";
    self.topLabel.font = [TDConstants fontSemiBoldSized:18];
    self.topLabel.textColor = [TDConstants
                               headerTextColor];
    [self.topLabel sizeToFit];
    CGRect topLabelFrame = self.topLabel.frame;
    topLabelFrame.origin.x = SCREEN_WIDTH/2 - self.topLabel.frame.size.width/2;
    topLabelFrame.origin.y = ([UIApplication sharedApplication].statusBarFrame.size.height +50)/2 - self.topLabel.frame.size.height/2;
    self.topLabel.frame = topLabelFrame;
    
    [self.backgroundImageView setBackgroundImage:YES editingViewOnly:YES];
    // Textfields
    
    self.alphaView.frame = self.view.frame;
    self.alphaView.backgroundColor = [UIColor clearColor];
    
    [self.userNameTextField setUpWithIconImageNamed:@"icon_email"
                                        placeHolder:@"Email Address"//@"Email or Phone Number"
                                       keyboardType:UIKeyboardTypeEmailAddress
                                               type:kTDTextFieldType_UsernameOrPhoneNumber
                                           delegate:self];
    self.userNameTextField.frame =
    CGRectMake(20,
               50 + [UIApplication sharedApplication].statusBarFrame.size.height,
               SCREEN_WIDTH-40,
               44);

    self.userNameTextField.textfield.font = [TDConstants fontRegularSized:16];
    self.userNameTextField.textfield.textColor = [TDConstants headerTextColor];
    
    self.resetButton.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"btn_reset_password"].size.width/2,
                                        self.userNameTextField.frame.origin.y + self.userNameTextField.frame.size.height + 40,
                                        [UIImage imageNamed:@"btn_reset_password"].size.width,
                                        [UIImage imageNamed:@"btn_reset_password"].size.height);

    self.progress.center = [TDViewControllerHelper centerPosition];

    CGPoint centerFrame = self.progress.center;
    centerFrame.y = self.resetButton.frame.origin.y;
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

- (void)viewDidDisappear:(BOOL)animated {
    [self.userNameTextField resignFirst];
    [super viewDidDisappear:animated];
}
- (void)dealloc {
    self.emailOrPhoneNumber = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - TDTextField delegates
- (void)textFieldDidBeginEditing:(UITextField *)textField type:(kTDTextFieldType)type {
    [self validateEmailField];
    self.keyboardUp = YES;
}

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
    if (self.navigationController.viewControllers.count) {
        [self.navigationController popViewControllerAnimated:YES];

    } else {
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromLeft;
        [self.view.window.layer addAnimation:transition forKey:nil];

        [self dismissViewControllerAnimated:NO completion:nil];
    }
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
                                     self.keyboardUp = YES;
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

    [[NSNotificationCenter defaultCenter] postNotificationName:TDDismissLoginViewController object:self];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *welcomeViewController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];
    
    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = welcomeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];

}


- (void)handleSingleTap:(UITapGestureRecognizer *) sender {
    [self.userNameTextField resignFirst];
    self.keyboardUp = NO;
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return self.keyboardUp;
}
@end
