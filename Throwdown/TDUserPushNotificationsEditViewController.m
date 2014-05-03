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

@implementation TDUserPushNotificationsEditViewController

@synthesize pushSettingsDict;
@synthesize headerView;

- (void)dealloc {
    self.pushSettingsDict = nil;
    self.headerView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    statusBarFrame = [self.view convertRect: [UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.titleLabel.text = @"Push Notifications";
    self.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:20.0];
    [self.navigationItem setTitleView:self.titleLabel];

    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    self.activityIndicator.text.text = @"Getting Settings";
    [self showActivity];

    [[TDAPIClient sharedInstance] getPushNotificationSettingsForUserToken:[TDCurrentUser sharedInstance].authToken success:^(NSDictionary *pushNotifications) {

        if ([pushNotifications isKindOfClass:[NSDictionary class]]) {
            self.pushSettingsDict = [pushNotifications mutableCopy];
            gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];
        }

    } failure:^{
        debug NSLog(@"error on push notifications");
        gotFromServer = NO;
        [self.tableView reloadData];
        [self hideActivity];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)backButtonHit:(id)sender {
    self.activityIndicator.text.text = @"Saving Settings";
    [self showActivity];

    [[TDAPIClient sharedInstance] sendPushNotificationSettings:self.pushSettingsDict callback:^(BOOL success) {
        if (success) {
            [self hideActivity];
            [self leave];
        } else {
            [self.tableView reloadData];
            [self hideActivity];

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Push Settings"
                                                            message:@"Something went wrong, please try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

-(void)leave
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - AlertView
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
}

#pragma mark - TableView Delegates
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    self.sectionHeaderLabel.text = @"Get Push Notification When Someone:";
    self.sectionHeaderLabel.font = [UIFont fontWithName:TDFontProximaNovaRegular size:15.0];
    self.sectionHeaderLabel.textColor = [TDConstants headerTextColor]; // 4c4c4c

    if (!self.headerView) {
        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0,
                                                                   0.0,
                                                                   self.view.frame.size.width,
                                                                   40.0)];
        CGRect headerLabelFrame = self.sectionHeaderLabel.frame;
        headerLabelFrame.origin.x = 5.0;
        headerLabelFrame.origin.y = 12.0;
        self.sectionHeaderLabel.frame = headerLabelFrame;
        [self.headerView addSubview:self.sectionHeaderLabel];
    }
    return self.headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    TDPushEditCell *cell = (TDPushEditCell*)[tableView dequeueReusableCellWithIdentifier:@"TDPushEditCell"];

    if (!cell) {

        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDPushEditCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }

    cell.rowNumber = indexPath.row;
    cell.longTitleLabel.text = @"";
    cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                       [self tableView:self.tableView heightForRowAtIndexPath:indexPath],
                                       cell.bottomLine.frame.size.width,
                                       cell.bottomLine.frame.size.height);
    cell.longTitleLabel.frame = CGRectMake(cell.longTitleLabel.frame.origin.x,
                                           cell.longTitleLabel.frame.origin.y,
                                           cell.longTitleLabel.frame.size.width,
                                           [self tableView:self.tableView heightForRowAtIndexPath:indexPath]);
    cell.aSwitch.hidden = NO;
    if (!gotFromServer) {
        cell.aSwitch.hidden = YES;
    }

    switch (indexPath.row) {
        case 0:
        {
            cell.longTitleLabel.text = @"Mentions you";
            if ([self.pushSettingsDict objectForKey:@"mentions"]) {
                cell.aSwitch.on = [[self.pushSettingsDict objectForKey:@"mentions"] boolValue];
            }
        }
            break;
        case 1:
        {
            cell.longTitleLabel.text = @"Likes your post";
            if ([self.pushSettingsDict objectForKey:@"post_likes"]) {
                cell.aSwitch.on = [[self.pushSettingsDict objectForKey:@"post_likes"] boolValue];
            }
        }
            break;
        case 2:
        {
            cell.longTitleLabel.text = @"Comments on your post";
            if ([self.pushSettingsDict objectForKey:@"post_comments"]) {
                cell.aSwitch.on = [[self.pushSettingsDict objectForKey:@"post_comments"] boolValue];
            }
        }
            break;
        case 3:
        {
            cell.longTitleLabel.text = @"Comments on a post you've\ncommented on";
            if ([self.pushSettingsDict objectForKey:@"comment_followup"]) {
                cell.aSwitch.on = [[self.pushSettingsDict objectForKey:@"comment_followup"] boolValue];
            }
        }
            break;

        default:
            break;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 3) {
        return 58.0;
    }
    return 42.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - TDPushEdit Cell delegate
-(void)switchOnFromRow:(NSInteger)row
{
    switch (row) {
        case 0:
        {
            [self.pushSettingsDict setObject:[NSNumber numberWithBool:YES]
                                      forKey:@"mentions"];
        }
            break;
        case 1:
        {
            [self.pushSettingsDict setObject:[NSNumber numberWithBool:YES]
                                      forKey:@"post_likes"];
        }
            break;
        case 2:
        {
            [self.pushSettingsDict setObject:[NSNumber numberWithBool:YES]
                                      forKey:@"post_comments"];
        }
            break;
        case 3:
        {
            [self.pushSettingsDict setObject:[NSNumber numberWithBool:YES]
                                      forKey:@"comment_followup"];
        }
            break;

        default:
            break;
    }

    debug NSLog(@"DICT:%@", self.pushSettingsDict);
}

-(void)switchOffFromRow:(NSInteger)row
{
    switch (row) {
        case 0:
        {
            [self.pushSettingsDict setObject:[NSNumber numberWithBool:NO]
                                      forKey:@"mentions"];
        }
            break;
        case 1:
        {
            [self.pushSettingsDict setObject:[NSNumber numberWithBool:NO]
                                      forKey:@"post_likes"];
        }
            break;
        case 2:
        {
            [self.pushSettingsDict setObject:[NSNumber numberWithBool:NO]
                                      forKey:@"post_comments"];
        }
            break;
        case 3:
        {
            [self.pushSettingsDict setObject:[NSNumber numberWithBool:NO]
                                      forKey:@"comment_followup"];
        }
            break;

        default:
            break;
    }

    debug NSLog(@"DICT:%@", self.pushSettingsDict);
}

#pragma mark - Activity
-(void)showActivity
{
    self.backButton.enabled = NO;
    self.activityIndicator.center = self.view.center;
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

-(void)hideActivity
{
    self.backButton.enabled = YES;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
}

@end
