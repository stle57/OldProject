//
//  TDGoalsViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 12/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDGoalsCell.h"
#import "TDKeyboardObserver.h"
@protocol TDGoalsViewControllerDelegate <NSObject>
@optional
- (void)continueButtonPressed;
@end

@interface TDGoalsViewController : UIViewController<UITableViewDataSource, UITableViewDataSource, TDGoalsCellDelegate, TDKeyboardObserverDelegate, UITextFieldDelegate>
@property (nonatomic, weak) id <TDGoalsViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel1;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel2;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel3;
@property (weak, nonatomic) IBOutlet UIView *bottomMargin;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (nonatomic) TDKeyboardObserver *keyboardObserver;

- (IBAction)continueButtonPressed:(id)sender;
@end
