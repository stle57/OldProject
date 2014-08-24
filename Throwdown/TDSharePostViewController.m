//
//  TDShareWithViewController.m
//  Throwdown
//
//  Created by Andrew C on 8/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDSharePostViewController.h"
#import "TDViewControllerHelper.h"
#import "TDAnalytics.h"
#import "TDConstants.h"
#import "TDCurrentUser.h"
#import "TDShareViewCell.h"
#import "TDAppDelegate.h"
#import "TDPostAPI.h"
#import "TDActivityIndicator.h"
#import <FacebookSDK/FacebookSDK.h>
#import "TWTAPIManager.h"

@interface TDSharePostViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBarItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;

@property (nonatomic) BOOL shareToFacebook;
@property (nonatomic) BOOL shareToTwitter;
@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *comment;
@property (nonatomic) BOOL isPR;
@property (nonatomic) BOOL userGenerated;

@property (nonatomic) ACAccountStore *accountStore;
@property (nonatomic) TWTAPIManager *apiManager;
@property (nonatomic) NSArray *accounts;

@end

@implementation TDSharePostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TDAnalytics sharedInstance] logEvent:@"camera_share_with_opened"];
    UIButton *button = [TDViewControllerHelper navBackButton];
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    [self.navigationBar setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontRegularSized:20],
                                                  NSForegroundColorAttributeName: [TDConstants headerTextColor] }];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.shareToFacebook = NO;
    self.shareToTwitter = NO;
}

- (void)backButtonPressed {
    [self performSegueWithIdentifier:@"ReturnToComposeView" sender:nil];
}

# pragma mark - setting data from previous controller

- (void)setValuesForSharing:(NSString *)filename withComment:(NSString *)comment isPR:(BOOL)isPR userGenerated:(BOOL)ug {
    self.filename = filename;
    self.comment = comment;
    self.isPR = isPR;
    self.userGenerated = ug;
}

- (IBAction)saveButtonPressed:(id)sender {
    NSMutableArray *shareOptions = [[NSMutableArray alloc] init];
    if (self.shareToFacebook) {
        [shareOptions addObject:@"facebook"];
    }
    if (self.shareToTwitter) {
        [shareOptions addObject:@"twitter"];
    }
    if (self.filename) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadComments
                                                            object:nil
                                                          userInfo:@{ @"filename":self.filename,
                                                                      @"comment":self.comment,
                                                                      @"pr": [NSNumber numberWithBool:self.isPR],
                                                                      @"userGenerated": [NSNumber numberWithBool:self.userGenerated],
                                                                      @"shareOptions": shareOptions
                                                                      }];
    } else {
        [[TDPostAPI sharedInstance] addTextPost:self.comment isPR:self.isPR shareOptions:shareOptions];
    }
    if (self.isPR) {
        [self performSegueWithIdentifier:@"PRSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"VideoCloseSegue" sender:self];
    }

    [[TDAnalytics sharedInstance] logEvent:@"camera_shared"];
}

#pragma mark - TableViewDelegates

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40.0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(18, 15, 320, 18)];
    label.font = [TDConstants fontRegularSized:15.0];
    label.textColor = [TDConstants headerTextColor];

    switch (section) {
        case 0:
            label.text = @"SOCIAL";
            break;
    }

    [header addSubview:label];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.;
}

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
    TDShareViewCell *cell = (TDShareViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TDShareViewCell"];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDShareViewCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.titleLabel.font = [TDConstants fontRegularSized:18];
    }

    switch (indexPath.row) {
        case 0:
            cell.titleLabel.text  = [TDCurrentUser sharedInstance].twitterIdentifier ? [TDCurrentUser sharedInstance].twitterIdentifier : @"Twitter";
            cell.iconView.image   = [UIImage imageNamed:@"twitter_active_48x38"];
            cell.buttonView.image = [UIImage imageNamed:(self.shareToTwitter ? @"checkbox_on" : @"checkbox")];
            break;
        case 1:
            cell.titleLabel.text  = [TDCurrentUser sharedInstance].fbIdentifier ? [TDCurrentUser sharedInstance].fbIdentifier : @"Facebook";
            cell.iconView.image   = [UIImage imageNamed:@"fb_active_48x48"];
            cell.buttonView.image = [UIImage imageNamed:(self.shareToFacebook ? @"checkbox_on" : @"checkbox")];
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0:
            if (self.shareToTwitter) {
                self.shareToTwitter = NO;
                [self.tableView reloadData];
            } else if ([[TDCurrentUser sharedInstance] canPostToTwitter]) {
                self.shareToTwitter = YES;
                [self.tableView reloadData];
            } else {
                [self connectToTwitter];
            }
            break;
        case 1:
            if (self.shareToFacebook) {
                self.shareToFacebook = NO;
                [self.tableView reloadData];
            } else {
                // first check the cached permission
                if ([[TDCurrentUser sharedInstance] canPostToFacebook]) {
                    self.shareToFacebook = YES;
                    [self.tableView reloadData];
                } else if (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
                    [self checkFacebookPermissions];
                } else {
                    [self loginToFacebook];
                }
            }
            break;
    }
}

