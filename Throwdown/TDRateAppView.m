//
//  TDRateAppView.m
//  Throwdown
//
//  Created by Stephanie Le on 11/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDRateAppView.h"
#import "TDViewControllerHelper.h"
#import "TDAppDelegate.h"
#import "TDAnalytics.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include "TDCurrentUser.h"
#include "TDHomeViewController.h"
#include "TDFeedbackViewController.h"

@implementation TDRateAppView
static NSString *yesButtonStr = @"btn_yes";
static NSString *okSureButtonStr = @"btn_ok_sure";
static NSString *notReallButtonStr = @"btn_not_really";
static NSString *noThanksButtonStr = @"btn_no_thanks";

- (void)dealloc {
    debug NSLog(@"TDRateAppView dealloc");

}

+ (id)rateView:(kRateAppViewType)type {
    TDRateAppView *rateView = [[[NSBundle mainBundle] loadNibNamed:@"TDRateAppView" owner:nil options:nil] lastObject];
    if ([rateView isKindOfClass:[TDRateAppView class]]) {
        [rateView setup:type];
        return rateView;
    } else {
        return nil;
    }
    return rateView;
}

- (void)setup:(kRateAppViewType)type {
    //debug NSLog(@"inside setup");
    self.viewType = type;
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, 113);
    self.backgroundColor = [TDConstants brandingRedColor];
    // Initialization code
    switch(self.viewType) {
        case kEnjoyView_Rate:
            [self setTDEnjoyView];
            break;
        case kRateAppView_Rate:
            [self setReviewAppView];
            break;
        case kFeedbackView_Rate:
            [self setFeedbackView];
            break;
        default:
            break;
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)setTDEnjoyView {
    // Configures the cell to ask if user is enjoying Throwdown
    NSString *titleStr = @"Enjoying Throwdown?";
    NSAttributedString *titleAttStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontRegularSized:17] color:[UIColor whiteColor] lineHeight:20 lineHeightMultipler:20/17];
    self.title.attributedText = titleAttStr;
    [self.title sizeToFit];

    CGRect titleFrame = self.title.frame;
    titleFrame.origin.x = SCREEN_WIDTH/2 - self.title.frame.size.width/2;
    titleFrame.origin.y = 20;
    self.title.frame = titleFrame;

    //Position the buttons
    CGFloat middleCellXPosition = SCREEN_WIDTH/2;

    CGRect noButtonFrame = self.noButton.frame;
    noButtonFrame.origin.x = middleCellXPosition - 10 - noButtonFrame.size.width;
    noButtonFrame.origin.y = self.title.frame.origin.y + self.title.frame.size.height + 20;
    self.noButton.frame = noButtonFrame;

    CGRect yesButtonFrame = self.yesButton.frame;
    yesButtonFrame.origin.x = middleCellXPosition + 10;
    yesButtonFrame.origin.y = self.title.frame.origin.y + self.title.frame.size.height + 20;
    self.yesButton.frame = yesButtonFrame;


}

- (void)setReviewAppView {
    // Configure the cellt o ask if user can review Throwdown.
    NSString *titleStr = @"How about rating us in the App Store?";
    NSAttributedString *titleAttStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontRegularSized:17] color:[UIColor whiteColor] lineHeight:20 lineHeightMultipler:20/17];
    self.title.attributedText = titleAttStr;
    [self.title sizeToFit];

    CGRect titleFrame = self.title.frame;
    titleFrame.origin.x = SCREEN_WIDTH/2 - self.title.frame.size.width/2;
    titleFrame.origin.y = 20;
    self.title.frame = titleFrame;

    // Change the buttons
    [self.noButton setImage:[UIImage imageNamed:noThanksButtonStr] forState:UIControlStateNormal];
    [self.noButton sizeToFit];

    [self.noButton addTarget:self action:@selector(removeCell) forControlEvents:UIControlEventTouchUpInside];

    [self.yesButton setImage:[UIImage imageNamed:okSureButtonStr] forState:UIControlStateNormal];
    [self.yesButton sizeToFit];
    [self.yesButton addTarget:self action:@selector(openAppStore) forControlEvents:UIControlEventTouchUpInside];

    //Position the buttons
    CGFloat middleCellXPosition = SCREEN_WIDTH/2;

    CGRect noButtonFrame = self.noButton.frame;
    noButtonFrame.origin.x = middleCellXPosition - 10 - noButtonFrame.size.width;
    noButtonFrame.origin.y = self.title.frame.origin.y + self.title.frame.size.height + 20;
    self.noButton.frame = noButtonFrame;

    CGRect yesButtonFrame = self.yesButton.frame;
    yesButtonFrame.origin.x = middleCellXPosition + 10;
    yesButtonFrame.origin.y = self.title.frame.origin.y + self.title.frame.size.height + 20;
    self.yesButton.frame = yesButtonFrame;
}

