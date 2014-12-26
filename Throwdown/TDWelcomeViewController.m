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

@interface TDWelcomeViewController () <UIScrollViewDelegate, TDGetStartedViewControllerDelegate, TDGoalsViewControllerDelegate, TDInterestsViewControllerDelegate>
//@property (weak, nonatomic) IBOutlet UIButton *signupButton;
//@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
//@property (weak, nonatomic) IBOutlet UIView *introSlide;
//@property (weak, nonatomic) IBOutlet UIView *slide1;
//@property (weak, nonatomic) IBOutlet UIView *slide2;
//@property (weak, nonatomic) IBOutlet UIView *slide3;
@property (weak, nonatomic) IBOutlet UIView *indicatorView;
//@property (weak, nonatomic) IBOutlet UIScrollView *backgroundScrollView;
//@property (weak, nonatomic) IBOutlet UIImageView *introBackground;
@property (weak, nonatomic) IBOutlet TDAppCoverBackgroundView *backgroundImage;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slide1constraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slide2constraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slide3constraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *introSlideConstraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundImageConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundImageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundImageHeightConstraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slide3TitleConstraint;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewOneTop;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewTwoTop;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewOneHeight;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewTwoHeight;
//@property (weak, nonatomic) IBOutlet UIImageView *previewOne;
//@property (weak, nonatomic) IBOutlet UIImageView *previewTwo;
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
    CGFloat height = frame.size.height;
    debug NSLog(@"working w/ height=%f", height);
    CGFloat width = frame.size.width;
    debug NSLog(@"working w/ width=%f", width);
    //self.view.frame = CGRectMake(0, 0, width, height);
    self.scrollView.frame = self.view.frame;
    
    self.pageWidth = width + 20;
    debug NSLog(@"pageWidth=%d", self.pageWidth);
    self.currentPage = 0;

    [self.backgroundImage setBackgroundImage];
    CGFloat imageWidth = self.backgroundImageWidthConstraint.constant;
    CGFloat imageHeight = self.backgroundImageHeightConstraint.constant;
    CGFloat totalWidth = (self.pageWidth * 4) + 40;
    debug NSLog(@"totalWidth=%f", totalWidth);
    CGFloat aspect = [UIScreen mainScreen].bounds.size.height / imageHeight;

    self.backgroundImageWidthConstraint.constant  = (imageWidth * aspect);
    debug NSLog(@"width constant=%f", self.backgroundImageWidthConstraint.constant);
    self.backgroundImageHeightConstraint.constant = (imageHeight * aspect);
    debug NSLog(@"height constant = %f", self.backgroundImageHeightConstraint.constant);

    self.scrollView.contentSize = CGSizeMake(totalWidth, height);
    self.scrollView.delegate = self;
    
//    self.introSlideConstraint.constant = 10;
//    self.slide1constraint.constant = self.pageWidth + 10;
//    self.slide2constraint.constant = self.pageWidth * 2 + 10;
//    self.slide3constraint.constant = self.pageWidth * 3 + 10;
//
    // Intro slide
    self.titleLabel.font = [UIFont fontWithName:@"BebasNeueRegular" size:68.0];
    self.snippetLabel.font = [TDConstants fontSemiBoldSized:20];
   // self.loginButton.titleLabel.font = [TDConstants fontSemiBoldSized:14];

    self.backgroundImageHeightConstraint.constant = frame.size.height;
    self.backgroundImageWidthConstraint.constant = frame.size.width;
    
    
    
    // moves all the slide 3 titles up if it's a small screen
