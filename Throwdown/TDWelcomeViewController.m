//
//  TDWelcomeViewController.m
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDWelcomeViewController.h"
#import "TDAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@interface TDWelcomeViewController ()
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation TDWelcomeViewController

- (void)viewWillAppear:(BOOL)animated
{
//    [self.navigationController setNavigationBarHidden:YES animated:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.navigationController setNavigationBarHidden:NO animated:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
/*    self.signupButton.layer.cornerRadius = 4;
    self.signupButton.clipsToBounds = YES;
    self.loginButton.layer.cornerRadius = 4;
    self.loginButton.clipsToBounds = YES; */

    // Position title and snippet and 2 buttons
    self.titleLabel.font = [UIFont fontWithName:@"BebasNeueRegular" size:62.0];
    [TDAppDelegate fixHeightOfThisLabel:self.titleLabel];
    CGRect textFrame = self.titleLabel.frame;
    textFrame.origin.y = 50.0;
    self.titleLabel.frame = textFrame;
    self.snippetLabel.text = @"A community that\ncelebrates fitness";
    self.snippetLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:24.0];
    [TDAppDelegate fixHeightOfThisLabel:self.snippetLabel];
    textFrame = self.snippetLabel.frame;
    textFrame.origin.y = CGRectGetMaxY(self.titleLabel.frame)+30.0;
    self.snippetLabel.frame = textFrame;
    CGRect buttonFrame = self.signupButton.frame;
    buttonFrame.origin.y = CGRectGetMaxY(self.snippetLabel.frame)+120.0;
    self.signupButton.frame = buttonFrame;
    buttonFrame = self.loginButton.frame;
    buttonFrame.origin.y = CGRectGetMaxY(self.signupButton.frame)+10.0;
    self.loginButton.frame = buttonFrame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

# pragma mark - navigation

- (void)showHomeController
{
    [self dismissViewControllerAnimated:NO completion:nil];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];

    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = homeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end
