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
- (void)continueButtonPressed:(NSMutableArray*)goalsList;
- (void)closeButtonPressed;
@end

@interface TDGoalsViewController : UIViewController<UITableViewDataSource, UITableViewDataSource, TDGoalsCellDelegate, TDKeyboardObserverDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, weak) id <TDGoalsViewControllerDelegate> delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withCloseButton:(BOOL)yes goalsList:(NSArray*)goalsList;

//@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel1;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel2;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel3;
@property (weak, nonatomic) IBOutlet UIView *bottomMargin;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIImageView *pageIndicator;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *closeButtonBackgroundView;

@property (nonatomic) BOOL showCloseButton;
@property (nonatomic) TDKeyboardObserver *keyboardObserver;
@property (nonatomic) NSMutableArray *goalList;
@property (nonatomic) UIGestureRecognizer *tapper;
@property (nonatomic) BOOL keyboardUp;

- (IBAction)continueButtonPressed:(id)sender;
- (IBAction)closeButtonPressed:(id)sender;
@end
