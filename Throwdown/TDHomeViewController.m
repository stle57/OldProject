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
#import "TDURLHelper.h"
#import "TDFileSystemHelper.h"
#import <QuartzCore/QuartzCore.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include "TDFindPeopleViewController.h"

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *feedSelectionControl;
@property (weak, nonatomic) IBOutlet UIButton *searchTDUsersButton;
@property (weak, nonatomic) IBOutlet UILabel *badgeCountLabel;
@property (nonatomic) NSNumber *badgeCount;

@property (nonatomic) BOOL didUpload;
@property (nonatomic) NSNumber *nextStartAll;
@property (nonatomic) NSNumber *nextStartFollowing;
@property (nonatomic) NSArray *posts;
@property (nonatomic) NSArray *postsFollowing;
@property (nonatomic) NSArray *notices;
@property (nonatomic) TDHomeHeaderView *headerView;
@property (nonatomic, retain) UIDynamicAnimator *animator;

@end

@implementation TDHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStarted:) name:TDPostUploadStarted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNotificationCount:) name:TDNotificationUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadHome:) name:TDNotificationReloadHome object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePost:) name:TDNotificationRemovePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePost:) name:TDNotificationUpdatePost object:nil];

    [self.badgeCountLabel setFont:[TDConstants fontSemiBoldSized:11]];
    [self.badgeCountLabel.layer setCornerRadius:9.0];

    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;

    [self.feedSelectionControl setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontSemiBoldSized:14] } forState:UIControlStateNormal];
    [self.feedSelectionControl setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontSemiBoldSized:14] } forState:UIControlStateHighlighted];
    [self.feedSelectionControl setContentPositionAdjustment:UIOffsetMake(0, 1) forSegmentType:UISegmentedControlSegmentAny barMetrics:UIBarMetricsDefault];

    self.headerView = [[TDHomeHeaderView alloc] initWithTableView:self.tableView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (goneDownstream) {
        [self hideBottomButtons];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Notices

- (NSUInteger)noticeCount {
    if (self.notices) {
        return [self.notices count];
    }
    return 0;
}

- (TDNotice *)getNoticeAt:(NSUInteger)index {
    if (self.notices && index < [self.notices count]) {
        return [self.notices objectAtIndex:index];
    }
    return nil;
}

- (BOOL)removeNoticeAt:(NSUInteger)index {
    if (self.notices && index < [self.notices count]) {
        NSMutableArray *list = [[NSMutableArray alloc] initWithArray:self.notices];
        [list removeObjectAtIndex:index];
        self.notices = [[NSArray alloc] initWithArray:list];
        return YES;
    }
    return NO;
}


#pragma mark - Posts

- (TDPost *)postForRow:(NSInteger)row {
    NSArray *posts = [self onAllFeed] ? self.posts : self.postsFollowing;
    NSInteger realRow = row - [self noticeCount];
    if (realRow < [posts count]) {
        return [posts objectAtIndex:realRow];
    } else {
        return nil;
    }
}

- (void)reloadHome:(NSNotification *)notification {
    [self fetchPostsRefresh];
}

- (void)fetchPostsRefresh {
    [self stopBottomLoadingSpinner];
    [[TDPostAPI sharedInstance] fetchPostsWithSuccess:^(NSDictionary *response) {
        // Set notices (shows in both all and following on home feed)
        if ([response objectForKey:@"notices"]) {
            NSMutableArray *tmp = [[NSMutableArray alloc] init];
            for (NSDictionary *dict in [response objectForKey:@"notices"]) {
                [tmp addObject:[[TDNotice alloc] initWithDictionary:dict]];
            }
            self.notices = [NSArray arrayWithArray:tmp];
        } else {
            self.notices = nil;
        }

        // Update notification count from feed
        // TODO: There's an inconsistency if user opens activity feed, this still gets set even though user has seen the notifications.
        if ([response valueForKey:@"notification_count"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdate
                                                                object:self
                                                              userInfo:@{@"notificationCount": [response valueForKey:@"notification_count"]}];
        }

        // do this last b/c it reloads the table
        [self handleNextStarts:response];
        [self handlePostsResponse:response fromStart:YES];

    } error:^{
        self.loaded = YES;
        self.errorLoading = YES;
        [self endRefreshControl];
        [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
        [self.tableView reloadData];
    }];
}

- (BOOL)fetchMorePostsAtBottom {
    if (![self hasMorePosts]) {
        return NO;
    }
    if ([self onAllFeed]) {
        debug NSLog(@"fetchPostsForAll");
        [[TDPostAPI sharedInstance] fetchPostsForAll:self.nextStartAll success:^(NSDictionary *response) {
            // if the request was aborted by another action
            if (showBottomSpinner) {
                [self handleNextStarts:response];
                [self handlePostsResponse:response fromStart:NO];
            }
        } error:^{
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
            [self stopBottomLoadingSpinner];
        }];
    } else {
        debug NSLog(@"fetchPostsForFollowing");
        [[TDPostAPI sharedInstance] fetchPostsForFollowing:self.nextStartFollowing success:^(NSDictionary *response) {
            // if the request was aborted by another action
            if (showBottomSpinner) {
                [self handleNextStarts:response];
                [self handlePostsResponse:response fromStart:NO];
            }
        } error:^{
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
            [self stopBottomLoadingSpinner];
        }];
    }
    return YES;
}

- (void)handlePostsResponse:(NSDictionary *)response fromStart:(BOOL)start {
    self.loaded = YES;
    self.errorLoading = NO;

    if (start) {
        self.posts = nil;
        self.postsFollowing = nil;
        self.removingPosts = nil;
    }

    // All feed
    if ([response valueForKeyPath:@"posts"]) {
        NSMutableArray *newPosts;
        if (self.posts) {
            newPosts = [[NSMutableArray alloc] initWithArray:self.posts];
        } else {
            newPosts = [[NSMutableArray alloc] init];
        }

        for (NSDictionary *postObject in [response valueForKeyPath:@"posts"]) {
            [newPosts addObject:[[TDPost alloc] initWithDictionary:postObject]];
        }
        self.posts = newPosts;
    }

    // Following feed
    if ([response valueForKeyPath:@"following"]) {
        NSMutableArray *newPosts;
        if (self.postsFollowing) {
            newPosts = [[NSMutableArray alloc] initWithArray:self.postsFollowing];
        } else {
            newPosts = [[NSMutableArray alloc] init];
        }

        for (NSDictionary *postObject in [response valueForKeyPath:@"following"]) {
            [newPosts addObject:[[TDPost alloc] initWithDictionary:postObject]];
        }
        self.postsFollowing = newPosts;
    }

    [self refreshPostsList];
}

- (void)handleNextStarts:(NSDictionary *)response {
    if ([response valueForKey:@"next_start"] && [[[response valueForKey:@"next_start"] class] isSubclassOfClass:[NSNumber class]]) {
        self.nextStartAll = [response valueForKey:@"next_start"];
    } else {
        self.nextStartAll = nil;
    }
    if ([response valueForKey:@"following_next_start"] && [[[response valueForKey:@"following_next_start"] class] isSubclassOfClass:[NSNumber class]]) {
        self.nextStartFollowing = [response valueForKey:@"following_next_start"];
    } else {
        self.nextStartFollowing = nil;
    }
}

- (BOOL)onAllFeed {
    return [self.feedSelectionControl selectedSegmentIndex] == 0;
}

- (NSArray *)postsForThisScreen {
    return [self onAllFeed] ? self.posts : self.postsFollowing;
}

- (BOOL)hasMorePosts {
    NSNumber *more = [self.feedSelectionControl selectedSegmentIndex] == 0 ? self.nextStartAll : self.nextStartFollowing;
    return more != nil;
}

- (void)removePost:(NSNotification *)n {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Main posts
        BOOL changeMade = NO;
        NSNumber *postId = (NSNumber *)[n.userInfo objectForKey:@"postId"];
        NSMutableArray *newList = [[NSMutableArray array] init];
        for (TDPost *post in self.posts) {
            if ([post.postId isEqualToNumber:postId]) {
                debug NSLog(@"removing post from vc with id %@", postId);
                changeMade = YES;
            } else {
                [newList addObject:post];
            }
        }
        if (changeMade) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.posts = [[NSArray alloc] initWithArray:newList];
                if ([self onAllFeed]) {
                    [self.tableView reloadData];
                }
            });
        }

        // Following posts
        changeMade = NO;
        newList = [[NSMutableArray array] init];
        for (TDPost *post in self.postsFollowing) {
            if ([post.postId isEqualToNumber:postId]) {
                debug NSLog(@"removing post from vc with id %@", postId);
                changeMade = YES;
            } else {
                [newList addObject:post];
            }
        }
        if (changeMade) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.postsFollowing = [[NSArray alloc] initWithArray:newList];
                if (![self onAllFeed]) {
                    [self.tableView reloadData];
                }
            });
        }
    });
}

