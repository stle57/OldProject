//
//  TDHomeViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDHomeViewController.h"
#import "TDAppDelegate.h"
#import "TDPostAPI.h"
#import "TDAPIClient.h"
#import "TDPostUpload.h"
#import "TDConstants.h"
#import "TDUserAPI.h"
#import "VideoButtonSegue.h"
#import "TDHomeHeaderView.h"
#import "TDActivityCell.h"
#import "TDUserProfileViewController.h"
#import "TDNavigationController.h"
#import "TDFileSystemHelper.h"
#import "UIAlertView+TDBlockAlert.h"
#import <QuartzCore/QuartzCore.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *badgeCountLabel;
@property (nonatomic) NSNumber *badgeCount;

@property (nonatomic) BOOL didUpload;

@end

@implementation TDHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStarted:) name:TDPostUploadStarted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPostsNotification:) name:TDNotificationUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadHome:) name:TDNotificationReloadHome object:nil];

    [self.badgeCountLabel setFont:[TDConstants fontSemiBoldSized:11]];
    [self.badgeCountLabel.layer setCornerRadius:9.0];

    // Fix buttons for 3.5" screens
    int screenHeight = [UIScreen mainScreen].bounds.size.height;
    self.recordButton.center = CGPointMake(self.recordButton.center.x, screenHeight - self.recordButton.frame.size.height / 2.0);
    self.profileButton.center = CGPointMake(self.profileButton.center.x, screenHeight - self.profileButton.frame.size.height / 2.0);
    self.badgeCountLabel.center = CGPointMake(self.badgeCountLabel.center.x, screenHeight - 45);
    self.notificationButton.center = CGPointMake(self.notificationButton.center.x, screenHeight - self.notificationButton.frame.size.height / 2.0);
    origRecordButtonCenter = self.recordButton.center;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:NO];

    // Frosted behind status bar
    [self addFrostedBehindForStatusBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (goneDownstream) {
        [self animateButtonsOnToScreen];
    }
    goneDownstream = NO;

    if (self.didUpload) {
        self.didUpload = NO;
        [[TDCurrentUser sharedInstance] registerForPushNotifications:@"Would you like to be notified of feedback?"];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self removeFrostedView];
}

- (void)viewDidLayoutSubviews {
    if (goneDownstream) {
        [self hideBottomButtons];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Posts

- (TDPost *)postForRow:(NSInteger)row {
    NSInteger realRow = row - [self noticeCount];
    if (realRow < self.posts.count) {
        return [self.posts objectAtIndex:realRow];
    } else {
        return nil;
    }
}

- (void)reloadHome:(NSNotification *)notification {
    [self fetchPostsUpStream];
}

- (NSUInteger)noticeCount {
    return [[TDPostAPI sharedInstance] noticeCount];
}

- (void)fetchPostsUpStream {
    [[TDPostAPI sharedInstance] fetchPostsUpstreamWithErrorHandlerStart:nil success:^(NSDictionary *response) {
        self.loaded = YES;
        self.errorLoading = NO;
        self.posts = [[TDPostAPI sharedInstance] getPosts];
        if ([response valueForKey:@"next_start"] == [NSNull null]) {
            noMorePostsAtBottom = YES;
        }
    } error:^{
        self.loaded = YES;
        self.errorLoading = YES;
        [self endRefreshControl];
        [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastIconType_Warning payload:@{} delegate:nil];
        [self.tableView reloadData];
    }];
}

- (BOOL)fetchPostsDownStream {
    if (noMorePostsAtBottom) {
        return NO;
    }
    [[TDPostAPI sharedInstance] fetchPostsUpstreamWithErrorHandlerStart:[super lowestIdOfPosts] success:^(NSDictionary *response) {
        self.posts = [[TDPostAPI sharedInstance] getPosts];
        if ([response valueForKey:@"next_start"] == [NSNull null]) {
            noMorePostsAtBottom = YES;
        }
    } error:nil];
    return YES;
}

- (NSArray *)postsForThisScreen {
    return self.posts;
}

#pragma mark - Refresh Control
- (void)refreshControlUsed {
    debug NSLog(@"home-refreshControlUsed");
    [[TDPostAPI sharedInstance] fetchPostsUpstreamWithErrorHandlerStart:nil error:^{
        [self endRefreshControl];
        [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastIconType_Warning payload:@{} delegate:nil];
    }];
}

#pragma mark - Frosted View behind Status bar
- (void)addFrostedBehindForStatusBar {
    if (statusBarFrame.size.height == 20) {
        UINavigationBar *statusBarBackground = [[UINavigationBar alloc] initWithFrame:statusBarFrame];
        statusBarBackground.barStyle = UIBarStyleDefault;
        statusBarBackground.translucent = YES;
        statusBarBackground.tag = 9920;
        [self.view insertSubview:statusBarBackground aboveSubview:self.tableView];
    }
}

- (void)removeFrostedView {
    // Need to remove it on viewWillDisappear to stop a flash at the screen top
    for (UIView *view in [NSArray arrayWithArray:self.view.subviews]) {
        if (view.tag == 9920) {
            [view removeFromSuperview];
            break;
        }
    }
}

#pragma mark - video upload indicator

- (void)uploadStarted:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[TDCurrentUser sharedInstance] isRegisteredForPush]) {
            self.didUpload = YES;
        }

        [self.headerView addUpload:notification.object];
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    });
}

