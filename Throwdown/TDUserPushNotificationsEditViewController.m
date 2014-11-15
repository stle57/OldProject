//
//  TDUserPushNotificationsEditViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/30/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserPushNotificationsEditViewController.h"
#import "TDPostAPI.h"
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDComment.h"
#import "TDViewControllerHelper.h"
#import "AFNetworking.h"
#import "TDUserAPI.h"
#import "NBPhoneNumberUtil.h"
#import "TDAPIClient.h"
#import "UIAlertView+TDBlockAlert.h"
#import "TDAnalytics.h"
/*
{
settings: [
    {
    name: "Get push Notification When Someone:",
    keys: [
        {
        key: "post_likes",
        value: true,
        name: "Likes your post"
        },
        {
        key: "post_comments",
        value: true,
        name: "Comments on your post"
        },
        {
        key: "mentions",
        value: true,
        name: "Mentions you"
        },
        {
        key: "comment_followup",
        value: false,
        name: "Comments on a post you've commented on"
        }
    ]
    }
]
}
*/

@interface TDUserPushNotificationsEditViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, TDPushEditCellDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet TDActivityIndicator *activityIndicator;

@property (nonatomic) NSArray *settings;
@property (nonatomic) NSMutableDictionary *pushSettings;
@property (nonatomic) NSDictionary *originalSettings;
@property (nonatomic) BOOL gotFromServer;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) NSMutableDictionary *headerLabels;

@end


@implementation TDUserPushNotificationsEditViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.pushSettings = nil;
    self.originalSettings = nil;
    self.headerLabels = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForegroundCallback:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    // Background
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Title
    self.titleLabel.text = @"Notifications";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    [self.navigationItem setTitleView:self.titleLabel];

    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    
    self.headerLabels = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self loadSettings];
}

- (void)loadSettings {
    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    [[TDAPIClient sharedInstance] getPushNotificationSettingsForUserToken:[TDCurrentUser sharedInstance].authToken success:^(id settings) {
        if ([settings isKindOfClass:[NSArray class]]) {
            self.settings = settings;
            debug NSLog(@"settings =%@", self.settings);
            self.pushSettings = [@{} mutableCopy];
            for (NSDictionary *group in settings) {
                for (NSDictionary *setting in [group objectForKey:@"keys"]) {
                    if ([setting objectForKey:@"email"] != nil) {
                        NSString *emailStr = [NSString stringWithFormat:@"%@_email", [setting objectForKey:@"key"]];
                        NSString *pushStr = [NSString stringWithFormat:@"%@_push", [setting objectForKey:@"key"]];
                        [self.pushSettings addEntriesFromDictionary:@{emailStr: [setting objectForKey:@"email"]}];
                         [self.pushSettings addEntriesFromDictionary:@{pushStr: [setting objectForKey:@"push"]}];
                    } else {
                        NSString *pStr = [NSString stringWithFormat:@"%@_push", [setting objectForKey:@"key"]];
                        [self.pushSettings addEntriesFromDictionary:@{pStr: [setting objectForKey:@"value"]}];
                    }
                }
            }
            debug NSLog(@"pushSettings = %@", self.pushSettings);
            self.originalSettings = [self.pushSettings copy];
            self.gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];
        }
    } failure:^{
        self.gotFromServer = NO;
        [self.tableView reloadData];
        [self hideActivity];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Sorry, there was an unexpected error while loading the settings"
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Try Again", nil];
        [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (alertView.cancelButtonIndex == buttonIndex) {
                [self leave];
            } else {
                [self loadSettings];
            }
        }];
    }];
}

- (NSDictionary *)settingFor:(NSIndexPath *)indexPath {
    if (!self.gotFromServer) {
        return nil;
    }
    return [[[self.settings objectAtIndex:indexPath.section] objectForKey:@"keys"] objectAtIndex:indexPath.row];
}

- (void)backButtonHit:(id)sender {
    if ([self.pushSettings isEqualToDictionary:self.originalSettings]) {
        [self leave];
    } else {
        [self save];
    }
}