#pragma mark - Update Posts

- (void)updatePost:(NSNotification *)n {
    BOOL changeMade = NO;
    NSNumber *postId = (NSNumber *)[n.userInfo objectForKey:@"postId"];

    for (TDPost *post in self.posts) {
        if ([post.postId isEqualToNumber:postId]) {
            [post updateFromNotification:n];
            changeMade = YES;
            break;
        }
    }
    for (TDPost *post in self.postsFollowing) {
        if ([post.postId isEqualToNumber:postId]) {
            [post updateFromNotification:n];
            changeMade = YES;
            break;
        }
    }

    if (changeMade) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

- (void)updatePostsAfterUserUpdate:(NSNotification *)notification {
    debug NSLog(@"%@ updatePostsAfterUserUpdate:%@", [self class], [[TDCurrentUser sharedInstance] currentUserObject]);

    for (TDPost *aPost in self.posts) {
        [aPost updateUserInfoFor:[[TDCurrentUser sharedInstance] currentUserObject]];
    }

    for (TDPost *aPost in self.postsFollowing) {
        [aPost updateUserInfoFor:[[TDCurrentUser sharedInstance] currentUserObject]];
    }

    [self.tableView reloadData];
}


#pragma mark - Refresh Control
- (void)refreshControlUsed {
    debug NSLog(@"home-refreshControlUsed");
    [self fetchPostsRefresh];
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
                                       fromPoint:CGPointMake(0.0, self.view.frame.size.height - self.recordButton.frame.size.height)
                                         toPoint:CGPointMake(self.view.frame.size.width, self.view.frame.size.height - self.recordButton.frame.size.height)];
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Storage Space Low"
                                                        message:@"There is not enough available storage to record or upload content. Clear some space to continue."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
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
        TDComment *comment = [post commentAtIndex:commentNumber];
        if (comment) {
            [self openProfile:comment.user.userId];
        }
    }
}

