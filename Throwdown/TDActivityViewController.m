//
//  TDActivityViewController.m
//  Throwdown
//
//  Created by Andrew C on 4/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDActivityViewController.h"
#import "TDAPIClient.h"
#import "TDCurrentUser.h"
#import "TDActivitiesCell.h"
#import "TDConstants.h"
#import "TDUserProfileViewController.h"
#import "TDUser.h"
#import "TDPost.h"

static NSString *const kActivityCell = @"TDActivitiesCell";

@interface TDActivityViewController () <UITableViewDataSource, TDActivitiesCellDelegate>

@property (nonatomic) NSArray *activities;
@property (nonatomic, retain) UIRefreshControl *refreshControl;

@end

@implementation TDActivityViewController

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Reset app badge count
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    // Reset feed button count
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdate
                                                        object:self
                                                      userInfo:@{@"notificationCount": @0}];


    self.tableView.dataSource = self;
    self.activities = @[];
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [UIColor colorWithRed:.223529412 green:.223529412 blue:.223529412 alpha:1.0],
                                                                    NSFontAttributeName: [TDConstants fontRegularSized:18.0]
                                                                    };

    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshControlUsed)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl setTintColor:[UIColor blackColor]];

    [self refresh];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSourceDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDActivitiesCell *cell = [tableView dequeueReusableCellWithIdentifier:kActivityCell];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:kActivityCell owner:self options:nil];
        cell = (TDActivitiesCell *)[topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }
    cell.activity = [self.activities objectAtIndex:[indexPath row]];
    cell.row = indexPath.row;

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.activities count];
}

#pragma mark - Refresh Control

- (void)refreshControlUsed {
    [self refresh];
}

- (void)refresh {
    [self.refreshControl beginRefreshing];
    [[TDAPIClient sharedInstance] getActivityForUserToken:[TDCurrentUser sharedInstance].authToken success:^(NSArray *activities) {
        self.activities = activities;
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    } failure:^{
        debug NSLog(@"error on activity");
        [self.refreshControl endRefreshing];
    }];
}

#pragma mark - TDActivitiesCellDelegate

- (void)userProfilePressedFromRow:(NSInteger)row {
    NSDictionary *userData = [[self.activities objectAtIndex:row] objectForKey:@"user"];
    TDUser *user = [[TDUser alloc] initWithDictionary:userData];

    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = user.userId;
    vc.fromProfileType = kFromProfileScreenType_OtherUser;

    [self.navigationController pushViewController:vc animated:YES];
    [self updateActivityAsClicked:row];
}

-(void)postPressedFromRow:(NSInteger)row {
    NSNumber *postId = [[[self.activities objectAtIndex:row] valueForKey:@"post"] valueForKey:@"id"];
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    vc.postId = postId;
    [self.navigationController pushViewController:vc animated:YES];
    [self updateActivityAsClicked:row];
}

- (void)updateActivityAsClicked:(NSInteger)row {
    if ([[self.activities objectAtIndex:row] objectForKey:@"id"]) {
        [[TDAPIClient sharedInstance] updateActivity:[[self.activities objectAtIndex:row] objectForKey:@"id"] seen:NO clicked:YES];
    }
}

#pragma mark - support unwinding on push notification

- (void)unwindToRoot {
    [self performSegueWithIdentifier:@"UnwindToHomeSegue" sender:nil];
}

@end
