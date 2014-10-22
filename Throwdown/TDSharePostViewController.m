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
#import "TDRadioButtonRowCell.h"
#import "TDAppDelegate.h"
#import "TDPostAPI.h"
#import "TDActivityIndicator.h"
#import <FacebookSDK/FacebookSDK.h>
#import "TWTAPIManager.h"

typedef NS_ENUM(NSUInteger, TDPostPrivacy) {
    TDPostPrivacyPublic,
    TDPostPrivacyPrivate
};

static NSString *const kFacebookShareKey = @"TDLastShareToFacebook";
static NSString *const kTwitterShareKey = @"TDLastShareToTwitter";

@interface TDSharePostViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBarItem;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (nonatomic) BOOL shareToFacebook;
@property (nonatomic) BOOL shareToTwitter;
@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *comment;
@property (nonatomic) BOOL isPR;
@property (nonatomic) BOOL userGenerated;
@property (nonatomic) TDPostPrivacy privacy;

@property (nonatomic) ACAccountStore *accountStore;
@property (nonatomic) TWTAPIManager *apiManager;
@property (nonatomic) NSArray *accounts;

@end

@implementation TDSharePostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TDAnalytics sharedInstance] logEvent:@"camera_share_with_opened"];

    // Background
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];

    UIButton *button = [TDViewControllerHelper navBackButton];
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barStyle = UIBarStyleBlack;
    navigationBar.translucent = NO;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontSemiBoldSized:18],
                                             NSForegroundColorAttributeName: [UIColor whiteColor] }];


    [self.saveButton setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[TDConstants fontRegularSized:18] } forState:UIControlStateNormal];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.shareToFacebook = ([[TDCurrentUser sharedInstance] canPostToFacebook] && [[[NSUserDefaults standardUserDefaults] objectForKey:kFacebookShareKey] boolValue]);
    self.shareToTwitter = ([[TDCurrentUser sharedInstance] canPostToTwitter] && [[[NSUserDefaults standardUserDefaults] objectForKey:kTwitterShareKey] boolValue]);
    self.privacy = TDPostPrivacyPublic;
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
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kFacebookShareKey];
    } else if ([[TDCurrentUser sharedInstance] canPostToFacebook]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:kFacebookShareKey];
    }
    if (self.shareToTwitter) {
        [shareOptions addObject:@"twitter"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kTwitterShareKey];
    } else if ([[TDCurrentUser sharedInstance] canPostToTwitter]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:kTwitterShareKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (self.filename) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadComments
                                                            object:nil
                                                          userInfo:@{ @"filename":self.filename,
                                                                      @"comment":self.comment,
                                                                      @"pr": [NSNumber numberWithBool:self.isPR],
                                                                      @"userGenerated": [NSNumber numberWithBool:self.userGenerated],
                                                                      @"shareOptions": shareOptions,
                                                                      @"private": [NSNumber numberWithBool:(self.privacy == TDPostPrivacyPrivate)]
                                                                      }];
    } else {
        [[TDPostAPI sharedInstance] addTextPost:self.comment isPR:self.isPR isPrivate:(self.privacy == TDPostPrivacyPrivate) shareOptions:shareOptions];
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
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, section == 1 ? 40 : 20)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(18, 18, SCREEN_WIDTH, 18)];
    label.font = [TDConstants fontSemiBoldSized:14];
    label.textColor = [TDConstants helpTextColor];

    switch (section) {
        case 0:
            label.text = @"";
            break;
        case 1:
            label.text = @"SOCIAL";
            break;
    }

    [header addSubview:label];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 1 ? 40 : 20;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 42.;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *finalCell;
    if (indexPath.section == 0) {
        TDRadioButtonRowCell *cell = (TDRadioButtonRowCell *)[tableView dequeueReusableCellWithIdentifier:@"TDRadioButtonRowCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDRadioButtonRowCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }
        switch (indexPath.row) {
            case 0:
                cell.titleLabel.text = @"Everyone";
                cell.icon.hidden = YES;
                cell.checkmark.hidden = (self.privacy != TDPostPrivacyPublic);
                break;
            case 1:
                cell.titleLabel.text = @"Just me";
                CGFloat width = [TDAppDelegate widthOfTextForString:cell.titleLabel.text
                                                            andFont:cell.titleLabel.font
                                                            maxSize:CGSizeMake(MAXFLOAT, cell.titleLabel.frame.size.height)];
                CGRect frame = cell.icon.frame;
                frame.origin.x = cell.titleLabel.frame.origin.x + width + 6;
                cell.icon.frame = frame;
                cell.icon.hidden = NO;
                cell.checkmark.hidden = (self.privacy != TDPostPrivacyPrivate);
                break;
        }
        finalCell = cell;
    } else {
        TDShareViewCell *cell = (TDShareViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TDShareViewCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDShareViewCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
        }
        switch (indexPath.row) {
            case 0:
                cell.titleLabel.text  = [TDCurrentUser sharedInstance].twitterIdentifier ? [TDCurrentUser sharedInstance].twitterIdentifier : @"Twitter";
                cell.iconView.image   = [UIImage imageNamed:([TDCurrentUser sharedInstance].twitterIdentifier ? @"twitter_active_48x38" : @"twitter_inactive_48x38")];
                cell.buttonView.image = [UIImage imageNamed:(self.shareToTwitter ? @"checkbox_on" : @"checkbox")];
                break;
            case 1:
                cell.titleLabel.text  = [TDCurrentUser sharedInstance].fbIdentifier ? [TDCurrentUser sharedInstance].fbIdentifier : @"Facebook";
                cell.iconView.image   = [UIImage imageNamed:([TDCurrentUser sharedInstance].fbIdentifier ? @"fb_active_48x48" : @"fb_inactive_48x48")];
                cell.buttonView.image = [UIImage imageNamed:(self.shareToFacebook ? @"checkbox_on" : @"checkbox")];
                break;
        }
        finalCell = cell;
    }
    return finalCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        BOOL reload = NO;
        switch (indexPath.row) {
            case 0:
                reload = (self.privacy != TDPostPrivacyPublic);
                self.privacy = TDPostPrivacyPublic;
                break;
            case 1:
                reload = (self.privacy != TDPostPrivacyPrivate);
                self.privacy = TDPostPrivacyPrivate;
                break;
        }
        if (reload) {
            [self.tableView reloadData];
        }
    } else {
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
                    } else if ([TDCurrentUser sharedInstance].fbUID && (FBSession.activeSession.state == FBSessionStateOpen || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)) {
                        [self checkFacebookPermissions];
                    } else if ([[TDCurrentUser sharedInstance] hasCachedFacebookToken]) {
                        [[TDCurrentUser sharedInstance] authenticateFacebookWithCachedToken:^(BOOL success) {
                            if (success) {
                                [self checkFacebookPermissions];
                            } else {
                                [self loginToFacebook];
                            }
                        }];
                    } else {
                        [self loginToFacebook];
                    }
                }
                break;
        }
    }
}

