//
//  TDFindPeopleController.h
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
#import "TDActivityIndicator.h"

//@protocol TDFindPeopleControllerDelegate <NSObject>
//@optional
//- (void)contactPressedFromRow:(TDContactInfo*)contact;
//- (void)invitesAdded:(NSMutableArray*)inviteList;
//@end

@interface TDFindPeopleController : UIViewController<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, TDFollowProfileCellDelegate, UIActionSheetDelegate, TDNoFollowProfileCellDelegate>

//@property (nonatomic, assign) id <TDFindPeopleControllerDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UILabel *navLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *suggestedLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;
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

- (IBAction)backButtonHit:(id)sender;
- (IBAction)inviteButtonHit:(id)sender;

- (void)hideActivity;
- (void)showActivity;
@end