#pragma mark - Bottom Buttons Bounce
- (void)hideBottomButtons {
    // Place off screen
    self.recordButton.center = CGPointMake(self.recordButton.center.x,
                                           [UIScreen mainScreen].bounds.size.height + (self.recordButton.frame.size.height / 2.0) + 1.0);
    self.profileButton.center = CGPointMake(self.profileButton.center.x,
                                            [UIScreen mainScreen].bounds.size.height + (self.profileButton.frame.size.height / 2.0) + 1.0);
    self.notificationButton.center = CGPointMake(self.notificationButton.center.x,
                                                 [UIScreen mainScreen].bounds.size.height + (self.notificationButton.frame.size.height / 2.0) + 1.0);
    self.badgeCountLabel.hidden = YES;
}

- (void)animateButtonsOnToScreen {
    [self hideBottomButtons];
    NSArray *items = @[self.recordButton, self.profileButton, self.notificationButton];
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UIGravityBehavior* gravityBehavior = [[UIGravityBehavior alloc] initWithItems:items];
    gravityBehavior.magnitude = 4.0;
    gravityBehavior.gravityDirection = CGVectorMake(0.0, -1.0);
    UICollisionBehavior* collisionBehavior = [[UICollisionBehavior alloc] initWithItems:items];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = NO;
    [collisionBehavior addBoundaryWithIdentifier:@"middle"
                                       fromPoint:CGPointMake(0.0, origRecordButtonCenter.y - self.recordButton.frame.size.height / 2.0)
                                         toPoint:CGPointMake(self.view.frame.size.width, origRecordButtonCenter.y - self.recordButton.frame.size.height / 2.0)];
    UIDynamicItemBehavior* propertiesBehavior = [[UIDynamicItemBehavior alloc] initWithItems:items];
    propertiesBehavior.elasticity = 0.4;
    propertiesBehavior.friction = 100.0;
    [self.animator addBehavior:gravityBehavior];
    [self.animator addBehavior:collisionBehavior];
    [self.animator addBehavior:propertiesBehavior];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self displayBadgeCount];
    });
}

#pragma mark - segues

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([@"VideoButtonSegue" isEqualToString:identifier] && [TDFileSystemHelper getFreeDiskspace] < kMinFileSpaceForRecording) {
        NSLog(@"Warning, low disk space: %lld", [TDFileSystemHelper getFreeDiskspace]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Storage Space Low" message:@"There is not enough available storage to record or upload content. Clear some space to continue." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert showWithCompletionBlock:nil];
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    if([segue isKindOfClass:[VideoButtonSegue class]]) {
        goneDownstream = YES;
    }
}

- (IBAction)unwindToHome:(UIStoryboardSegue *)sender {
    // hide the buttons here b/c the seuge animates a screenshot of current view and buttons are visible
    if (goneDownstream) {
        [self hideBottomButtons];
    }
    debug NSLog(@"home view unwindToHome with identifier %@", sender.identifier);
}

- (void)showHomeController {
    // stub to stop crash bug from segue: navigateToHomeFrom
}

#pragma mark - Post Delegate

- (void)userButtonPressedFromRow:(NSInteger)row {
    TDPost *post = [self postForRow:row];
    if (post) {
        [self openProfile:post.user.userId];
    }
}

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
    TDPost *post = [self postForRow:row];
    if (post) {
        TDComment *comment = [post.comments objectAtIndex:commentNumber];
        TDUser *user = comment.user;
        [self openProfile:user.userId];
    }
}

#pragma mark - Notification Badge Count