- (void)setFeedbackView {
    // Configure the cell to ask for a review.
    NSString *titleStr = @"Would you give us some feedback?";
    NSAttributedString *titleAttStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontRegularSized:17] color:[UIColor whiteColor] lineHeight:20 lineHeightMultipler:20/17];
    self.title.attributedText = titleAttStr;
    [self.title sizeToFit];

    CGRect titleFrame = self.title.frame;
    titleFrame.origin.x = SCREEN_WIDTH/2 - self.title.frame.size.width/2;
    titleFrame.origin.y = 20;
    self.title.frame = titleFrame;

    // Change the buttons
    [self.noButton setImage:[UIImage imageNamed:noThanksButtonStr] forState:UIControlStateNormal];
    [self.noButton sizeToFit];

    [self.noButton addTarget:self action:@selector(removeCell) forControlEvents:UIControlEventTouchUpInside];

    [self.yesButton setImage:[UIImage imageNamed:okSureButtonStr] forState:UIControlStateNormal];
    [self.yesButton sizeToFit];
    [self.yesButton addTarget:self action:@selector(showFeedbackView) forControlEvents:UIControlEventTouchUpInside];

    //Position the buttons
    CGFloat middleCellXPosition = SCREEN_WIDTH/2;

    CGRect noButtonFrame = self.noButton.frame;
    noButtonFrame.origin.x = middleCellXPosition - 10 - noButtonFrame.size.width;
    noButtonFrame.origin.y = self.title.frame.origin.y + self.title.frame.size.height + 20;
    self.noButton.frame = noButtonFrame;

    CGRect yesButtonFrame = self.yesButton.frame;
    yesButtonFrame.origin.x = middleCellXPosition + 10;
    yesButtonFrame.origin.y = self.title.frame.origin.y + self.title.frame.size.height + 20;
    self.yesButton.frame = yesButtonFrame;
}


- (IBAction)noButtonPressed:(id)sender {
    [[TDCurrentUser sharedInstance] didNotEnjoyThrowdown:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(removeReviewAppCell)]) {
        [self.delegate fadeToFeedbackPrompt];
    }
}

- (IBAction)yesButtonPressed:(id)sender{
    [[TDCurrentUser sharedInstance] didEnjoyThrowdown:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(fadeToReviewPrompt)]) {
        [self.delegate fadeToReviewPrompt];
    }
}

- (void)showSendFeedbackView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fadeToReviewPrompt)]) {
        [self.delegate fadeToReviewPrompt];
    }
}

- (void)removeCell {
    [iRate sharedInstance].declinedThisVersion = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(removeReviewAppCell)]) {
        [self.delegate removeReviewAppCell];
    }
}

- (void)openAppStore {
    if (self.delegate && [self.delegate respondsToSelector:@selector(openAppStore)]) {
        [self.delegate openAppStore];
    }
}

- (void)showFeedbackView {
    [iRate sharedInstance].declinedThisVersion = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(showFeedbackModal)]) {
        [self.delegate showFeedbackModal];
    }
}

@end
