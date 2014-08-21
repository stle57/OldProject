//
//  TDSocialConnectViewController.m
//  Throwdown
//
//  Created by Andrew C on 8/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSocialConnectViewController.h"
#import "TDViewControllerHelper.h"
#import "TDConstants.h"
#import "TDSocialConnectCell.h"
#import <FacebookSDK/FacebookSDK.h>
#import "TDAppDelegate.h"
#import "TDCurrentUser.h"
#import "UIAlertView+TDBlockAlert.h"

@interface TDSocialConnectViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIButton *backButton;

@end

@implementation TDSocialConnectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TDConstants backgroundColor];

    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [TDConstants headerTextColor];
    titleLabel.font = [TDConstants fontRegularSized:20];
    switch (self.network) {
        case TDSocialNetworkFacebook:
            titleLabel.text = @"Facebook";
            break;
    }
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
    TDSocialConnectCell *cell = (TDSocialConnectCell *)[tableView dequeueReusableCellWithIdentifier:@"TDSocialConnectCell"];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDSocialConnectCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.connectLabel.font = [TDConstants fontRegularSized:18];
        cell.connectLabel.textAlignment = NSTextAlignmentCenter;
    }

    switch (indexPath.row) {
        case 0:
            if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
                cell.connectLabel.textColor = [TDConstants brandingRedColor];
                cell.connectLabel.text = @"Unlink";
            } else {
                cell.connectLabel.textColor = [TDConstants headerTextColor];
                cell.connectLabel.text = @"Connect to Facebook";
            }
            break;
    }
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.network == TDSocialNetworkFacebook) {
        // If the session state is any of the two "open" states when the button is clicked
        if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unlink?" message:@"Unlink your Facebook account?" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
            [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    // Close the session and remove the access token from the cache
                    // The session state handler (in the app delegate) will be called automatically
                    [FBSession.activeSession closeAndClearTokenInformation];
                    [[TDCurrentUser sharedInstance] unlinkFacebook];
                    [self.tableView reloadData];
                }
            }];
        } else {
            // Open a session showing the user the login UI
            // You must ALWAYS ask for public_profile permissions when opening a session
            [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                               allowLoginUI:YES
                                          completionHandler:
             ^(FBSession *session, FBSessionState state, NSError *error) {
                 // Retrieve the app delegate
                 // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
                 [[TDAppDelegate appDelegate] sessionStateChanged:session state:state error:error success:^{
                     [self.tableView reloadData];
                     [self.navigationController popViewControllerAnimated:YES];
                 } failure:^(NSString *error) {
                     [self.tableView reloadData];
                 }];
             }];
        }
    }
}

- (void)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
