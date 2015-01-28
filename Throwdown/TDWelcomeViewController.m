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
#import "TDViewControllerHelper.h"
#import "TDHomeViewController.h"
#import "UIImage+BlurredFrame.h"
#import "TDGuestUser.h"

@interface TDWelcomeViewController () <UIScrollViewDelegate, TDGetStartedViewControllerDelegate, TDGoalsViewControllerDelegate, TDInterestsViewControllerDelegate, TDLoadingViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
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
@property (nonatomic) NSMutableArray *goalsList;
@property (nonatomic) NSMutableArray *interestList;
@end

@implementation TDWelcomeViewController

- (void)dealloc {
    self.goalsList = nil;
    self.interestList = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    BOOL guestUserEdit = NO;

    self.view.backgroundColor = [UIColor clearColor];
    
    // Move slides to the right
    CGRect frame = [[UIScreen mainScreen] bounds];
    CGFloat width = frame.size.width;
    
    CGRect frame1 = self.view.frame;
    frame1.size.height = frame.size.height +  [UIApplication sharedApplication].statusBarFrame.size.height;
    self.view.frame = frame1;
    
    self.scrollView.frame = self.view.frame;
    
    self.pageWidth = width + 20;
    self.currentPage = 0;
    [self.backgroundImage setBackgroundImage:NO editingViewOnly:self.editViewOnly];
    [self.blurredBackgroundImage setBackgroundImage:YES editingViewOnly:self.editViewOnly];
    
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

    self.backgroundImageHeightConstraint.constant = frame.size.height;
    self.backgroundImageWidthConstraint.constant = frame.size.width;
    self.blurredImageHeightConstraint.constant = frame.size.height;
    self.blurredImageWidthConstraint.constant = frame.size.width;

    if ([[TDCurrentUser sharedInstance] isLoggedIn] && self.editViewOnly) {
        // We are a logged in user and editing.
        [[TDUserAPI sharedInstance] getGoalsAndInterests:^(NSDictionary *dict) {
            if ([dict objectForKey:@"goals"]) {
                self.goalsList = [dict objectForKey:@"goals"];
                if (self.goalsViewController) {
                    self.goalsViewController.goalList = [self.goalsList mutableCopy];
                    [self.goalsViewController.tableView reloadData];
                }
            }
            if([dict objectForKey:@"interests"]) {
                self.interestList = [dict objectForKey:@"interests"];
                if (self.interestsViewController) {
                    self.interestsViewController.interestList = [self.interestList mutableCopy];
                    [self.interestsViewController.tableView reloadData];
                }
            }
        }];
    } else if (self.editViewOnly) {
        // We are guest user, but editing
        guestUserEdit = YES;
    }else {
        // Start from initial view.
        self.getStartedViewController = [[TDGetStartedViewController alloc] initWithNibName:@"TDGetStartedViewController" bundle:nil ];
        self.getStartedViewController.delegate = self;
        [self addChildViewController:self.getStartedViewController];
        [self.scrollView addSubview:self.getStartedViewController.view];

        CGRect getStartedFrame = self.getStartedViewController.view.frame;
        getStartedFrame.origin.x = 0;
        self.getStartedViewController.view.frame = getStartedFrame;
    }

    self.goalsViewController = [[TDGoalsViewController alloc] initWithNibName:@"TDGoalsViewController" bundle:nil withCloseButton:self.editViewOnly goalsList:guestUserEdit ? [TDGuestUser sharedInstance].goalsList : self.goalsList];
    self.goalsViewController.delegate = self;
    [self addChildViewController:self.goalsViewController];
    [self.scrollView addSubview:self.goalsViewController.view];
    CGRect goalsFrame = self.goalsViewController.view.frame;
    goalsFrame.origin.x = self.editViewOnly ? 0 : self.pageWidth ;
    self.goalsViewController.view.frame = goalsFrame;

    self.interestsViewController =[[TDInterestsViewController alloc] initWithNibName:@"TDInterestsViewController" bundle:nil withBackButton:self.editViewOnly interestsList:guestUserEdit ? [TDGuestUser sharedInstance].interestsList : self.interestList];
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
    
    self.backgroundImage.alpha = 1.f;
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
    int page = offset / (self.pageWidth - 20);

    if (offset > self.interestsViewController.view.frame.origin.x) {
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.scrollEnabled = YES;
    }
    
    if (!self.editViewOnly) {
        CGFloat value = (self.scrollView.contentOffset.x - (self.pageWidth/2))/(self.pageWidth/2);

        if (value > 0 || value <= 1) {
            [self setBlurLevel: value];
        }
    }
    
    if (page > 0 && self.currentPage != page) {
        // Blur the image only once, when we are transitioning from page 0 to 1
        if (self.currentPage == 0) {
//            self.backgroundImage.alpha = 1;
//            self.blurredBackgroundImage.alpha = 0;
        }
        self.currentPage = page;
    } else if (page == 0 && !self.editViewOnly){
        self.currentPage = 0;
    }
}

