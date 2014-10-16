//
//  TDFindPeopleViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 10/15/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDFollowProfileCell.h"
#import "TDContactInfo.h"
#import "TDConstants.h"
#import "TDNoFollowProfileCell.h"
#import "TDActivityIndicator.h"


@interface TDFindPeopleViewController : UIViewController<TDNoFollowProfileCellDelegate, UIActionSheetDelegate, TDFollowProfileCellDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *navLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic) NSInteger currentRow;
@property (nonatomic) NSArray *tdUsers;
@property (nonatomic) NSArray *suggestedUsers;
@property (nonatomic) NSMutableArray *filteredUsersArray;
@property (nonatomic) CGFloat origNameLabelYAxis;
@property (nonatomic) CGRect origNameLabelFrame;
@property (nonatomic) NSMutableArray *inviteList;
@property (nonatomic) NSMutableArray *labels;
@property (nonatomic) BOOL gotFromServer;
@property (nonatomic) TDUser *profileUser;
@property (nonatomic) BOOL searchingActive;
@property (nonatomic) NSString *searchText;
@property (retain) UIView *disableViewOverlay;
@property (retain) UIView *headerView;
@property (retain) TDNoFollowProfileCell *emptyCell;

- (IBAction)backButtonHit:(id)sender;
- (IBAction)inviteButtonHit:(id)sender;

- (void)hideActivity;
- (void)showActivity;

@end
