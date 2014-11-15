//
//  TDRateAppView.m
//  Throwdown
//
//  Created by Stephanie Le on 11/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDRateAppView.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDAppDelegate.h"
#import "TDAnalytics.h"
#import "iRate.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include "TDCurrentUser.h"
#include "TDHomeViewController.h"
#include "TDFeedbackViewController.h"

@implementation TDRateAppView
- (void)dealloc {
    debug NSLog(@"TDRateAppView dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)viewDidLoad {
    debug NSLog(@"inside viewDidLoad");

    [self setup];
}

+ (id)rateView {
    TDRateAppView *rateView = [[[NSBundle mainBundle] loadNibNamed:@"TDRateAppView" owner:nil options:nil] lastObject];
    if ([rateView isKindOfClass:[TDRateAppView class]]) {
        return rateView;
    } else {
        return nil;
    }
    return rateView;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:(CGRect)frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    debug NSLog(@"setup inside TDRateAppView");
    self.backgroundColor = [UIColor whiteColor];
    debug NSLog(@"view frame before changing = %@", NSStringFromCGRect(self.frame));
    CGRect viewFrame = self.frame;
    viewFrame.origin.x = SCREEN_WIDTH/2 - 290/2;
    viewFrame.origin.y = SCREEN_HEIGHT/2 - 310/2;
    viewFrame.size.width = 290;
    viewFrame.size.height = 310;
    self.frame = viewFrame;
    debug NSLog(@"self.frame=%@", NSStringFromCGRect(self.frame));
    UIImage *image = [UIImage imageNamed:@"td_icon.png"];
    if (image != nil) {
        debug NSLog(@"image does not equal NIL");
    }
//    debug NSLog(@"width of image=%f", image.size.width);
//    debug NSLog(@"height of image = %f", image.size.height);
//
    [self.tdIcon setImage:image];

    CGRect tdFrame = self.tdIcon.frame;
    tdFrame.origin.x = self.frame.size.width/2 - self.tdIcon.frame.size.width/2;
    tdFrame.origin.y = 21;
    self.tdIcon.frame = tdFrame;
    
    self.tdIcon.layer.borderColor = [[UIColor magentaColor] CGColor];
    self.tdIcon.layer.borderWidth = 2.0;
    debug NSLog(@"tdicon = %@", NSStringFromCGRect(self.tdIcon.frame));
    // Create top label
    NSString *labelText = @"Enjoying Throwdown?";
//    self.label1 = [[UILabel alloc] initWithFrame:CGRectMake(20, self.tdIcon.frame.origin.y+self.tdIcon.frame.size.height + 19,self.frame.size.width, 50)];
    CGRect label1Frame = self.label1.frame;
    label1Frame.origin.x = 20;
    label1Frame.origin.y = self.tdIcon.frame.origin.y+self.tdIcon.frame.size.height + 19;
    label1Frame.size.width = self.frame.size.width;
    label1Frame.size.height = 50;
    self.label1.frame = label1Frame;
    
    NSAttributedString *label1String = [TDViewControllerHelper makeParagraphedTextWithString:labelText font:[TDConstants fontSemiBoldSized:21] color:[TDConstants commentTextColor] lineHeight:(21) lineHeightMultipler:21/21];
    self.label1.attributedText = label1String;
    [self.label1 sizeToFit];
    debug NSLog(@"label1 frame=%@", NSStringFromCGRect(self.label1.frame));
    
    NSString *label2Text = @"Recommend Throwdown to others by\nleaving us a review in the App Store";
    CGRect label2Frame = self.label2.frame;
    label2Frame.origin.x = 20;
    label2Frame.origin.y = self.label1.frame.origin.y + self.label1.frame.size.height + 8;
    label2Frame.size.width = self.frame.size.width;
    label2Frame.size.height = 100;
    self.label2.frame = label2Frame;
    NSAttributedString *label2String = [TDViewControllerHelper makeParagraphedTextWithString:label2Text font:[TDConstants fontSemiBoldSized:14] color:[TDConstants commentTextColor] lineHeight:(17) lineHeightMultipler:17/14];
    self.label2.attributedText = label2String;
    self.label2.textAlignment = NSTextAlignmentLeft;
    [self.label2 setNumberOfLines:0];
    [self.label2 sizeToFit];
    [self addSubview:self.label2];
    self.label2.layer.borderWidth = 2.;
    self.label2.layer.borderColor = [[UIColor blueColor] CGColor];
    
    CGFloat space = self.frame.size.height - self.tdIcon.frame.size.height - self.label2.frame.size.height - self.label1.frame.size.height - 21 - 19 -8 -self.rateButton.frame.size.height - self.dismissButton.frame.size.height - self.feedbackButton.frame.size.height;
    
    debug NSLog(@"space left=%f", space);
    
    CGRect divider1Frame = self.divider.frame;
    divider1Frame.origin.x = 0;
    divider1Frame.origin.y = self.label2.frame.origin.y + self.label2.frame.size.height + space;
    self.divider.frame = divider1Frame;
    self.divider.layer.borderColor = [[TDConstants darkBackgroundColor] CGColor];
    debug NSLog(@"divider frame=%@",NSStringFromCGRect( self.divider.frame));
    
    NSString *rateLabel = @"Yes, rate it now!";
//    self.rateButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.label2.frame.origin.y + self.label2.frame.size.height + 20, self.frame.size.width, TD_BUTTON_HEIGHT)];
    [self.rateButton setTitle:rateLabel forState:UIControlStateNormal];
    self.rateButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.rateButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.rateButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateNormal];
    [self.rateButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateSelected];

    CGRect rateFrame = self.rateButton.frame;
    rateFrame.origin.x = 0;
    rateFrame.origin.y = self.label2.frame.origin.y + self.label2.frame.size.height + space;
    rateFrame.size.width = self.frame.size.width;
    rateFrame.size.height = TD_BUTTON_HEIGHT;
    self.rateButton.frame = rateFrame;
    
    NSString *feedbackLabel = @"No, send feedback";
//    self.feedbackButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.rateButton.frame.origin.y + self.rateButton.frame.size.height, self.frame.size.width, TD_BUTTON_HEIGHT)];
    [self.feedbackButton setTitle:feedbackLabel forState:UIControlStateNormal];
    self.feedbackButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.feedbackButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateNormal];
    [self.feedbackButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateSelected];
