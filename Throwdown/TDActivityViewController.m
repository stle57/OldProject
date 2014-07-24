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

@interface TDActivityViewController () <UITableViewDataSource, UITableViewDelegate, TDActivitiesCellDelegate>

@property (nonatomic) NSArray *activities;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;

@end

@implementation TDActivityViewController

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (![MFMailComposeViewController canSendMail]) {
        self.feedbackButton.hidden = YES;
    }

    CGRect frame = self.tableView.frame;
    frame.size.height = [UIScreen mainScreen].bounds.size.height - (self.feedbackButton.hidden ? 0 : self.feedbackButton.frame.size.height);
    self.tableView.frame = frame;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.activities = @[];
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [UIColor colorWithRed:.223529412 green:.223529412 blue:.223529412 alpha:1.0],
                                                                    NSFontAttributeName: [TDConstants fontRegularSized:18.0]
                                                                    };

    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlUsed) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor blackColor]];
    [self.tableView addSubview:self.refreshControl];

    [self refresh];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
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
    cell.activity = [self.activities objectAtIndex:indexPath.row];
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
    // Reset app badge count
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    // Reset feed button count
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdate
                                                        object:self
                                                      userInfo:@{@"notificationCount": @0}];


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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *postId = [[[self.activities objectAtIndex:indexPath.row] valueForKey:@"post"] valueForKey:@"id"];
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil];
    vc.postId = postId;
    [self.navigationController pushViewController:vc animated:YES];
    [self updateActivityAsClicked:indexPath];
}

#pragma mark - TDActivitiesCellDelegate

- (void)userProfilePressedWithId:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil];
    vc.userId = userId;
    vc.fromProfileType = kFromProfileScreenType_OtherUser;

    [self.navigationController pushViewController:vc animated:YES];
}
- (void)activityPressedFromRow:(NSNumber *)row {
    [self updateActivityAsClicked:[NSIndexPath indexPathForRow:[row integerValue] inSection:0]];
}

- (void)updateActivityAsClicked:(NSIndexPath *)indexPath {
    if ([[self.activities objectAtIndex:indexPath.row] objectForKey:@"id"]) {
        [[TDAPIClient sharedInstance] updateActivity:[[self.activities objectAtIndex:indexPath.row] objectForKey:@"id"] seen:NO clicked:YES];
        TDActivitiesCell *cell = (TDActivitiesCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
}

#pragma mark - support unwinding on push notification

- (void)unwindToRoot {
    debug NSLog(@"unwind from activity");
    // Looks weird but ensures the profile closes on both own profile page and when tapped from feed
    [self.navigationController popViewControllerAnimated:NO];
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Feedback
- (IBAction)feedbackButton:(id)sender {
    [self displayFeedbackEmail];
}

- (NSString *) platform{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *machine = malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	free(machine);
	return platform;
}

- (void)displayFeedbackEmail {
    if (![MFMailComposeViewController canSendMail]) {
        // can't send email, don't try!
        return;
    }
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    [picker setSubject:@"Throwdown Feedback"];

    // Set up the recipients.
    NSArray *toRecipients = [NSArray arrayWithObjects:@"feedback@throwdown.us",
                             nil];

    [picker setToRecipients:toRecipients];

    // Fill out the email body text.
    NSMutableString *emailBody = [NSMutableString string];
    [emailBody appendString:[NSString stringWithFormat:@"Thanks for using Throwdown! We appreciate any thoughts you have on making it better or if you found a bug, let us know here."]];

    [emailBody appendString:[NSString stringWithFormat:@"\n\n\n\n\nApp Version:%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    [emailBody appendString:[NSString stringWithFormat:@"\nApp Build #:%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
    [emailBody appendString:[NSString stringWithFormat:@"\nOS:%@", [[UIDevice currentDevice] systemVersion]]];
    [emailBody appendString:[NSString stringWithFormat:@"\nModel:%@", [self platform]]];
    [emailBody appendString:[NSString stringWithFormat:@"\nID:%@", [TDCurrentUser sharedInstance].userId]];
    [emailBody appendString:[NSString stringWithFormat:@"\nName:%@", [TDCurrentUser sharedInstance].username]];

    [picker setMessageBody:emailBody isHTML:NO];

    // Present the mail composition interface.
    if (picker) {
        [self presentViewController:picker animated:YES completion:nil];
    }
}

// The mail compose view controller delegate method
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

@end