- (void)setBlurLevel:(float)blurLevel {
    self.blurredBackgroundImage.alpha = blurLevel;
    
    self.goalsViewController.view.alpha = blurLevel;
    
    self.goalsViewController.closeButtonBackgroundView.alpha = blurLevel;
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
- (void)showGuestController:(NSDictionary*)guestPosts {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.navigationController.viewControllers.count ==2) {
        TDGuestUserProfileViewController *viewController = self.navigationController.viewControllers[1];
        [viewController refreshPosts:guestPosts];

        [self.navigationController popToViewController:viewController animated:NO];
    } else {
        TDGuestUserProfileViewController *guestViewController = [[TDGuestUserProfileViewController alloc] initWithNibName:@"TDGuestUserProfileViewController" bundle:nil goalsList:self.goalsList interestsLists:self.interestList guestPosts:guestPosts];

        [self.navigationController pushViewController:guestViewController animated:YES];
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
    CGRect frame2 = self.goalsViewController.view.frame;
    [self.scrollView scrollRectToVisible:frame2 animated:YES];
}

#pragma mark - GoalsViewControllerDelegate 
- (void)continueButtonPressed:(NSMutableArray *)goalsList {
    self.goalsList = [goalsList copy];
    CGRect frame2 = self.interestsViewController.view.frame;
    [self.scrollView scrollRectToVisible:frame2 animated:YES];
}

- (void)closeButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - InterestsViewControllerDelgate
- (void)doneButtonPressed:(NSMutableArray *)interestList {
    self.interestList = [interestList copy];
    CGRect frame = self.loadingViewController.view.frame;
    frame.origin.x +=20;
    [self.scrollView scrollRectToVisible:frame animated:YES];

    if (self.editViewOnly && [[TDCurrentUser sharedInstance] isLoggedIn]) {
        [self.loadingViewController showData:self.goalsList interestList:self.interestList];
    } else {
        [[TDGuestUser sharedInstance] updateGuestInfo:self.goalsList interestsList:self.interestList];
        [self.loadingViewController showData:self.goalsList interestList:self.interestList];
    }
}

- (void)backButtonPressed {
    int offset = (int)self.scrollView.contentOffset.x;
    CGRect frame = self.interestsViewController.view.frame;
    frame.origin.x = offset - self.pageWidth;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}

- (void)loadGuestView:(NSDictionary *)guestPosts {

    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransition;
    transition.subtype = kCATransitionFromBottom;
    [self.view.window.layer addAnimation:transition forKey:nil];

    [self dismissViewControllerAnimated:YES completion:nil];
    [TDViewControllerHelper navigateToGuestFrom:self guestPosts:guestPosts];
}
- (void)loadHomeView {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [TDViewControllerHelper navigateToHomeFrom:self];
}

- (void)loadInterestsView {
    [self backButtonPressed];
}
@end
