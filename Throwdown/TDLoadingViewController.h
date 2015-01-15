//
//  TDLoadingViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 12/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDLoadingView.h"
@protocol TDLoadingViewControllerDelegate <NSObject>
@optional
- (void)loadGuestView;
- (void)loadHomeView;
@end
@interface TDLoadingViewController : UIViewController
@property (nonatomic, weak) id <TDLoadingViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *alphaView;
- (void)showData:(NSMutableArray *)goalsList interestList:(NSMutableArray*)interestList;
@end
