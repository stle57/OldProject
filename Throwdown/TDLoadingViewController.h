//
//  TDLoadingViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 12/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDLoadingView.h"
#import "TDGuestUserProfileViewController.h"
@protocol TDLoadingViewControllerDelegate <NSObject>
@optional
- (void)loadGuestView:(NSDictionary *)guestPosts;
- (void)loadHomeView;
- (void)loadInterestsView;
@end
@interface TDLoadingViewController : UIViewController
@property (nonatomic, weak) id <TDLoadingViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *alphaView;
- (void)showData:(NSArray *)goalsList interestList:(NSArray*)interestList;
- (void)animateToLastView;
@end
