//
//  TDReviewAppCell.m
//  Throwdown
//
//  Created by Stephanie Le on 2/19/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDReviewAppCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDRateAppView.h"
#import "TDAnalytics.h"

@interface TDReviewAppCell()

@property (nonatomic, retain) UIView *topLine;
@property (nonatomic, retain) UIView *bottomLine;
@property (nonatomic, retain) UIView *bottomPaddingMargin;
@property (nonatomic, retain) TDRateAppView *enjoyView;
@property (nonatomic, retain) TDRateAppView *rateView;
@property (nonatomic, retain) TDRateAppView *feedbackView;

@end
@implementation TDReviewAppCell

- (void)awakeFromNib {
    self.backgroundColor = [TDConstants brandingRedColor];

    [self createViews];
}

- (void)prepareForReuse {
}

- (void)createViews {
    self.topLine = [[UIView alloc] initWithFrame:CGRectMake(0, .5, SCREEN_WIDTH, .5) ];
    self.topLine.backgroundColor = [TDConstants darkBorderColor];
    ;
    [self addSubview:self.topLine];

    self.bottomPaddingMargin = [[UIView alloc] initWithFrame:CGRectMake(0, 113, SCREEN_WIDTH, 15)];
    self.bottomPaddingMargin.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomPaddingMargin];

    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, SCREEN_WIDTH, .5)];
    self.bottomLine.backgroundColor = [TDConstants darkBorderColor];
    [self addSubview:self.bottomLine];

    self.enjoyView= [TDRateAppView rateView:kEnjoyView_Rate];
    CGRect enjoyViewFrame = self.enjoyView.frame;
    enjoyViewFrame.size.height = self.frame.size.height-self.bottomPaddingMargin.frame.size.height;
    enjoyViewFrame.size.width = SCREEN_WIDTH;
    self.enjoyView.frame = enjoyViewFrame;
    self.enjoyView.delegate = self;
    [self addSubview:self.enjoyView];

    self.rateView = [TDRateAppView rateView:kRateAppView_Rate];
    CGRect rateViewFrame = self.rateView.frame ;
    rateViewFrame.size.width = SCREEN_WIDTH;
    rateViewFrame.size.height = self.frame.size.height - self.bottomPaddingMargin.frame.size.height;
    self.rateView.frame = rateViewFrame;
    self.rateView.delegate = self;
    [self addSubview:self.rateView];

    self.feedbackView = [TDRateAppView rateView:kFeedbackView_Rate];
    CGRect feedbackViewFrame = self.feedbackView.frame;
    feedbackViewFrame.size.width = SCREEN_WIDTH;
    feedbackViewFrame.size.height = self.frame.size.height - self.bottomPaddingMargin.frame.size.height;
    self.feedbackView.frame = feedbackViewFrame;
    self.feedbackView.delegate = self;
    [self addSubview:self.feedbackView];

    if ([TDCurrentUser sharedInstance].didNotEnjoyThrowdown) {
        self.feedbackView.alpha = 1;
        self.enjoyView.alpha = 0;
        self.rateView.alpha = 0;
    } else if ([TDCurrentUser sharedInstance].didEnjoyThrowdown) {
        self.rateView.alpha = 1;
        self.enjoyView.alpha = 0;
        self.feedbackView.alpha = 0;
    } else {
        self.enjoyView.alpha = 1;
        self.rateView.alpha = 0;
        self.feedbackView.alpha = 0;
    }

}

- (void)setViewType:(kRateAppViewType)type {
    switch(type) {
        case kEnjoyView_Rate:
            self.enjoyView = [TDRateAppView rateView:type];
            break;
        case kRateAppView_Rate:
            self.rateView  = [TDRateAppView rateView:type];
            break;
        case kFeedbackView_Rate:
            self.feedbackView = [TDRateAppView rateView:type];
            break;

        default:
            break;
    }
}
- (void)showView:(kRateAppViewType)type {

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         switch (type) {
                             case kEnjoyView_Rate:
                                 self.rateView.alpha = 0;
                                 self.feedbackView.alpha = 0;
                                 break;

                             case kRateAppView_Rate:
                                 self.feedbackView.alpha = 0;
                                 self.enjoyView.alpha = 0;
                                 break;
                                 
                             case kFeedbackView_Rate:
                                 self.rateView.alpha = 0;
                                 self.enjoyView.alpha = 0;
                                 break;
                             default:
                                 break;
                         }
                     }
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:0.5
                                               delay:0
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              switch (type) {
                                                  case kEnjoyView_Rate:
                                                      self.enjoyView.alpha = 1;
                                                      break;
                                                  case kRateAppView_Rate:
                                                      self.rateView.alpha = 1;
                                                      break;
                                                  case kFeedbackView_Rate:
                                                      self.feedbackView.alpha = 1;
                                                      break;
                                                  default:
                                                      break;
                                              }
                                          }
                                          completion:^(BOOL finished){
                                              debug NSLog(@"done.");
                                          }
                          ];
                     }
     ];

}

- (void)fadeToReviewPrompt {
    [self showView:kRateAppView_Rate];
}

- (void)fadeToFeedbackPrompt {
    [self showView:kFeedbackView_Rate];
}

- (void)removeReviewAppCell {
    if (self.delegate && [self.delegate respondsToSelector:@selector(reloadTable)]) {
        [self.delegate reloadTable];
    }
}

- (void)openAppStore {
    [[TDAnalytics sharedInstance] logEvent:@"rating_accepted"];

    //mark as rated
    [iRate sharedInstance].ratedThisVersion = YES;

    [self.delegate reloadTable];

    //launch app store
    [[iRate sharedInstance] openRatingsPageInAppStore];
}

- (void)showFeedbackModal {
    [[TDAnalytics sharedInstance] logEvent:@"rating_closed"];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDShowFeedbackViewController object:self userInfo:nil];
}
@end