//    if (height == 480) {
////        self.slide3TitleConstraint.constant = 20;
////        self.previewOneHeight.constant = 300;
////        self.previewTwoHeight.constant = 300;
////        self.previewOneTop.constant = -10;
////        self.previewTwoTop.constant = -10;
////        self.previewOne.clipsToBounds = YES;
////        self.previewTwo.clipsToBounds = YES;
////        self.backgroundImage.image = [UIImage imageNamed:@"AppCover_iPhone4s"];
////        self.backgroundImage.frame = CGRectMake(0, 0, [UIImage imageNamed:@"AppCover_iPhone4"].size.width, [UIImage imageNamed:@"AppCover_iPhone4"].size.height);
//        
//    } else if (height == 568) {
//        debug NSLog(@"AppCover_iPhone5");
////        self.previewOneTop.constant = 0;
////        self.previewTwoTop.constant = 0;
//        self.backgroundImage.image = [UIImage imageNamed:@"AppCover_iPhone5"];
////        self.backgroundImage.frame = CGRectMake(0, 0, [UIImage imageNamed:@"AppCover_iPhone5"].size.width, [UIImage imageNamed:@"AppCover_iPhone5"].size.height);
////        CGRect frame = self.backgroundImage.frame;
////        frame.size.width =[UIImage imageNamed:@"AppCover_iPhone5"].size.width;
////        frame.size.height = [UIImage imageNamed:@"AppCover_iPhone5"].size.height;
////        self.backgroundImage.frame = frame;
//        self.backgroundImageHeightConstraint.constant = frame.size.height;
//        self.backgroundImageWidthConstraint.constant = frame.size.width;
//
//    } else if (height == 667) {
////        self.backgroundImage.image = [UIImage imageNamed:@"AppCover_iPhone6"];
////        self.backgroundImage.frame = CGRectMake(0, 0, [UIImage imageNamed:@"AppCover_iPhone6"].size.width, [UIImage imageNamed:@"AppCover_iPhone6"].size.height);
//
//        
//    } else if (height == 736) {
////        CGFloat offset = (height / 2) - (self.previewOneHeight.constant + 150) / 2;
////        self.previewOneTop.constant = offset;
////        self.previewTwoTop.constant = offset;
//        self.backgroundImage.image = [UIImage imageNamed:@"AppCover_iPhone6plus"];
//        self.backgroundImage.frame = CGRectMake(0, 0, [UIImage imageNamed:@"AppCover_iPhone6plus"].size.width, [UIImage imageNamed:@"AppCover_iPhone6plus"].size.height);
//
//    }

    //self.backgroundImageConstraint.constant = -100 - (-self.pageWidth) / 4.0;
    
    self.indicatorView.hidden = YES;
    
    CGRect indicatorFrame = self.indicatorView.frame;
    indicatorFrame.origin.x = SCREEN_WIDTH/2 - self.indicatorView.frame.size.width/2;
    indicatorFrame.origin.y = SCREEN_HEIGHT - 10 - self.indicatorView.frame.size.height;
    self.indicatorView.frame = indicatorFrame;

    // labels on slide 1 & 2
    for (NSNumber *tag in @[@12, @22]) {
        TTTAttributedLabel *text = (TTTAttributedLabel *)[self.view viewWithTag:[tag integerValue]];
        text.font = [TDConstants fontRegularSized:19];
        text.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        text.minimumLineHeight = 27;
        text.text = text.text; //reset the text to get the styling
    }

    // slide 3 titles
    for (NSNumber *tag in @[@31, @34]) {
        TTTAttributedLabel *text = (TTTAttributedLabel *)[self.view viewWithTag:[tag integerValue]];
        text.font = [TDConstants fontSemiBoldSized:21];
        text.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        text.minimumLineHeight = 29;
        text.text = text.text; //reset the text to get the styling
    }
    // slide 3 bullets
    for (NSNumber *tag in @[@32, @33]) {
        TTTAttributedLabel *text = (TTTAttributedLabel *)[self.view viewWithTag:[tag integerValue]];
        text.font = [TDConstants fontRegularSized:21];
        text.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        text.minimumLineHeight = 29;
        text.text = text.text; //reset the text to get the styling
    }
    
    self.getStartedViewController = [[TDGetStartedViewController alloc] initWithNibName:@"TDGetStartedViewController" bundle:nil ];
    self.getStartedViewController.delegate = self;
    [self addChildViewController:self.getStartedViewController];
    [self.scrollView addSubview:self.getStartedViewController.view];
    //[self.getStartedViewController didMoveToParentViewController:self];

    CGRect getStartedFrame = self.getStartedViewController.view.frame;
    getStartedFrame.origin.x = 0;
    self.getStartedViewController.view.frame = getStartedFrame;
    
    
    self.goalsViewController =[[TDGoalsViewController alloc] initWithNibName:@"TDGoalsViewController" bundle:nil ];
    self.goalsViewController.delegate = self;
    [self addChildViewController:self.goalsViewController];
    [self.scrollView addSubview:self.goalsViewController.view];
    CGRect goalsFrame = self.goalsViewController.view.frame;
    goalsFrame.origin.x = width +10;
    self.goalsViewController.view.frame = goalsFrame;
    
    self.interestsViewController =[[TDInterestsViewController alloc] initWithNibName:@"TDInterestsViewController" bundle:nil ];
    self.interestsViewController.delegate = self;
    [self addChildViewController:self.interestsViewController];
    [self.scrollView addSubview:self.interestsViewController.view];
    CGRect interestFrame = self.interestsViewController.view.frame;
    interestFrame.origin.x = 2*width + 10;
    self.interestsViewController.view.frame = interestFrame;

    self.loadingViewController =[[TDLoadingViewController alloc] initWithNibName:@"TDLoadingViewController" bundle:nil ];
    [self addChildViewController:self.loadingViewController];
    [self.scrollView addSubview:self.loadingViewController.view];
    CGRect loadingFrame = self.loadingViewController.view.frame;
    loadingFrame.origin.x = 3*width +10;
    self.loadingViewController.view.frame = loadingFrame;
    
    debug NSLog(@"self.view = %@", NSStringFromCGRect(self.view.frame));
    debug NSLog(@"scroll view frame = %@", NSStringFromCGRect(self.scrollView.frame));
    debug NSLog(@"background image frame = %@", NSStringFromCGRect(self.backgroundImage.frame));
    
    self.scrollView.layer.borderColor = [[UIColor magentaColor] CGColor];
    self.scrollView.layer.borderWidth = 2.;
}

