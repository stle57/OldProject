//
//  TDWelcomeViewController.m
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDWelcomeViewController.h"
#import "TDConstants.h"
#import "TDAppDelegate.h"
#import "TDAnalytics.h"
#import <QuartzCore/QuartzCore.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import "TDGetStartedViewController.h"
#import "TDGoalsViewController.h"
#import "TDInterestsViewController.h"
#import "TDLoadingViewController.h"
#import "TDLoginViewController.h"
#import "TDAppCoverBackgroundView.h"
#import "TDGuestUserProfileViewController.h"
#import "TDViewControllerHelper.h"
#import "TDHomeViewController.h"

@interface TDWelcomeViewController () <UIScrollViewDelegate, TDGetStartedViewControllerDelegate, TDGoalsViewControllerDelegate, TDInterestsViewControllerDelegate, TDLoadingViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *indicatorView;
@property (weak, nonatomic) IBOutlet TDAppCoverBackgroundView *backgroundImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundImageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundImageHeightConstraint;
@property (nonatomic, retain) TDGetStartedViewController *getStartedViewController;
@property (nonatomic, retain) TDGoalsViewController *goalsViewController;
@property (nonatomic, retain) TDInterestsViewController *interestsViewController;
@property (nonatomic, retain) TDLoadingViewController *loadingViewController;

@property (nonatomic) int pageWidth;
@property (nonatomic) int currentPage;
@end

