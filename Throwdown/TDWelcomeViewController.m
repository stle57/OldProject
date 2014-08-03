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
@end

@implementation TDWelcomeViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect pagingScrollViewFrame = [[UIScreen mainScreen] bounds];
    pagingScrollViewFrame.origin.x -= 10;
    pagingScrollViewFrame.size.width += 20;
    self.scrollView.frame = pagingScrollViewFrame;
    self.scrollView.contentSize = CGSizeMake(340 * 4, pagingScrollViewFrame.size.height);
    self.scrollView.delegate = self;

    // Move slides to the right
    CGRect frame = [[UIScreen mainScreen] bounds];

    CGFloat screenHeight = frame.size.height;

    frame.origin.x += 10;
    self.introSlide.frame = frame;
    frame.origin.x += frame.size.width + 20;
    self.slide1.frame = frame;
    frame.origin.x += frame.size.width + 20;
    self.slide2.frame = frame;
    frame.origin.x += frame.size.width + 20;
    self.slide3.frame = frame;

    // Intro slide
    self.titleLabel.font = [UIFont fontWithName:@"BebasNeueRegular" size:68.0];
    self.snippetLabel.font = [TDConstants fontSemiBoldSized:20];
    self.loginButton.titleLabel.font = [TDConstants fontSemiBoldSized:14];

    if (screenHeight == 480.) {
        [self fixPosition:self.titleLabel];
        [self fixPosition:self.snippetLabel];
        [self fixPosition:self.loginButton];
        [self fixPosition:self.signupButton];
        [self fixPosition:self.indicatorView withHeight:88];
        for (UIView *view in [self.slide1 subviews]) {
            [self fixPosition:view withHeight:88];
        }
        for (UIView *view in [self.slide2 subviews]) {
            [self fixPosition:view withHeight:88];
        }
        for (UIView *view in [self.slide3 subviews]) {
            [self fixPosition:view];
        }
    }

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

- (void)fixPosition:(UIView *)view {
    [self fixPosition:view withHeight:44];
}

- (void)fixPosition:(UIView *)view withHeight:(CGFloat)height {
    CGRect frame = view.layer.frame;
    frame.origin.y -= height;
    view.frame = frame;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int offset = (int)scrollView.contentOffset.x;
    int page = offset / 340;

    // Hide indicator on first slide
    self.indicatorView.hidden = offset < 170;

    [self.backgroundScrollView setContentOffset:CGPointMake((offset - 340) / 4.f, 0)];

    if (offset % 340 == 0 && page > 0) {
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
    UIViewController *homeViewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeViewController"];

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
