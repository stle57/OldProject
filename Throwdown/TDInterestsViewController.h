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
- (void)doneButtonPressed;
@end
@interface TDInterestsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, TDGoalsCellDelegate,TDKeyboardObserverDelegate, UITextFieldDelegate>

@property (nonatomic, weak) id <TDInterestsViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel1;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel2;
@property (weak, nonatomic) IBOutlet UIView *bottomMargin;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (nonatomic) TDKeyboardObserver *keyboardObserver;
- (IBAction)doneButtonPressed:(id)sender;
@end
