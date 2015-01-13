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
#import "UIImage+BlurredFrame.h"

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
@property (weak, nonatomic) IBOutlet TDAppCoverBackgroundView *blurredBackgroundImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *blurredImageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *blurredImageHeightConstraint;
@property (nonatomic) int pageWidth;
@property (nonatomic) int currentPage;
@property (nonatomic) CGFloat oldXOffset;
@end

@implementation TDWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Move slides to the right
    CGRect frame = [[UIScreen mainScreen] bounds];
    CGFloat width = frame.size.width;
    
    CGRect frame1 = self.view.frame;
    frame1.size.height = frame.size.height +  [UIApplication sharedApplication].statusBarFrame.size.height;
    self.view.frame = frame1;
    
    self.scrollView.frame = self.view.frame;
    
    self.pageWidth = width + 20;
    self.currentPage = 0;

    [self.backgroundImage setBackgroundImage:NO];
    [self.blurredBackgroundImage setBackgroundImage:YES];
    
    self.blurredBackgroundImage.layer.borderWidth = 3.0;
    self.blurredBackgroundImage.layer.borderColor = [[UIColor blueColor] CGColor];
    
    self.backgroundImage.layer.borderColor = [[UIColor magentaColor] CGColor];
    self.backgroundImage.layer.borderWidth = 1.;
    
    self.backgroundImage.frame = self.view.frame;
    self.blurredBackgroundImage.frame = self.view.frame;
    
    CGFloat imageWidth = self.backgroundImageWidthConstraint.constant;
    CGFloat imageHeight = self.backgroundImageHeightConstraint.constant;
    CGFloat aspect = [UIScreen mainScreen].bounds.size.height / imageHeight;

    self.backgroundImageWidthConstraint.constant  = (imageWidth * aspect);
    self.backgroundImageHeightConstraint.constant = (imageHeight * aspect);
    self.blurredImageWidthConstraint.constant = (imageWidth * aspect);
    self.blurredImageHeightConstraint.constant = (imageHeight * aspect);
    
    CGFloat totalWidth = self.editViewOnly ? (self.pageWidth *3) + 40 : (self.pageWidth * 4) + 40;
    self.scrollView.contentSize = CGSizeMake(totalWidth, 1);
    self.scrollView.delegate = self;
    
    
    // Intro slide
    self.titleLabel.font = [UIFont fontWithName:@"BebasNeueRegular" size:68.0];
    self.snippetLabel.font = [TDConstants fontSemiBoldSized:20];

    self.backgroundImageHeightConstraint.constant = frame.size.height;
    self.backgroundImageWidthConstraint.constant = frame.size.width;
    self.blurredImageHeightConstraint.constant = frame.size.height;
    self.blurredImageWidthConstraint.constant = frame.size.width;
    self.blurredBackgroundImage.alpha = 0;

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
    
    self.oldXOffset = 1;
}

-(void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.scrollView.contentOffset = CGPointZero;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int offset = (int)scrollView.contentOffset.x;
    debug NSLog(@"offset = %d", offset);
    int page = offset / (self.pageWidth - 20);

    if (offset > self.interestsViewController.view.frame.origin.x) {
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.scrollEnabled = YES;
    }
//    
//    if (self.oldXOffset > offset) {
//        CGFloat blurredAlpha = (offset/395.);
//        CGFloat backgroundAlpha = 1.- (offset/395.);
//        debug NSLog(@"setting alpha for background image = %f", backgroundAlpha);
//        debug NSLog(@"setting alpha for blurred image = %f", blurredAlpha);
//
//        self.blurredBackgroundImage.alpha = blurredAlpha;
//        self.backgroundImage.alpha = backgroundAlpha;
//
//    }
//    if (page == 0) {
//        CGRect frame = CGRectMake((self.pageWidth - 20) - scrollView.contentOffset.x , 0, (self.pageWidth - 20) - scrollView.contentOffset.x , self.backgroundImage.frame.size.height);
//        debug NSLog(@"blur the frame=%@", NSStringFromCGRect(frame));
//        [self.backgroundImage applyBlurOnImage1:frame];
//    } else {
//        
//    }
    
    if(scrollView.contentOffset.x >= 0 && scrollView.contentOffset.x <= 375.0) {
        //self.backgroundImage.alpha = 0;
//        [self.blurredBackgroundImage blurImage:scrollView.contentOffset.x];
        float percent = (scrollView.contentOffset.x / 395.0);
        debug NSLog(@"alpa for blurred image = %f", percent);
        self.blurredBackgroundImage.alpha = percent;
        
    } else if (scrollView.contentOffset.x > 375.0){
        self.blurredBackgroundImage.alpha = 1;
    } else if (scrollView.contentOffset.x < 0) {
        self.blurredBackgroundImage.alpha = 0;
    }
    
    if (page > 0 && self.currentPage != page) {
        // Blur the image only once, when we are transitioning from page 0 to 1
        if (self.currentPage == 0) {
   
        }
        self.currentPage = page;
    } else if (page == 0 && !self.editViewOnly){
        self.currentPage = 0;
    }
    
    self.oldXOffset = offset;
}


# pragma mark - navigation

- (void)showHomeController {
    [self dismissViewControllerAnimated:NO completion:nil];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];
    
    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = homeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - TDGuestViewController {
- (void)showGuestController {
    debug NSLog(@"inside show guest controller");
    [self dismissViewControllerAnimated:YES completion:nil];
    debug NSLog(@"dismissing the welcomeview controller?");
    if (self.navigationController.viewControllers.count ==2) {
        TDGuestUserProfileViewController *viewController = self.navigationController.viewControllers[1];
        [self.navigationController popToViewController:viewController animated:NO];
    } else {
        UIViewController *guestViewController = [[TDGuestUserProfileViewController alloc] initWithNibName:@"TDGuestUserProfileViewController" bundle:nil];
        debug NSLog(@"going to show guestViewController with address = [%p]", &guestViewController);
        debug NSLog(@"before navigation controllers = %lu", (unsigned long)self.navigationController.viewControllers.count);
        [self.navigationController pushViewController:guestViewController animated:YES];
        debug NSLog(@"done launching new guest view controller");
        debug NSLog(@"after navigation controllers = %lu", (unsigned long)self.navigationController.viewControllers.count);
    }

}

#pragma mark - GetStartedViewControllerDelegate
- (void) loginButtonPressed {
    TDLoginViewController *loginController = [[TDLoginViewController alloc] init];
    CATransition *transition = [CATransition animation];
    transition.duration = 0.45;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    transition.type = kCATransitionFromRight;
    [transition setType:kCATransitionPush];
    transition.subtype = kCATransitionFromRight;
    transition.delegate = self;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController pushViewController:loginController animated:NO];
    
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
    [self dismissViewControllerAnimated:YES completion:nil];

    [TDViewControllerHelper navigateToGuestFrom:self];
}

- (void)loadHomeView {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [TDViewControllerHelper navigateToHomeFrom:self];
}
@end