@implementation TDWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Move slides to the right
    CGRect frame = [[UIScreen mainScreen] bounds];
    CGFloat height = frame.size.height +  [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat width = frame.size.width;
    
    CGRect frame1 = self.view.frame;
    frame1.size.height = frame.size.height +  [UIApplication sharedApplication].statusBarFrame.size.height;
    self.view.frame = frame1;
    
    self.scrollView.frame = self.view.frame;
    
    self.pageWidth = width + 20;
    self.currentPage = 0;

    [self.backgroundImage setBackgroundImage];
    self.backgroundImage.frame = self.view.frame;
    
    CGFloat imageWidth = self.backgroundImageWidthConstraint.constant;
    CGFloat imageHeight = self.backgroundImageHeightConstraint.constant;
    CGFloat aspect = [UIScreen mainScreen].bounds.size.height / imageHeight;

    self.backgroundImageWidthConstraint.constant  = (imageWidth * aspect);
    self.backgroundImageHeightConstraint.constant = (imageHeight * aspect);
    CGFloat totalWidth = self.editViewOnly ? (self.pageWidth *3) + 40 : (self.pageWidth * 4) + 40;
    self.scrollView.contentSize = CGSizeMake(totalWidth, height);
    self.scrollView.delegate = self;
    
    // Intro slide
    self.titleLabel.font = [UIFont fontWithName:@"BebasNeueRegular" size:68.0];
    self.snippetLabel.font = [TDConstants fontSemiBoldSized:20];

    self.backgroundImageHeightConstraint.constant = frame.size.height;
    self.backgroundImageWidthConstraint.constant = frame.size.width;
    
    //self.scrollView.delaysContentTouches = NO;

    if (!self.editViewOnly) {

        self.getStartedViewController = [[TDGetStartedViewController alloc] initWithNibName:@"TDGetStartedViewController" bundle:nil ];
        self.getStartedViewController.delegate = self;
        [self addChildViewController:self.getStartedViewController];
        [self.scrollView addSubview:self.getStartedViewController.view];
        
        CGRect getStartedFrame = self.getStartedViewController.view.frame;
        getStartedFrame.origin.x = 0;
        self.getStartedViewController.view.frame = getStartedFrame;
    }

    self.goalsViewController = [[TDGoalsViewController alloc] initWithNibName:@"TDGoalsViewController" bundle:nil withCloseButton:self.editViewOnly];
    self.goalsViewController.delegate = self;
    [self addChildViewController:self.goalsViewController];
    [self.scrollView addSubview:self.goalsViewController.view];
    CGRect goalsFrame = self.goalsViewController.view.frame;
    goalsFrame.origin.x = self.editViewOnly ? 0 : self.pageWidth ;
    self.goalsViewController.view.frame = goalsFrame;
    
    self.interestsViewController =[[TDInterestsViewController alloc] initWithNibName:@"TDInterestsViewController" bundle:nil withBackButton:self.editViewOnly];
    self.interestsViewController.delegate = self;
    
    [self addChildViewController:self.interestsViewController];
    [self.scrollView addSubview:self.interestsViewController.view];
    CGRect interestFrame = self.interestsViewController.view.frame;
    interestFrame.origin.x = self.editViewOnly ? self.pageWidth  : self.pageWidth * 2 ;
    self.interestsViewController.view.frame = interestFrame;
    
    self.loadingViewController =[[TDLoadingViewController alloc] initWithNibName:@"TDLoadingViewController" bundle:nil ];
    self.loadingViewController.delegate = self;
    [self addChildViewController:self.loadingViewController];
    [self.scrollView addSubview:self.loadingViewController.view];
    CGRect loadingFrame = self.loadingViewController.view.frame;
    loadingFrame.origin.x = self.editViewOnly ? (2*self.pageWidth) : self.pageWidth * 3;
    self.loadingViewController.view.frame = loadingFrame;

    if (self.editViewOnly) {
        [self.backgroundImage applyBlurOnImage];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.scrollView.contentOffset = CGPointZero;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int offset = (int)scrollView.contentOffset.x;
    int page = offset / (self.pageWidth - 20);

    if (offset > self.interestsViewController.view.frame.origin.x) {
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.scrollEnabled = YES;
    }
    
    if (page > 0 && self.currentPage != page) {
        // Blur the image only once, when we are transitioning from page 0 to 1
        if (self.currentPage == 0) {
            [self.backgroundImage applyBlurOnImage];
        }
        self.currentPage = page;
    } else if (page == 0 && !self.editViewOnly){
        self.currentPage = 0;
        [self.backgroundImage setBackgroundImage];
    }
}


# pragma mark - navigation

- (void)showHomeController {
    [self dismissViewControllerAnimated:NO completion:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];
    
    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = homeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - TDGuestViewController {
- (void)showGuestController {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIViewController *guestViewController = [[TDGuestUserProfileViewController alloc] initWithNibName:@"TDGuestUserProfileViewController" bundle:nil];

    [self.navigationController pushViewController:guestViewController animated:YES];
}

#pragma mark - GetStartedViewControllerDelegate
- (void) loginButtonPressed {
    TDLoginViewController *loginController = [[TDLoginViewController alloc] init];
    UIViewController *srcViewController = (UIViewController *) self;
    UIViewController *destViewController = (UIViewController *) loginController;
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [srcViewController.view.window.layer addAnimation:transition forKey:nil];
    
    [srcViewController presentViewController:destViewController animated:NO completion:nil];
    
}

- (void)getStartedButtonPressed {
    [self.backgroundImage applyBlurOnImage];

    CGRect frame2 = self.goalsViewController.view.frame;
    [self.scrollView scrollRectToVisible:frame2 animated:YES];
}

#pragma mark - GoalsViewControllerDelegate 
- (void)continueButtonPressed {
    CGRect frame2 = self.interestsViewController.view.frame;
    [self.scrollView scrollRectToVisible:frame2 animated:YES];
}

- (void)closeButtonPressed {
    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromBottom;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - InterestsViewControllerDelgate
- (void)doneButtonPressed {
    CGRect frame = self.loadingViewController.view.frame;
    frame.origin.x +=20;
    [self.scrollView scrollRectToVisible:frame animated:YES];
    [self.loadingViewController showData];
}

- (void)backButtonPressed {
    int offset = (int)self.scrollView.contentOffset.x;
    CGRect frame = self.interestsViewController.view.frame;
    frame.origin.x = offset - self.pageWidth;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}

- (void)loadGuestView {
    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromBottom;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [TDViewControllerHelper navigateToGuestFrom:self];
}

- (void)loadHomeView {
    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromBottom;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [TDViewControllerHelper navigateToHomeFrom:self];
}
@end