-(void)viewWillAppear:(BOOL)animated {
    debug NSLog(@"isnide view will appear");
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int offset = (int)scrollView.contentOffset.x;
    int page = offset / (self.pageWidth - 20);
    // Hide indicator on first slide
    self.indicatorView.hidden = offset < (self.pageWidth / 2);

   // self.backgroundImageConstraint.constant = -100 -(offset - self.pageWidth) / 4.0;

    if (page > 0 && self.currentPage != page) {
        self.currentPage = page;
        [[TDAnalytics sharedInstance] logEvent:[NSString stringWithFormat:@"intro_page_%d", page]];
        for (NSNumber *num in @[@41, @42]) {
            UIImageView *indicator = (UIImageView *)[self.view viewWithTag:[num integerValue]];
            if ([num intValue] == 40 + page) {
                [indicator setImage:[UIImage imageNamed:@"ovals_left"]];
            } else {
                [indicator setImage:[UIImage imageNamed:@"ovals_right"]];
            }
        }
    }
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

#pragma mark - GetStartedViewControllerDelegate
- (void) loginButtonPressed {
    debug NSLog(@"inside loginButtonPressed");
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
    
//    CATransition *transition = [CATransition animation];
//    transition.duration = 0.45;
//    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
//    transition.type = kCATransitionFromLeft;
//    [transition setType:kCATransitionPush];
//    transition.subtype = kCATransitionFromRight;
//    transition.delegate = self;
//    [self.navigationController.view.layer addAnimation:transition forKey:nil];
//    self.navigationController.navigationBarHidden = NO;
//    [self.navigationController pushViewController:loginController animated:NO];
    
    //[self.navigationController presentViewController:loginController animated:YES completion:nil];
    

}
- (void)getStartedButtonPressed {
    debug NSLog(@"inside getStartedButtonPressed");
   // [self.backgroundImage blurImage];
    CGRect frame2 = self.goalsViewController.view.frame;
    frame2.origin.x += 20;
    [self.scrollView scrollRectToVisible:frame2 animated:YES];
    debug NSLog(@"goals view controller=%@", NSStringFromCGRect(self.goalsViewController.view.frame));
}

#pragma mark - GoalsViewControllerDelegate 
- (void)continueButtonPressed {
    debug NSLog(@"inside continueButtonPressed");
    CGRect frame2 = self.interestsViewController.view.frame;
    frame2.origin.x += 20;
    [self.scrollView scrollRectToVisible:frame2 animated:YES];
    debug NSLog(@"interests view controller=%@", NSStringFromCGRect(self.interestsViewController.view.frame));
}

#pragma mark - InterestsViewControllerDelgate
- (void)doneButtonPressed {
    debug NSLog(@"done button pressed, load data");
    CGRect frame = self.loadingViewController.view.frame;
    frame.origin.x +=20;
    [self.scrollView scrollRectToVisible:frame animated:YES];
    [self.loadingViewController showData];
}
@end