- (void)checkFacebookPermissions {
    [self.activityIndicator startSpinnerWithMessage:@"Checking permissions"];
    [FBRequestConnection startWithGraphPath:@"/me/permissions" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            NSDictionary *permissions= [(NSArray *)[result data] objectAtIndex:0];
            if (![permissions objectForKey:@"publish_actions"]) {
                [self.activityIndicator setMessage:@"Requesting permissions"];
                [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForegroundCallback:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [self.activityIndicator startSpinnerWithMessage:@"Connecting"];
    [[TDAnalytics sharedInstance] logEvent:@"facebook_request"];
    [FBSession openActiveSessionWithPublishPermissions:@[@"public_profile", @"publish_actions"]
                                       defaultAudience:FBSessionDefaultAudienceFriends
                                          allowLoginUI:YES
                                     completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {

         // First let the app delegate handle the response
         [[TDAppDelegate appDelegate] sessionStateChanged:session state:state error:error success:^{
             [self.activityIndicator stopSpinner];
             if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
                 [[TDAnalytics sharedInstance] logEvent:@"facebook_missing_permissions"];
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

- (void)willEnterForegroundCallback:(NSNotification *)notification {
    [self.activityIndicator stopSpinner];
    [[TDAnalytics sharedInstance] logEvent:@"facebook_returned"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
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
    [[TDCurrentUser sharedInstance] updateFacebookPermissions];
    [self.tableView reloadData];
}



#pragma mark - Twitter connection

- (void)connectToTwitter {
    if (![TWTAPIManager isLocalTwitterAccountAvailable]) {
        // TODO: open up twitter auth in webview
        [[TDAnalytics sharedInstance] logEvent:@"twitter_no_users"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"You have to add an account to the iOS Settings app first." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        if (!self.accountStore) {
            self.accountStore =  [[ACAccountStore alloc] init];
        }
        [self.activityIndicator startSpinnerWithMessage:@"Connecting"];
        [[TDAnalytics sharedInstance] logEvent:@"twitter_request"];
        ACAccountType *twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [self.accountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {
            if (granted) {
                [[TDAnalytics sharedInstance] logEvent:@"twitter_accepted" withInfo:[NSString stringWithFormat:@"%lu", (unsigned long)[self.accounts count]] source:nil];
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
                [[TDAnalytics sharedInstance] logEvent:@"twitter_denied"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopSpinner];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                    message:@"Please enable Twitter for Throwdown in iOS Settings > Privacy > Twitter"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                });
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
                    if (success) {
                        [self.activityIndicator stopSpinner];
                        [self.activityIndicator showMessage:@"Connected" forSeconds:1.];
                        self.shareToTwitter = YES;
                        [self.tableView reloadData];
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
            [[TDAnalytics sharedInstance] logEvent:@"error" withInfo:[error localizedDescription] source:@"TDSharePostViewController#performReverseAuthForAccount"];
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