- (void)leave {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)save {
    self.activityIndicator.text.text = @"Saving";
    [self showActivity];
    [[TDAPIClient sharedInstance] sendPushNotificationSettings:self.pushSettings callback:^(BOOL success) {
        [self hideActivity];
        if (success) {
            [self leave];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"Sorry, there was an unexpected error while saving your changes"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Try Again", nil];
            [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (alertView.cancelButtonIndex == buttonIndex) {
                    [self leave];
                } else {
                    [self save];
                }
            }];
        }
    }];
}

#pragma mark - TableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *newValue = [NSString stringWithFormat:@"%ld", (long)section ];
    
    UILabel *label = [self.headerLabels valueForKey:newValue];
    
    UIView *headerView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, HEADER_TOP_MARGIN + label.frame.size.height + HEADER_BOTTOM_MARGIN)];
    [headerView addSubview:label];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *newValue = [NSString stringWithFormat:@"%ld", (long)section];
    [self createHeaderLabels:section];
    UILabel *label = [self.headerLabels valueForKey:newValue];
    debug NSLog(@"height for Header=%f in section %@", HEADER_TOP_MARGIN + label.frame.size.height + HEADER_BOTTOM_MARGIN, newValue);
    return HEADER_TOP_MARGIN + label.frame.size.height + HEADER_BOTTOM_MARGIN;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.gotFromServer) {
        return [self.settings count];
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.gotFromServer) {
        return [[[self.settings objectAtIndex:section] objectForKey:@"keys"] count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDPushEditCell *cell = (TDPushEditCell*)[tableView dequeueReusableCellWithIdentifier:@"TDPushEditCell"];

    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDPushEditCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }

    if (indexPath.row != 0) {
        cell.topLine.hidden = YES;
    }
    cell.indexPath = indexPath;
    cell.longTitleLabel.text = @"";
    cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                       [self tableView:self.tableView heightForRowAtIndexPath:indexPath],
                                       cell.bottomLine.frame.size.width,
                                       cell.bottomLine.frame.size.height);
    cell.longTitleLabel.frame = CGRectMake(cell.longTitleLabel.frame.origin.x,
                                           cell.longTitleLabel.frame.origin.y,
                                           cell.longTitleLabel.frame.size.width,
                                           [self tableView:self.tableView heightForRowAtIndexPath:indexPath]);

    cell.longTitleLabel.text = [[self settingFor:indexPath] objectForKey:@"name"];
    CGRect bottomLineFrame = cell.bottomLine.frame;
    bottomLineFrame.origin.y = [self tableView:tableView heightForRowAtIndexPath:indexPath]-.5;
    cell.bottomLine.frame = bottomLineFrame;
    if ([[self settingFor:indexPath] objectForKey:@"email"]) {
        [cell.emailButton setImage:[UIImage imageNamed:@"email-on.png"] forState:UIControlStateNormal];
    } else {
        [cell.emailButton setImage:[UIImage imageNamed:@"email-off.png"] forState:UIControlStateNormal];
    }
    if ([[self settingFor:indexPath] objectForKey:@"push"]) {
        [cell.pushButton setImage:[UIImage imageNamed:@"push-on.png"] forState:UIControlStateNormal];
    } else {
        [cell.pushButton setImage:[UIImage imageNamed:@"push-off.png"] forState:UIControlStateNormal];
    }
    if ([[self settingFor:indexPath] objectForKey:@"options"]) {
        cell.segmentControl.hidden = NO;
        cell.pushButton.hidden = YES;
        cell.emailButton.hidden = YES;
        //cell.aSwitch.hidden = YES;
        cell.segmentControl.selectedSegmentIndex =[[[self settingFor:indexPath] objectForKey:@"value"] integerValue];
        NSUInteger index = 0;
        for (NSString *opt in [[self settingFor:indexPath] objectForKey:@"options"]) {
            [cell.segmentControl setTitle:opt forSegmentAtIndex:index];
            index++;
        }
    } else {
        cell.segmentControl.hidden = YES;
        cell.pushButton.hidden = NO;
        cell.emailButton.hidden = NO;
        
        //cell.aSwitch.hidden = NO;
        //cell.aSwitch.on = [[[self settingFor:indexPath] objectForKey:@"value"] boolValue];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) createHeaderLabels:(NSInteger)section {
    NSString *sectionStr = [NSString stringWithFormat:@"%ld", (long)section ];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, SCREEN_WIDTH, 100)];
