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
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.signupButton.layer.cornerRadius = 4;
    self.signupButton.clipsToBounds = YES;
    self.loginButton.layer.cornerRadius = 4;
    self.loginButton.clipsToBounds = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
