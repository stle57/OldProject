//
//  TDSocialNetworksViewController.m
//  Throwdown
//
//  Created by Andrew C on 8/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSocialNetworksViewController.h"
#import "TDViewControllerHelper.h"
#import "TDConstants.h"
#import "TDSocialNetworkCell.h"
#import "TDSocialConnectViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "TDCurrentUser.h"

@interface TDSocialNetworksViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIButton *backButton;

@end

@implementation TDSocialNetworksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TDConstants backgroundColor];

    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"Social Networks";
    titleLabel.textColor = [TDConstants headerTextColor];
    titleLabel.font = [TDConstants fontRegularSized:20];
    [self.navigationItem setTitleView:titleLabel];

    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

    self.tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] bounds] style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - TableViewDelegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 42.;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDSocialNetworkCell *cell = (TDSocialNetworkCell *)[tableView dequeueReusableCellWithIdentifier:@"TDSocialNetworkCell"];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDSocialNetworkCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.titleLabel.font = [TDConstants fontRegularSized:18];
    }

    switch (indexPath.row) {
        case 0:
            if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
                cell.titleLabel.text = [TDCurrentUser sharedInstance].fbIdentifier;
                cell.iconView.image = [UIImage imageNamed:@"fb_active_48x48"];
            } else {
                cell.titleLabel.text = @"Facebook";
                cell.iconView.image = [UIImage imageNamed:@"fb_inactive_48x48"];
            }
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0: {
            TDSocialConnectViewController *vc = [[TDSocialConnectViewController alloc] init];
            vc.network = TDSocialNetworkFacebook;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

- (void)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