- (void)refreshPostsNotification:(NSNotification *)notification {
    if (notification.userInfo) {
        if ([notification.userInfo objectForKey:@"notificationCount"]) {
            self.badgeCount = (NSNumber *)[notification.userInfo objectForKey:@"notificationCount"];
        } else if ([notification.userInfo objectForKey:@"incrementCount"]) {
            self.badgeCount = [NSNumber numberWithLong:[self.badgeCount integerValue] + [((NSNumber *)[notification.userInfo objectForKey:@"incrementCount"]) integerValue]];
        } else if ([notification.userInfo objectForKey:@"decreaseCount"]) {
            self.badgeCount = [NSNumber numberWithLong:[self.badgeCount integerValue] - [((NSNumber *)[notification.userInfo objectForKey:@"decreaseCount"]) integerValue]];
        }
        [self displayBadgeCount];
    }
}
- (void)displayBadgeCount {
    if ([self.badgeCount integerValue] > 0) {
        self.badgeCountLabel.hidden = NO;
        self.badgeCountLabel.text = [NSString stringWithFormat:@"%@", self.badgeCount];
        CGRect frame = self.badgeCountLabel.frame;
        if ([self.badgeCount integerValue] < 10) {
            frame.size.width = 18;
        } else if ([self.badgeCount integerValue] < 100) {
            frame.size.width = 24;
        } else if ([self.badgeCount integerValue] < 1000) {
            frame.size.width = 28;
        } else {
            frame.size.width = 34;
        }
        self.badgeCountLabel.frame = frame;
    } else {
        self.badgeCountLabel.hidden = YES;
    }

}

#pragma mark - TDToastViewDelegate

- (void)toastNotificationTappedPayload:(NSDictionary *)payload {
    [self openPushNotification:payload];

    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdate
                                                        object:self
                                                      userInfo:@{@"decreaseCount": @1}];
    if ([payload objectForKey:@"activity_id"]) {
        [[TDAPIClient sharedInstance] updateActivity:[payload objectForKey:@"activity_id"] seen:NO clicked:YES];
    }
}

#pragma mark - Handle URL's

- (void)openURL:(NSURL *)url {
    [self unwindAllViewControllers];
    NSString *modelId = [[url pathComponents] objectAtIndex:1]; // 0 is the first slash
    if ([@"post" isEqualToString:[url host]]) {
        TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil];
        vc.slug = modelId;
        vc.delegate = self;
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([@"user" isEqualToString:[url host]]) {
        TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
        vc.username = modelId;

        if ([modelId isEqualToString:[[TDCurrentUser sharedInstance] currentUserObject].username] ||
            [modelId isEqualToString:[[TDCurrentUser sharedInstance].currentUserObject.userId stringValue]]) {
            vc.fromProfileType = kFromProfileScreenType_OwnProfileButton;
            vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
            navController.navigationBar.barStyle = UIBarStyleDefault;
            navController.navigationBar.translucent = YES;
            [self.navigationController presentViewController:navController animated:YES completion:nil];

        } else {
            vc.fromProfileType = kFromProfileScreenType_OtherUser;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

#pragma mark - Notifications and sub view

- (void)openPushNotification:(NSDictionary *)notification {
    [self unwindAllViewControllers];
    if ([notification objectForKey:@"user_id"]) {
        [self openProfile:[notification objectForKey:@"user_id"]];
    } else if ([notification objectForKey:@"post_id"]) {
        [self openDetailView:[notification objectForKey:@"post_id"]];
    }
}

- (void)unwindAllViewControllers {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
    UIViewController *top = [TDAppDelegate topMostController];
    if ([top class] == [UINavigationController class] || [top class] == [TDNavigationController class]) {
        for (UIViewController *vc in [((UINavigationController *)top) viewControllers]) {
            if ([vc respondsToSelector:@selector(unwindToRoot)]) {
                [vc performSelector:@selector(unwindToRoot)];
            }
        }
    }
}

- (void)openProfile:(NSNumber *)userId {
    debug NSLog(@"gotoProfileForUser:%@", userId);
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;

    // Slightly different if current user
    if ([userId isEqualToNumber:[[TDCurrentUser sharedInstance] currentUserObject].userId]) {
        vc.fromProfileType = kFromProfileScreenType_OwnProfile;
    } else {
        vc.fromProfileType = kFromProfileScreenType_OtherUser;
    }
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)notificationButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ActivityViewController"];
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)openDetailView:(NSNumber *)postId {
    [super openDetailView:postId];
}

@end
