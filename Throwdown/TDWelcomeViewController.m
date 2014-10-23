//
//  TDWelcomeViewController.m
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDWelcomeViewController.h"
#import "TDAppDelegate.h"
#import "TDAnalytics.h"
#import <QuartzCore/QuartzCore.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

@interface TDWelcomeViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *introSlide;
@property (weak, nonatomic) IBOutlet UIView *slide1;
@property (weak, nonatomic) IBOutlet UIView *slide2;
@property (weak, nonatomic) IBOutlet UIView *slide3;
@property (weak, nonatomic) IBOutlet UIView *indicatorView;
@property (weak, nonatomic) IBOutlet UIScrollView *backgroundScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *introBackground;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slide1constraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slide2constraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slide3constraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *introSlideConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundImageConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundImageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundImageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *slide3TitleConstraint;

@property (nonatomic) int pageWidth;
@property (nonatomic) int currentPage;
@end

@implementation TDWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Move slides to the right
    CGRect frame = [[UIScreen mainScreen] bounds];
    CGFloat height = frame.size.height;
    CGFloat width = frame.size.width;

    self.pageWidth = width + 20;
    self.currentPage = 0;

    CGFloat imageWidth = self.backgroundImageWidthConstraint.constant;
    CGFloat imageHeight = self.backgroundImageHeightConstraint.constant;
    CGFloat totalWidth = (self.pageWidth * 4) + 40;

    CGFloat aspect = [UIScreen mainScreen].bounds.size.height / imageHeight;

    self.backgroundImageWidthConstraint.constant  = (imageWidth * aspect);
    self.backgroundImageHeightConstraint.constant = (imageHeight * aspect);

    self.scrollView.contentSize = CGSizeMake(totalWidth, height);
    self.scrollView.delegate = self;

    self.introSlideConstraint.constant = 10;
    self.slide1constraint.constant = self.pageWidth + 10;
    self.slide2constraint.constant = self.pageWidth * 2 + 10;
    self.slide3constraint.constant = self.pageWidth * 3 + 10;

    // Intro slide
    self.titleLabel.font = [UIFont fontWithName:@"BebasNeueRegular" size:68.0];
    self.snippetLabel.font = [TDConstants fontSemiBoldSized:20];
    self.loginButton.titleLabel.font = [TDConstants fontSemiBoldSized:14];

    // moves all the slide 3 titles up if it's a small screen
    if (height == 480) {
        self.slide3TitleConstraint.constant = 20;
    }

    self.backgroundImageConstraint.constant = -100 - (-self.pageWidth) / 4.0;

    self.indicatorView.hidden = YES;

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
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int offset = (int)scrollView.contentOffset.x;
    int page = offset / (self.pageWidth - 20);

    // Hide indicator on first slide
    self.indicatorView.hidden = offset < (self.pageWidth / 2);

    self.backgroundImageConstraint.constant = -100 -(offset - self.pageWidth) / 4.0;

    if (page > 0 && self.currentPage != page) {
        self.currentPage = page;
        [[TDAnalytics sharedInstance] logEvent:[NSString stringWithFormat:@"intro_page_%d", page]];
        for (NSNumber *num in @[@41, @42, @43]) {
            UIImageView *indicator = (UIImageView *)[self.view viewWithTag:[num integerValue]];
            if ([num intValue] == 40 + page) {
                [indicator setImage:[UIImage imageNamed:@"page-circle-orange"]];
            } else {
                [indicator setImage:[UIImage imageNamed:@"page-circle-white"]];
            }
        }
    }
}


# pragma mark - navigation

- (void)showHomeController {
    [self dismissViewControllerAnimated:NO completion:nil];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];

    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = homeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (IBAction)getStartedPressed:(id)sender {
    CGRect frame = self.slide1.frame;
    frame.origin.x += 10;
    [self.scrollView scrollRectToVisible:frame animated:YES];
}

@end