//    [self.feedbackButton addTarget:self action: @selector(feedbackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    [self addSubview:self.feedbackButton];
    self.feedbackButton.layer.borderColor = [[UIColor blueColor] CGColor];
    self.feedbackButton.layer.borderWidth = 2.;

    CGRect feedbackFrame = self.feedbackButton.frame;
    feedbackFrame.origin.x = 0;
    feedbackFrame.origin.y = self.rateButton.frame.origin.y + self.rateButton.frame.size.height;
    feedbackFrame.size.width = self.frame.size.width;
    feedbackFrame.size.height = TD_BUTTON_HEIGHT;
    self.feedbackButton.frame = feedbackFrame;
    
    NSString *dismissLabel = @"Dismiss";
//    self.dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.feedbackButton.frame.origin.y + self.feedbackButton.frame.size.height, self.frame.size.width, TD_BUTTON_HEIGHT)];
    [self.dismissButton setTitle:dismissLabel forState:UIControlStateNormal];
    self.dismissButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.dismissButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateNormal];
    [self.dismissButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateSelected];
    [self addSubview:self.dismissButton];
//    [self.dismissButton addTarget:self action: @selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect dismissFrame = self.dismissButton.frame;
    dismissFrame.origin.x = 0;
    dismissFrame.origin.y = self.feedbackButton.frame.origin.y + self.feedbackButton.frame.size.height;
    dismissFrame.size.width = self.frame.size.width;
    dismissFrame.size.height = TD_BUTTON_HEIGHT;
    self.dismissButton.frame = dismissFrame;
    
    self.dismissButton.layer.borderColor = [[UIColor greenColor] CGColor];
    self.dismissButton.layer.borderWidth = 2.;

    debug NSLog(@"rateButton frame=%@", NSStringFromCGRect(self.rateButton.frame));
    debug NSLog(@"feedbackButton frame = %@", NSStringFromCGRect(self.feedbackButton.frame));
    debug NSLog(@"dismissButton frame = %@", NSStringFromCGRect(self.dismissButton.frame));
    debug NSLog(@"self.frame.size.width=%f", self.frame.size.width);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animateHide) name:TDRemoveRateView object:nil];
    //self.hidden = YES;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)showInView {
    if ([self isKindOfClass:[UIView class]])
    {
        [self setup];
        [[TDAppDelegate appDelegate].window addSubview:self];

        [self animateShow];
    }
}

- (void)animateShow
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                      animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
    CATransform3D scale2 = CATransform3DMakeScale(1.2, 1.2, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
    CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:
                            [NSValue valueWithCATransform3D:scale1],
                            [NSValue valueWithCATransform3D:scale2],
                            [NSValue valueWithCATransform3D:scale3],
                            [NSValue valueWithCATransform3D:scale4],
                            nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.5],
                           [NSNumber numberWithFloat:0.9],
                           [NSNumber numberWithFloat:1.0],
                           nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = 0.2;
    
    [AlertView.layer addAnimation:animation forKey:@"show"];
}

- (void)animateHide
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                      animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(1.0, 1.0, 1);
    CATransform3D scale2 = CATransform3DMakeScale(0.5, 0.5, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.0, 0.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:
                            [NSValue valueWithCATransform3D:scale1],
                            [NSValue valueWithCATransform3D:scale2],
                            [NSValue valueWithCATransform3D:scale3],
                            nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.5],
                           [NSNumber numberWithFloat:0.9],
                           nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = 0.1;
    
    [AlertView.layer addAnimation:animation forKey:@"hide"];
    
    [self performSelector:@selector(removeFromSuperview) withObject:self afterDelay:0.105];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TDRemoveHomeViewControllerOverlay
                                                        object:self
                                                      userInfo:nil];
}

- (IBAction)feedbackButtonPressed:(UIButton *)sender {
    debug NSLog(@"feedback button pressed");
    
    self.feedbackVC = [[TDFeedbackViewController alloc] initWithNibName:@"TDFeedbackViewController" bundle:nil ];
    
    [self addSubview:self.feedbackVC.view];
}

- (IBAction)rateButtonPressed:(UIButton *)sender {
    debug NSLog(@"rate button tapped");
    debug NSLog(@"inside TDRateUsDelegate:toastNotificationTappedRateUs");

    [[TDAnalytics sharedInstance] logEvent:@"rating_accepted"];
    [self animateHide];

    //mark as rated
    [iRate sharedInstance].ratedThisVersion = YES;
    
    //launch app store
    [[iRate sharedInstance] openRatingsPageInAppStore];
    
}

- (IBAction)dismissButtonPressed:(UIButton *)sender {
    debug NSLog(@"dismiss button pressed");
    [self animateHide];
}

@end
