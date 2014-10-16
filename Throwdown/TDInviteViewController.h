//
//  TDInviteViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 9/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDContactsViewController.h"
#import "TDInviteCell.h"
#import "TDActivityIndicator.h"

#define TD_INVITE_CELL_HEIGHT 65
#define TD_INVITE_HEADER_HEIGHT_SEC0 120
#define TD_INVITE_HEADER_HEIGHT_SEC1 13
#define TD_INVITE_HEADER_HEIGHT_SEC2 49
#define HEADER1_TOP_MARGIN 20
#define HEADER1_MIDDLE_MARGIN 25
#define HEADER1_BOTTOM_MARGIN 13
#define HEADER2_TOP_MARGIN 25
#define HEADER2_BOTTOM_MARGIN 10

@interface TDInviteViewController : UIViewController<UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate, TDContactsViewControllerDelegate, TDFollowProfileCellDelegate, TDInviteCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (nonatomic) CGRect origUsernameLabelFrame;
@property (nonatomic) CGRect origNameLabelFrame;

@property (nonatomic) NSMutableArray *headerLabels;
@property (nonatomic) TDActivityIndicator *activityIndicator;

- (IBAction)closeButtonHit:(id)sender;
- (IBAction)nextButtonHit:(id)sender;

@end
