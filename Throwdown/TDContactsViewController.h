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

@import AddressBook;

static const CGFloat MIDDLE_CELL_Y_AXIS = 23.75;

@protocol TDContactsViewControllerDelegate <NSObject>
@optional
- (void)contactPressedFromRow:(TDContactInfo*)contact;
@end

@interface TDContactsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, TDFollowProfileCellDelegate, UIActionSheetDelegate>

@property (nonatomic, assign) id <TDContactsViewControllerDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UILabel *navLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *suggestedLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (nonatomic) NSArray *contacts;
@property (nonatomic) NSArray *userList;
@property (nonatomic) NSMutableArray *filteredContactArray;


- (IBAction)backButtonHit:(id)sender;
- (IBAction)inviteButtonHit:(id)sender;
@end
