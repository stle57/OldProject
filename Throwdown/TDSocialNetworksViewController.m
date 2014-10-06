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
    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    self.tableView.layer.borderColor = [[UIColor redColor] CGColor];
    self.tableView.layer.borderWidth = 2.;
    
    // Background
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"Social Networks";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [TDConstants fontSemiBoldSized:18];
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
    return 2;
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
    cell.topLine.hidden = YES;
    cell.bottomLine.hidden = YES;
    switch (indexPath.row) {
        case 0:
            if ([[TDCurrentUser sharedInstance] canPostToTwitter]) {
                cell.titleLabel.text = [TDCurrentUser sharedInstance].twitterIdentifier;
                cell.iconView.image = [UIImage imageNamed:@"twitter_active_48x38"];
            } else {
                cell.titleLabel.text = @"Twitter";
                cell.iconView.image = [UIImage imageNamed:@"twitter_inactive_48x38"];
            }
            break;
        case 1:
            if ([[TDCurrentUser sharedInstance] hasCachedFacebookToken]) {
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
    TDSocialConnectViewController *vc = [[TDSocialConnectViewController alloc] init];
    switch (indexPath.row) {
        case 0:
            vc.network = TDSocialNetworkTwitter;
            break;
        case 1:
            vc.network = TDSocialNetworkFacebook;
            break;
    }
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
