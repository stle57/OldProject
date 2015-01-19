//
//  TDUsersViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 1/18/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDActivityIndicator.h"
#import "TDFollowProfileCell.h"

@interface TDUsersViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, TDFollowProfileCellDelegate>
@property (weak, nonatomic) IBOutlet UILabel *navLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic) NSArray *userList;
@property (nonatomic) NSString *navTitle;
@property (nonatomic) BOOL gotFromServer;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString*)title;
- (IBAction)backButtonHit:(id)sender;
@end