//    CGFloat lineHeight = 18.0;
//    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:[[self.settings objectAtIndex:section] objectForKey:@"name"] font:[TDConstants fontSemiBoldSized:18] color:[TDConstants commentTimeTextColor] lineHeight:lineHeight lineHeightMultipler:(lineHeight/18.0)];
    
    label.text =[[self.settings objectAtIndex:section] objectForKey:@"name"] ;
    label.font = [TDConstants fontSemiBoldSized:13];
    label.textColor = [TDConstants commentTimeTextColor];
    [label sizeToFit];
    
    debug NSLog(@"label frame=%@", NSStringFromCGRect(label.frame));
    [self.headerLabels setObject:label forKey:sectionStr];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.001;
}
#pragma mark - TDPushEditCellDelegate

- (void)switchValue:(NSNumber *)value forIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [[self settingFor:indexPath] objectForKey:@"key"];
    [self.pushSettings setObject:value forKey:[NSString stringWithFormat:@"%@_push", key]];
    debug NSLog(@"DICT:%@", self.pushSettings);

    
}

- (void)emailValue:(NSNumber *)value forIndexPath:(NSIndexPath *)indexPath {
    debug NSLog(@"inside emailValue");
    NSString *key = [NSString stringWithFormat:@"%@_email", [[self settingFor:indexPath] objectForKey:@"key"]];
    [self.pushSettings setObject:value forKey:key];
    
    TDPushEditCell *cell = (TDPushEditCell*) [self.tableView cellForRowAtIndexPath:indexPath];
    if ([[self.pushSettings objectForKey:key] boolValue]) {
        [cell.emailButton setImage:[UIImage imageNamed:@"email-on.png"] forState:UIControlStateNormal];
    } else {
        [cell.emailButton setImage:[UIImage imageNamed:@"email-off.png"] forState:UIControlStateNormal];
    }
    
    debug NSLog(@"DICT:%@", self.pushSettings);
}
- (void)pushValue:(NSNumber *)value forIndexPath:(NSIndexPath *)indexPath {
    debug NSLog(@"inside pushValue");
    if ([[TDCurrentUser sharedInstance] didAskForPush] && [[TDCurrentUser sharedInstance] isRegisteredForPush])
    {
        debug NSLog(@"   ALREADY ASKED");
        // change the value and move on
        NSString *key = [NSString stringWithFormat:@"%@_push", [[self settingFor:indexPath] objectForKey:@"key"]];
        [self.pushSettings setObject:value forKey:key];
        TDPushEditCell *cell = (TDPushEditCell*) [self.tableView cellForRowAtIndexPath:indexPath];
        if ([[self.pushSettings objectForKey:key] boolValue]) {
            [cell.pushButton setImage:[UIImage imageNamed:@"push-on.png"] forState:UIControlStateNormal];
        } else {
            [cell.pushButton setImage:[UIImage imageNamed:@"push-off.png"] forState:UIControlStateNormal];
        }
        debug NSLog(@"DICT:%@", self.pushSettings);
        return;
    }
    
    if (![[TDCurrentUser sharedInstance] didAskForPush] && ![[TDCurrentUser sharedInstance] isRegisteredForPush]) {
        // Show for prompt, user never been on this page before
        NSString * message = @"We'd like to ask for your\n permission for push notifications.\n On the next screen, please tap\n \"OK\" to give us permission.";

        [[TDAnalytics sharedInstance] logEvent:@"notification_asked"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Requested" message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ask me", nil];
        [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [[TDAnalytics sharedInstance] logEvent:@"notification_accept"];
                [[TDCurrentUser sharedInstance] registerForRemoteNotificationTypes];
                
                // Change all settings to push
                NSDictionary *dictionary = [self.pushSettings copy];
                
                for (NSString *key in dictionary) {
                    if ([key containsString:@"email"]) {
                        [self.pushSettings setValue:@0 forKey:key];
                    }
                    else if ([key containsString:@"push"]) {
                        [self.pushSettings setValue:@1 forKey:key];
                    }
                }

                for (int secNum = 0; secNum < [self.tableView numberOfSections]; secNum ++) {
                    for (int row= 0; row < [self.tableView numberOfRowsInSection:secNum]; row++) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:secNum];
                        TDPushEditCell *cell = (TDPushEditCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                        cell.pushValue=true;
                        cell.emailValue = false;
                        [cell.pushButton setImage:[UIImage imageNamed:@"push-on.png"] forState:UIControlStateNormal];
                        [cell.emailButton setImage:[UIImage imageNamed:@"email-off.png"] forState:UIControlStateNormal];
                        
                        if (!cell.segmentControl.isHidden) {
                            [cell.segmentControl setSelectedSegmentIndex:1];
                        }
                    }
                }
                debug NSLog(@"switched all settings to push %@", self.pushSettings);
            } else {
                debug NSLog(@"GOT INTO CANCEL SITUATION");
                // User hit cancel, revert the value back.
                NSString *key = [NSString stringWithFormat:@"%@_push", [[self settingFor:indexPath] objectForKey:@"key"]];
                TDPushEditCell *cell = (TDPushEditCell*) [self.tableView cellForRowAtIndexPath:indexPath];
                cell.pushValue = [[self.pushSettings objectForKey:key] boolValue];
                if ([[self.pushSettings objectForKey:key] boolValue]) {
                    [cell.pushButton setImage:[UIImage imageNamed:@"push-on.png"] forState:UIControlStateNormal];
                } else {
                    [cell.pushButton setImage:[UIImage imageNamed:@"push-off.png"] forState:UIControlStateNormal];
                }
                debug NSLog(@"DICT:%@", self.pushSettings);
                return;
            }
        }];
        
        return;

    }
    
    if ([[TDCurrentUser sharedInstance] didAskForPush] && ![[TDCurrentUser sharedInstance] isRegisteredForPush]) {
        debug NSLog(@"showing alert");
        // Show an alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Push Notifications"
                                                        message:@"Enable push notifications in Settings App > Notifications > Throwdown"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
}

