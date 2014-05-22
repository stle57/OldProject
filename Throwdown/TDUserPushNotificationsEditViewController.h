//
//  TDUserPushNotificationsEditViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/30/14.
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
#import "TDPushEditCell.h"
#import "TDConstants.h"
#import "TDActivityIndicator.h"

@interface TDUserPushNotificationsEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, TDPushEditCellDelegate>
{
    CGRect origTableViewFrame;
    CGRect statusBarFrame;
    BOOL gotFromServer;
    NSMutableDictionary *pushSettingsDict;
    UIView *headerView;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionHeaderLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;
@property (nonatomic, retain) NSMutableDictionary *pushSettingsDict;
@property (nonatomic, retain) UIView *headerView;

-(IBAction)backButtonHit:(id)sender;
@end
