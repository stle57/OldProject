//
//  TDInterestsViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 12/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDGoalsCell.h"
#import "TDKeyboardObserver.h"
@protocol TDInterestsViewControllerDelegate <NSObject>
@optional
- (void)doneButtonPressed:(NSMutableArray *)interestList;
- (void)backButtonPressed;
@end
@interface TDInterestsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, TDGoalsCellDelegate,TDKeyboardObserverDelegate, UITextFieldDelegate>

@property (nonatomic, weak) id <TDInterestsViewControllerDelegate> delegate;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withBackButton:(BOOL)yes interestsList:(NSArray*)interestsList;

//@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel1;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel2;
@property (weak, nonatomic) IBOutlet UIView *bottomMargin;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *pageIndicator;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *doneBackgroundView;

@property (nonatomic) TDKeyboardObserver *keyboardObserver;
@property (nonatomic) BOOL showBackButton;
@property (nonatomic) NSMutableArray *interestList;

- (IBAction)doneButtonPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;
@end