//- (void)emailValue:(NSNumber *)value forIndexPath:(NSIndexPath *)indexPath {
//    debug NSLog(@"inside emailValue");
//    NSString *key = [[self settingFor:indexPath] objectForKey:@"key"];
//    [self.pushSettings setObject:value forKey:key];
//    debug NSLog(@"DICT:%@", self.pushSettings);
//}
//- (void)pushValue:(NSNumber *)value forIndexPath:(NSIndexPath *)indexPath {
//    debug NSLog(@"inside pushValue");
//    NSString *key = [[self settingFor:indexPath] objectForKey:@"key"];
//    [self.pushSettings setObject:value forKey:key];
//    debug NSLog(@"DICT:%@", self.pushSettings);
//}

#pragma mark - Activity

- (void)showActivity {
    self.backButton.enabled = NO;
    self.activityIndicator.center = [TDViewControllerHelper centerPosition];
    
    CGPoint centerFrame = self.activityIndicator.center;
    centerFrame.y = self.activityIndicator.center.y - self.activityIndicator.backgroundView.frame.size.height/2;
    self.activityIndicator.center = centerFrame;
    
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivity {
    self.backButton.enabled = YES;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
}

#pragma  mark - NSNotification
- (void)willEnterForegroundCallback:(NSNotification *)notification {
    debug NSLog(@"got into the callback");
    [self.tableView reloadData];
}
@end
