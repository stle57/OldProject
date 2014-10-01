//
//  TDFollowViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 9/12/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPostsViewController.h"
#import "TDAppDelegate.h"
#import "TDPostAPI.h"
#import "TDConstants.h"
#import "TDUserAPI.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "TDUserEditCell.h"
#import "TDConstants.h"
#import "TDActivityIndicator.h"
#import "TDUserPasswordEditViewController.h"
#import "TDFollowProfileCell.h"
#import "TDNoFollowProfileCell.h"
#import "TDContactsViewController.h"

#define TABLEVIEW_POSITION_UNDER_SEARCHBAR 69
#define TD_NOFOLLOWCELL_HEIGHT 120
#define TD_FOLLOW_CELL_HEIGHT 65
#define TD_NOFOLLOWCELL_HEIGHT2 190

@interface TDFollowViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, TDFollowProfileCellDelegate, TDNoFollowProfileCellDelegate, TDContactsViewControllerDelegate, UIScrollViewDelegate>
{
    TDUser *profileUser;
    NSString *name;
    NSString *username;
    NSString *pictureFileName;
    CGRect origTableViewFrame;
    CGRect statusBarFrame;
    BOOL keybdUp;
    kFeedProfileType profileType;
    UIImage *editedProfileImage;
    UIImageView *tempFlyInImageView;

}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *suggestedLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *pictureFileName;
@property (nonatomic, retain) TDUser *profileUser;
@property (nonatomic, assign) kUserListType followControllerType;
@property (nonatomic, retain) UIImage *editedProfileImage;
@property (nonatomic, retain) UIImageView *tempFlyInImageView;
@property (nonatomic) UIButton *backButton;

- (IBAction)inviteButtonHit:(id)sender;

@end
