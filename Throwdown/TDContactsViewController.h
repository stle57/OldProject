//
//  TDContactsViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 9/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDFollowProfileCell.h"
#import "TDContactInfo.h"
#import "TDConstants.h"
#import "TDNoFollowProfileCell.h"

@import AddressBook;

static const CGFloat MIDDLE_CELL_Y_AXIS = 23.75;

@protocol TDContactsViewControllerDelegate <NSObject>
@optional
- (void)contactPressedFromRow:(TDContactInfo*)contact;
- (void)invitesAdded:(NSMutableArray*)inviteList;
@end

@interface TDContactsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate,TDFollowProfileCellDelegate, UIActionSheetDelegate, TDNoFollowProfileCellDelegate>

@property (nonatomic, weak) id <TDContactsViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *navLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic) NSArray *contacts;
@property (nonatomic) NSMutableArray *filteredContactArray;
@property (nonatomic) CGFloat origNameLabelYAxis;
@property (nonatomic) CGRect origNameLabelFrame;
@property (nonatomic) NSMutableArray *inviteList;
@property (nonatomic) NSMutableArray *labels;
@property (nonatomic) BOOL searchingActive;
@property (nonatomic) NSString *searchText;
@property (retain) UIView *disableViewOverlay;
@property (nonatomic) NSIndexPath *editingIndexPath;

- (IBAction)backButtonHit:(id)sender;
- (IBAction)doneButtonHit:(id)sender;

- (void)setValuesForSharing:(NSArray *)currentInvite;
@end
