//
//  TDRateAppView.h
//  Throwdown
//
//  Created by Stephanie Le on 11/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDFeedbackViewController.h"
#import "iRate.h"
#import "TDConstants.h"

@protocol TDRateAppDelegate <NSObject>
@optional
-(void)openAppStore;
-(void)removeReviewAppCell;
-(void)fadeToReviewPrompt;
-(void)fadeToFeedbackPrompt;
-(void)showFeedbackModal;
@end

@interface TDRateAppView : UIView<iRateDelegate>
@property (nonatomic, weak) id <TDRateAppDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIButton *yesButton;
@property (weak, nonatomic) IBOutlet UIButton *noButton;
@property (weak, nonatomic) IBOutlet UIView *bottomPadding;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (nonatomic, retain) TDFeedbackViewController *feedbackVC;
@property (nonatomic) kRateAppViewType viewType;
+ (id)rateView:(kRateAppViewType)type;
- (void)setup:(kLoadingViewType)type;

- (IBAction)noButtonPressed:(id)sender;
- (IBAction)yesButtonPressed:(id)sender;
@end