- (void)checkFacebookPermissions {
    [self.activityIndicator startSpinnerWithMessage:@"Checking permissions"];
    [FBRequestConnection startWithGraphPath:@"/me/permissions" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSDictionary *permissions= [(NSArray *)[result data] objectAtIndex:0];
            if (![permissions objectForKey:@"publish_actions"]) {
                [self.activityIndicator setMessage:@"Requesting permissions"];
                [FBSession.activeSession requestNewPublishPermissions:@[@"", @"publish_actions"]
                                                      defaultAudience:FBSessionDefaultAudienceFriends
                                                    completionHandler:^(FBSession *session, NSError *error) {
                                                        [self.activityIndicator stopSpinner];
                                                        if (!error) {
                                                            if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
                                                                [self setFacebookPermission:NO];
                                                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Error"
                                                                                                                message:@"Sharing permissions must be granted to share to Facebook. Please try again."
                                                                                                               delegate:nil
                                                                                                      cancelButtonTitle:@"OK"
                                                                                                      otherButtonTitles:nil];
                                                                [alert show];
                                                            } else {
                                                                [self setFacebookPermission:YES];
                                                            }
                                                      } else {
                                                          // See: https://developers.facebook.com/docs/ios/errors
                                                          NSLog(@"FB::Error %@", error.description);
                                                          [self setFacebookPermission:NO];
                                                          [self showFacebookError];
                                                      }
                                                  }];
            } else {
                [self.activityIndicator stopSpinner];
                [self setFacebookPermission:YES];
            }
        } else {
            // See: https://developers.facebook.com/docs/ios/errors
            NSLog(@"FB::Error %@", error.description);
            [self.activityIndicator stopSpinner];
            [self setFacebookPermission:NO];
            [self showFacebookError];
        }
    }];
}

- (void)loginToFacebook {
    // TODO: listen for app became active and remove the activity indicator - this happens if user leaves fb and comes back without clicking buttons
    [self.activityIndicator startSpinnerWithMessage:@"Connecting"];
    [FBSession openActiveSessionWithPublishPermissions:@[@"public_profile", @"publish_actions"]
                                       defaultAudience:FBSessionDefaultAudienceFriends
                                          allowLoginUI:YES
                                     completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {

         // First let the app delegate handle the response
         [[TDAppDelegate appDelegate] sessionStateChanged:session state:state error:error success:^{
             [self.activityIndicator stopSpinner];
             if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
                 [self setFacebookPermission:NO];
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Error"
                                                                 message:@"Sharing permissions must be granted to share to Facebook. Please try again."
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
                 [alert show];
             } else {
                 [self.activityIndicator showMessage:@"Connected" forSeconds:1.];
                 [self setFacebookPermission:YES];
             }
         } failure:^(NSString *error) {
             [self.activityIndicator stopSpinner];
             if (error) {
                 [self.activityIndicator showMessage:error forSeconds:1.5];
             }
             [self setFacebookPermission:NO];
         }];
     }];
}

- (void)showFacebookError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook Error"
                                                    message:@"Sorry, something went wrong when communicating with Facebook. Please try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)setFacebookPermission:(BOOL)on {
    self.shareToFacebook = on;
    [[TDCurrentUser sharedInstance] setFbPublishPermission:on];
    [self.tableView reloadData];
}



#pragma mark - Twitter connection

- (void)connectToTwitter {
    if (![TWTAPIManager isLocalTwitterAccountAvailable]) {
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
                if (success) {
                    [self.activityIndicator stopSpinner];
                    self.shareToTwitter = YES;
                    [self.tableView reloadData];
                } else {
                    [self showUnknownError];
                }
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
