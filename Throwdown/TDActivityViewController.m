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
#import "TDFeedbackViewController.h"

static NSString *const kActivityCell = @"TDActivitiesCell";

@interface TDActivityViewController () <UITableViewDataSource, UITableViewDelegate, TDActivitiesCellDelegate>

@property (nonatomic) NSArray *activities;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableBottomOffset;
@property (nonatomic, retain) TDFeedbackViewController *feedbackViewController;
@property (retain) UIView *disableViewOverlay;
@end

@implementation TDActivityViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.feedbackViewController = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (![MFMailComposeViewController canSendMail]) {
        self.feedbackButton.hidden = YES;
        self.tableBottomOffset.constant = 0;
    } else {
        self.feedbackButton.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    }

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.activities = @[];
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                    NSFontAttributeName: [TDConstants fontSemiBoldSized:18.0]
                                                                    };

    // Background
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    navigationBar.barStyle = UIBarStyleBlack;
    navigationBar.translucent = NO;

    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlUsed) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl setTintColor:[UIColor blackColor]];
    [self.tableView addSubview:self.refreshControl];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animateHide) name:TDRemoveRateView object:nil];
    self.disableViewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0.0f,0,SCREEN_WIDTH,SCREEN_HEIGHT)];
    self.disableViewOverlay.backgroundColor=[UIColor blackColor];
    self.disableViewOverlay.alpha = 0;
    
    [self refresh];
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

    if ([self.activities count] > indexPath.row) {
        cell.activity = [self.activities objectAtIndex:indexPath.row];
        cell.row = indexPath.row;
    }

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
    if (indexPath.row > [self.activities count]) {
        return;
    }
    NSDictionary *activity = [self.activities objectAtIndex:indexPath.row];
    [self updateActivityAsClicked:indexPath];

    if ([activity valueForKey:@"post"]) {
        NSNumber *postId = [[activity valueForKey:@"post"] valueForKey:@"id"];
        TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil];
        vc.postId = postId;
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([activity valueForKey:@"user"]) {
        NSNumber *userId = [[activity valueForKey:@"user"] valueForKey:@"id"];
        TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
        vc.userId = userId;
        vc.profileType = kFeedProfileTypeOther;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - TDActivitiesCellDelegate

- (void)userProfilePressedWithId:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil];
    vc.userId = userId;
    vc.profileType = kFeedProfileTypeOther;

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
    [self displayFeedbackViewController];
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

- (void)displayFeedbackViewController {
    
    [self addOverlay];
    self.feedbackViewController = [[TDFeedbackViewController alloc] initWithNibName:@"TDFeedbackViewController" bundle:nil ];
    
    CGRect feedbackFrame = self.feedbackViewController.view.frame;
    feedbackFrame.origin.x = self.view.frame.size.width/2 - self.feedbackViewController.view.frame.size.width/2;
    feedbackFrame.origin.y = (self.view.frame.size.height/2  - self.feedbackViewController.view.frame.size.height/2) - ([UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height/2);
    self.feedbackViewController.view.frame = feedbackFrame;
    [self.view addSubview:self.feedbackViewController.view];
    
}

// The mail compose view controller delegate method
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void) animateHide {
    //[self.feedbackViewController.view removeFromSuperview];
    [self removeOverlay];
}

- (void)addOverlay {
    
    self.disableViewOverlay.alpha = 0;
    [self.view addSubview:self.disableViewOverlay];
    
    [UIView beginAnimations:@"FadeIn" context:nil];
    [UIView setAnimationDuration:0.5];
    self.disableViewOverlay.alpha = 0.6;
    [UIView commitAnimations];
    
}

- (void)removeOverlay {
    [self.disableViewOverlay removeFromSuperview];
}

@end
