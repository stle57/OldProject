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
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "TWTAPIManager.h"
#import "TDActivityIndicator.h"
#import "TDAPIClient.h"

@interface TDSocialConnectViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIButton *backButton;

@property (nonatomic) ACAccountStore *accountStore;
@property (nonatomic) TWTAPIManager *apiManager;
@property (nonatomic) NSArray *accounts;
@property (nonatomic) TDActivityIndicator *activityIndicator;

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
        case TDSocialNetworkTwitter:
            titleLabel.text = @"Twitter";
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

    self.activityIndicator = [[TDActivityIndicator alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view addSubview:self.activityIndicator];
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

    switch (self.network) {
        case TDSocialNetworkFacebook:
            if ([TDCurrentUser sharedInstance].fbUID && (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)) {
                cell.connectLabel.textColor = [TDConstants brandingRedColor];
                cell.connectLabel.text = @"Unlink";
            } else {
                cell.connectLabel.textColor = [TDConstants headerTextColor];
                cell.connectLabel.text = @"Connect to Facebook";
            }
            break;
        case TDSocialNetworkTwitter:
            if ([[TDCurrentUser sharedInstance] canPostToTwitter]) {
                cell.connectLabel.textColor = [TDConstants brandingRedColor];
                cell.connectLabel.text = @"Unlink";
            } else {
                cell.connectLabel.textColor = [TDConstants headerTextColor];
                cell.connectLabel.text = @"Connect to Twitter";
            }
            break;
    }
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (self.network) {
        case TDSocialNetworkFacebook:
            [self handleFacebook];
            break;
        case TDSocialNetworkTwitter:
            [self handleTwitter];
            break;
    }
}

- (void)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Facebook

- (void)willEnterForegroundCallback:(NSNotification *)notification {
    [self.activityIndicator stopSpinner];
    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)handleFacebook {
    // If the session state is any of the two "open" states when the button is clicked
    if ([TDCurrentUser sharedInstance].fbUID && (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)) {
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForegroundCallback:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [self.activityIndicator startSpinnerWithMessage:@"Connecting"];
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile"]
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             // Retrieve the app delegate
             // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
             [[TDAppDelegate appDelegate] sessionStateChanged:session state:state error:error success:^{
                 [self.activityIndicator stopSpinner];
                 [self.tableView reloadData];
                 [self.navigationController popViewControllerAnimated:YES];
             } failure:^(NSString *error) {
                 [self.activityIndicator stopSpinner];
                 [self.tableView reloadData];
             }];
         }];
    }
}

#pragma mark - Twitter

- (void)handleTwitter {
    if ([[TDCurrentUser sharedInstance] canPostToTwitter]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unlink?" message:@"Unlink your Twitter account?" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [[TDCurrentUser sharedInstance] unlinkTwitter];
                [self.tableView reloadData];
            }
        }];
    } else if (![TWTAPIManager isLocalTwitterAccountAvailable]) {
        // TODO: open up twitter auth in webview
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You have to add an account to the iOS Settings app first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        if (!self.accountStore) {
            self.accountStore =  [[ACAccountStore alloc] init];
        }
        [self.activityIndicator startSpinnerWithMessage:@"Connecting"];
        ACAccountType *twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [self.accountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {
            if (granted) {
                self.accounts = [self.accountStore accountsWithAccountType:twitterAccountType];
                if ([self.accounts count] == 1) {
                    ACAccount *account = [self.accounts lastObject];
                    debug NSLog(@"%@\n%@\n%@", [[account credential] oauthToken], [account credential], account);
                    [self performReverseAuthForAccount:account];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.activityIndicator stopSpinner];
                        [self selectTwitterAccount];
                    });
                }
             } else {
                 // not authed, show error to try again
                 debug NSLog(@"Failed");
             }
        }];
    }
}

- (void)selectTwitterAccount {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (ACAccount *acct in self.accounts) {
        [sheet addButtonWithTitle:acct.accountDescription];
    }
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    [sheet showInView:self.view];
}

- (void)performReverseAuthForAccount:(ACAccount *)account {
    if (!self.apiManager) {
        self.apiManager = [[TWTAPIManager alloc] init];
    }
    [self.apiManager performReverseAuthForAccount:account withHandler:^(NSData *responseData, NSError *error) {
        if (responseData) {
            [[TDCurrentUser sharedInstance] handleTwitterResponseData:responseData callback:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopSpinner];
                    if (success) {
                        [self.tableView reloadData];
                        [self.navigationController popViewControllerAnimated:YES];
                    } else {
                        [self showUnknownError];
                    }
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.activityIndicator stopSpinner];
                [self showUnknownError];
            });
            NSLog(@"Reverse Auth process failed. Error returned was: %@\n", [error localizedDescription]);
        }
    }];
}

- (void)showUnknownError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                                    message:@"Sorry, there was an unexpected error connecting your account. Please try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [self.activityIndicator startSpinnerWithMessage:@"Connecting"];
        [self performReverseAuthForAccount:self.accounts[buttonIndex]];
    }
}

@end
