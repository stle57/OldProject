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

- (void)viewDidLoad {
    [super viewDidLoad];

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
    vc.profileUser = user;
    vc.fromProfileType = kFromProfileScreenType_OtherUser;

    [self.navigationController pushViewController:vc animated:YES];
}

-(void)postPressedFromRow:(NSInteger)row {
    NSDictionary *postData = [[self.activities objectAtIndex:row] objectForKey:@"post"];
    TDPost *post = [[TDPost alloc] initWithDictionary:postData];

    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    vc.post = post;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