#pragma mark - Notification Badge Count

- (void)refreshNotificationCount:(NSNotification *)notification {
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
    debug NSLog(@"Inside toastNotificationTappedPayload");
    [self openPushNotification:payload];

    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdate
                                                        object:self
                                                      userInfo:@{@"decreaseCount": @1}];
    if ([payload objectForKey:@"activity_id"]) {
        [[TDAPIClient sharedInstance] updateActivity:[payload objectForKey:@"activity_id"] seen:NO clicked:YES];
    }
}

#pragma mark - Handle URL's

- (BOOL)openURL:(NSURL *)url {
    NSArray *pair = [TDURLHelper parseThrowdownURL:url];

    if (!pair) {
        return NO;
    }

    NSString *model   = [pair firstObject];
    NSString *modelId = [pair lastObject];

    if ([model isEqualToString:@"post"]) {
        [self unwindAllViewControllers];

        TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil];
        vc.slug = modelId;
        [self.navigationController pushViewController:vc animated:YES];
        return YES;

    } else if ([model isEqualToString:@"user"]) {
        [self unwindAllViewControllers];

        TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
        vc.username = modelId;
        if ([modelId isEqualToString:[[TDCurrentUser sharedInstance] currentUserObject].username] ||
            [modelId isEqualToString:[[TDCurrentUser sharedInstance].currentUserObject.userId stringValue]]) {
            vc.profileType = kFeedProfileTypeOwnViaButton;
            vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
            navController.navigationBar.barStyle = UIBarStyleDefault;
            navController.navigationBar.translucent = YES;
            [self.navigationController presentViewController:navController animated:YES completion:nil];
        } else {
            vc.profileType = kFeedProfileTypeOther;
            [self.navigationController pushViewController:vc animated:YES];

        }
        return YES;
    }
    return NO;
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
        vc.profileType = kFeedProfileTypeOwn;
    } else {
        vc.profileType = kFeedProfileTypeOther;
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

- (IBAction)feedSelectionControlChanged:(id)sender {
    [self reloadPosts];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    NSLog(@"selection is %ld", (long)[self.feedSelectionControl selectedSegmentIndex]);
}

- (IBAction)searchTDUsersButtonPressed:(id)sender {
    TDFindPeopleViewController *vc = [[TDFindPeopleViewController alloc] initWithNibName:@"TDFindPeopleViewController" bundle:nil ];
    vc.profileUser = [TDCurrentUser sharedInstance].currentUserObject;
    [self.navigationController pushViewController:vc animated:NO];
}

@end
