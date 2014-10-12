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


static CGFloat const kMinRowHeight = 42.;

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

@end


@implementation TDUserPushNotificationsEditViewController

- (void)dealloc {
    self.pushSettings = nil;
    self.originalSettings = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Background
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    
    // Title
    self.titleLabel.text = @"Push Notifications";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    [self.navigationItem setTitleView:self.titleLabel];

    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    
    self.tableView.backgroundColor = [TDConstants darkBackgroundColor];
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
            self.pushSettings = [@{} mutableCopy];
            for (NSDictionary *group in settings) {
                for (NSDictionary *setting in [group objectForKey:@"keys"]) {
                    [self.pushSettings addEntriesFromDictionary:@{[setting objectForKey:@"key"]: [setting objectForKey:@"value"]}];
                }
            }
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
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 35.0)];

    if (self.gotFromServer && section < [self.settings count]) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 7, SCREEN_WIDTH, 18)];
        label.text = [[self.settings objectAtIndex:section] objectForKey:@"name"];
        label.font = [TDConstants fontRegularSized:16.0];
        label.textColor = [TDConstants headerTextColor];
        [header addSubview:label];
    }

    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.;
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
    if ([[self settingFor:indexPath] objectForKey:@"options"]) {
        cell.segmentControl.hidden = NO;
        cell.aSwitch.hidden = YES;
        cell.segmentControl.selectedSegmentIndex =[[[self settingFor:indexPath] objectForKey:@"value"] integerValue];
        NSUInteger index = 0;
        for (NSString *opt in [[self settingFor:indexPath] objectForKey:@"options"]) {
            [cell.segmentControl setTitle:opt forSegmentAtIndex:index];
            index++;
        }
    } else {
        cell.segmentControl.hidden = YES;
        cell.aSwitch.hidden = NO;
        cell.aSwitch.on = [[[self settingFor:indexPath] objectForKey:@"value"] boolValue];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.gotFromServer) {
        NSString *text = [[self settingFor:indexPath] objectForKey:@"name"];
        UILabel *label = [[UILabel alloc] init];
        label.text = text;
        CGFloat height = [label sizeThatFits:CGSizeMake(242., MAXFLOAT)].height;
        return height > kMinRowHeight ? height : kMinRowHeight;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - TDPushEditCellDelegate

- (void)switchValue:(NSNumber *)value forIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [[self settingFor:indexPath] objectForKey:@"key"];
    [self.pushSettings setObject:value forKey:key];
    debug NSLog(@"DICT:%@", self.pushSettings);

}

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

@end
