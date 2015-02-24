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
#include "TDFeedbackViewController.h"
#import "iRate.h"
#import "TDTagFeedViewController.h"
#import "NSString+URLEncode.h"
#import "TDInviteViewController.h"

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController () <UIScrollViewDelegate, UIDocumentInteractionControllerDelegate, TDGuestUserInfoCellDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *feedSelectionControl;
@property (weak, nonatomic) IBOutlet UIButton *searchTDUsersButton;
@property (weak, nonatomic) IBOutlet UILabel *badgeCountLabel;
@property (nonatomic) NSNumber *badgeCount;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (nonatomic) BOOL didUpload;
@property (nonatomic) BOOL scrollToTop;
@property (nonatomic) NSNumber *nextStartAll;
@property (nonatomic) NSNumber *nextStartFollowing;
@property (nonatomic) NSArray *posts;
@property (nonatomic) NSArray *postsFollowing;
@property (nonatomic) NSArray *notices;
@property (nonatomic) TDHomeHeaderView *headerView;
@property (nonatomic, retain) UIDynamicAnimator *animator;
@property (nonatomic) CGFloat previousScrollViewYOffset;
@property (nonatomic) CGPoint lastScrollOffset;
@property (nonatomic) CGPoint scrollOffsetFollowing;
@property (retain) UIView *disableViewOverlay;
@property (nonatomic) TDFeedbackViewController *feedbackVC;
@property (nonatomic, retain) UIDocumentInteractionController *documentController;
@property (nonatomic) NSString *instagramFileLocation;

@end

@implementation TDHomeViewController

// Returns nil if TDHomeViewController is not the topmost controller (excl. navigation controller)
+ (TDHomeViewController *)getHomeViewController {
    id rootController = [[[TDAppDelegate appDelegate] window] rootViewController];
    if (rootController && [rootController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = rootController;
        if ([navigationController.viewControllers count] > 0) {
            UIViewController *controller = (UIViewController *)[navigationController.viewControllers objectAtIndex:0];
            if ([controller isKindOfClass:[TDHomeViewController class]]) {
                return (TDHomeViewController*)controller;
            }
        }
    }
    return nil;
}


- (void)viewDidLoad {

    // setup the feed selection so we don't
    [self.feedSelectionControl setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontSemiBoldSized:14] } forState:UIControlStateNormal];
    [self.feedSelectionControl setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontSemiBoldSized:14] } forState:UIControlStateHighlighted];
    [self.feedSelectionControl setContentPositionAdjustment:UIOffsetMake(0, 1) forSegmentType:UISegmentedControlSegmentAny barMetrics:UIBarMetricsDefault];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.feedSelectionControl setSelectedSegmentIndex:[defaults integerForKey:@"currentHomeFeedTabIndex"]];

    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStarted:) name:TDPostUploadStarted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNotificationCount:) name:TDNotificationUpdate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadHome:) name:TDNotificationReloadHome object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePost:) name:TDNotificationRemovePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePost:) name:TDNotificationUpdatePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForegroundCallback:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOverlay) name:TDRemoveHomeViewControllerOverlay object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFeedbackViewController) name:TDShowFeedbackViewController object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postToInstagram:) name:TDNotificationPostToInstagram object:nil];

    [self.badgeCountLabel setFont:[TDConstants fontSemiBoldSized:11]];
    [self.badgeCountLabel.layer setCornerRadius:9.0];

    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;

    self.inviteButton.titleLabel.font = [TDConstants fontRegularSized:18];


    self.headerView = [[TDHomeHeaderView alloc] initWithTableView:self.tableView];
    self.previousScrollViewYOffset = 0;
    
    self.disableViewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0.0f,0,SCREEN_WIDTH,SCREEN_HEIGHT)];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    if (self.scrollToTop) {
        [self scrollTableToTop];
        self.scrollToTop = NO;
    }
    [self showNavBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (goneDownstream) {
        [self animateButtonsOnToScreen];
    }
    goneDownstream = NO;

    if (self.didUpload) {
        self.didUpload = NO;
        [self askForPushNotification];
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

- (void)askForPushNotification {
    BOOL asked = [[TDCurrentUser sharedInstance] registerForPushNotifications:@"Thanks for making a post! We'd\nlike to notify you when someone\nlikes or comments on it. But, we'd\nlike to ask you first. On the next\nscreen, please tap \"OK\" to give\nus permission."];
    if (!asked && [[iRate sharedInstance] shouldPromptForRating]) {
        [[iRate sharedInstance] promptIfNetworkAvailable];
    }
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
    BOOL hasAskedForGoal = [[TDCurrentUser sharedInstance] didAskForGoalsInitially];

    BOOL hasAskedForGoalsFinal = [[TDCurrentUser sharedInstance] didAskForGoalsFinal];
    if (!hasAskedForGoal && !hasAskedForGoalsFinal) {
        hasAskedForGoalsFinal = YES; // We don't want to add another section if both values are no.  So override the boolean
    }

    NSInteger realRow = row - ([self noticeCount] + ([[TDCurrentUser sharedInstance] isNewUser] ? 1 : 0) + (hasAskedForGoal ? 0 : 1) + (hasAskedForGoalsFinal ? 0 :1) ) ;
    if ([iRate sharedInstance].shouldPromptForRating && (realRow > TD_REVIEW_APP_CELL_POST_NUM)){
        realRow = realRow - 1;
    }

    if (realRow < [posts count]) {
        return [posts objectAtIndex:realRow];
    } else {
        return nil;
    }
}

- (void)reloadHome:(NSNotification *)notification {
    [self fetchPosts];
}

- (void)fetchPosts {
    [self stopBottomLoadingSpinner];
    [self fetchPostsAtStart:nil completion:nil];
}

- (void)fetchPostsWithCompletion:(void (^)(void))completion {
    [self stopBottomLoadingSpinner];
    [self fetchPostsAtStart:nil completion:completion];
}

- (BOOL)fetchMorePostsAtBottom {
    return [self fetchPostsAtStart:([self onAllFeed] ? self.nextStartAll : self.nextStartFollowing) completion:nil];
}

- (BOOL)fetchPostsAtStart:(NSNumber *)start completion:(void (^)(void))completion {
    if (start != nil && ![self hasMorePosts]) {
        return NO;
    }
    [[TDPostAPI sharedInstance] fetchPostsForFeed:([self onAllFeed] ? kFetchPostsForFeedAll : kFetchPostsForFeedFollowing) start:start success:^(NSDictionary *response) {
        [self handlePostsResponse:response fromStart:(start == nil)];
        if (completion) {
            completion();
        }
    } error:^{
        if (completion) {
            completion();
            [[TDAppDelegate appDelegate] showToastWithText:@"Upload complete but couldn't refresh feed" type:kToastType_Info payload:@{} delegate:nil];
        } else {
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
        }

        if (start == nil) {
            self.loaded = YES;
            self.errorLoading = YES;
        }

        [self stopBottomLoadingSpinner]; // calls tableview reloaddata
        [self endRefreshControl];
    }];
    return YES;
}

- (void)handlePostsResponse:(NSDictionary *)response fromStart:(BOOL)start {
    self.loaded = YES;
    self.errorLoading = NO;
    NSMutableArray *tmp = [[NSMutableArray alloc] init];

    if (start) {
        // Set notices (shows in both all and following on home feed)
        if ([response objectForKey:@"notices"]) {
            for (NSDictionary *dict in [response objectForKey:@"notices"]) {
                [tmp addObject:[[TDNotice alloc] initWithDictionary:dict]];
            }
            self.notices = [NSArray arrayWithArray:tmp];
        } else {
            self.notices = nil;
        }

//        debug NSLog(@"=======>self.notices count=%lu", (unsigned long)self.notices.count);

        // Update notification count from feed
        // TODO: There's an inconsistency if user opens activity feed, this still gets set even though user has seen the notifications.
        if ([response valueForKey:@"notification_count"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdate
                                                                object:self
                                                              userInfo:@{@"notificationCount": [response valueForKey:@"notification_count"]}];
        }
    }

    // All feed
    if ([response valueForKeyPath:@"posts"]) {
        if (start) {
            self.posts = nil;
        }

        if ([response valueForKey:@"next_start"] && [[[response valueForKey:@"next_start"] class] isSubclassOfClass:[NSNumber class]]) {
            self.nextStartAll = [response valueForKey:@"next_start"];
        } else {
            self.nextStartAll = nil;
        }

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
        if (start) {
            self.postsFollowing = nil;
        }

        if ([response valueForKey:@"following_next_start"] && [[[response valueForKey:@"following_next_start"] class] isSubclassOfClass:[NSNumber class]]) {
            self.nextStartFollowing = [response valueForKey:@"following_next_start"];
        } else {
            self.nextStartFollowing = nil;
        }

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

- (BOOL)onAllFeed {
    return [self.feedSelectionControl selectedSegmentIndex] == 0;
}

- (NSArray *)postsForThisScreen {
    return [self onAllFeed] ? self.posts : self.postsFollowing;
}

- (BOOL)hasMorePosts {
    NSNumber *more = [self onAllFeed] ? self.nextStartAll : self.nextStartFollowing;
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
    [self fetchPosts];
}

#pragma mark - video upload indicator

- (void)uploadStarted:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.headerView addUpload:notification.object];

        // Check if we were already presented before the notifcation came through
        if ([[self.navigationController viewControllers] lastObject] == self) {
            [self askForPushNotification];
            [self scrollTableToTop];
        } else {
            self.didUpload = YES;
            self.scrollToTop = YES;
        }
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
    [self showNavBar];

    if([segue isKindOfClass:[VideoButtonSegue class]]) {
        goneDownstream = YES;
    }
}

- (IBAction)unwindToHome:(UIStoryboardSegue *)sender {
    // hide the buttons here b/c the seuge animates a screenshot of current view and buttons are visible
    if (goneDownstream) {
        [self hideBottomButtons];
    }
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
        [self showNavBar];
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

            [self showNavBar];
            [self.navigationController presentViewController:navController animated:YES completion:nil];
        } else {
            vc.profileType = kFeedProfileTypeOther;
            [self showNavBar];
            [self.navigationController pushViewController:vc animated:YES];

        }
        return YES;
    } else if ([model isEqualToString:@"tag"]) {
        TDTagFeedViewController *vc = [[TDTagFeedViewController alloc] initWithNibName:@"TDTagFeedViewController" bundle:nil ];
        vc.tagName = [[url path] lastPathComponent];
        [self.navigationController pushViewController:vc animated:YES];
    }
    return NO;
}

#pragma mark - TDPostViewDelegate and TDDetailsCommentsCellDelegate

// Just override to call showNavBar then send to TDPostsViewController

- (void)userTappedURL:(NSURL *)url {
    [self showNavBar];
    [super userTappedURL:url];
}

- (void)locationButtonPressedFromRow:(NSInteger)row {
    [self showNavBar];
    [super locationButtonPressedFromRow:row];
}


#pragma mark - Navigation

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
    [self showNavBar];
    [super openProfile:userId];
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
    [self showNavBar];
    [super openDetailView:postId];
}

- (IBAction)feedSelectionControlChanged:(id)sender {
    CGPoint scrollTo = self.lastScrollOffset;
    self.lastScrollOffset = self.tableView.contentOffset;

    // User switched tab and that tab is empty:
    if (![self postsForThisScreen] || [[self postsForThisScreen] count] == 0) {
        self.loaded = NO;
        self.errorLoading = NO;
        [self fetchPosts];
    }
    [self reloadPosts];
    self.tableView.contentOffset = scrollTo;
    [self showNavBar];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[self.feedSelectionControl selectedSegmentIndex] forKey:@"currentHomeFeedTabIndex"];
    [defaults synchronize];
}

- (IBAction)searchTDUsersButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    TDFindPeopleViewController *vc = [[TDFindPeopleViewController alloc] initWithNibName:@"TDFindPeopleViewController" bundle:nil ];
    vc.profileUser = [TDCurrentUser sharedInstance].currentUserObject;

    [self showNavBar];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)inviteButtonPressed:(id)sender {
    [self showNavBar];

    TDInviteViewController *vc = [[TDInviteViewController alloc] initWithNibName:@"TDInviteViewController" bundle:nil ];

    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];

}

- (void)addOverlay {
    self.disableViewOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [[TDAppDelegate appDelegate].window addSubview:self.disableViewOverlay];
    [UIView beginAnimations:@"FadeIn" context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView commitAnimations];

}
#pragma mark - ScrollViewDelegate (hiding nav bar when scrolling)

- (void)scrollTableToTop {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [super scrollViewDidScroll:scrollView];

    if (self.navigationController == nil) {
        return;
    }

    CGRect frame = self.navigationController.navigationBar.frame;
    // table view acts up if there isn't enough content in there so abort if content is smaller than the frame size
    if (self.tableView.contentSize.height <= self.tableView.frame.size.height) {
        return;
    }

    CGFloat size = frame.size.height - 21;
    CGFloat scrollOffset = scrollView.contentOffset.y;
    CGFloat scrollDiff = (scrollOffset - self.previousScrollViewYOffset) * 0.5;
    CGFloat scrollHeight = scrollView.frame.size.height;
    CGFloat scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom;

    if (scrollOffset <= -scrollView.contentInset.top) {
        frame.origin.y = 20;
    } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
        frame.origin.y = -size;
    } else {
        frame.origin.y = MIN(20, MAX(-size, frame.origin.y - scrollDiff));
    }

    [self setTableViewFrameBasedOn:frame];

    self.navigationController.navigationBar.frame = frame;

    CGFloat framePercentageHidden = ((20 - frame.origin.y) / (frame.size.height - 1));
    [self updateNavigationBarButtons:(1.0 - framePercentageHidden)];
    self.previousScrollViewYOffset = scrollOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self stoppedScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self stoppedScrolling];
    }
}

- (void)stoppedScrolling {
    CGRect frame = self.navigationController.navigationBar.frame;
    if (frame.origin.y < 20) {
        CGFloat top = -(frame.size.height - 21);
        [self animateNavBarTo:(top + 20 > frame.origin.y ? top : 20)];
    }
}

- (void)showNavBar {
    [self animateNavBarTo:20];
}

- (void)animateNavBarTo:(CGFloat)y {
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.navigationController.navigationBar.frame;
        CGFloat alpha = frame.origin.y >= y && y < 20 ? 0 : 1;
        frame.origin.y = y;
        self.navigationController.navigationBar.frame = frame;
        [self updateNavigationBarButtons:alpha];
        [self setTableViewFrameBasedOn:frame];
    }];
}

- (void)setTableViewFrameBasedOn:(CGRect)frame {
    CGRect scrollFrame = self.tableView.frame;
    scrollFrame.origin.y = frame.origin.y - 20;
    scrollFrame.size.height = [UIScreen mainScreen].bounds.size.height - 20;
    if (!CGRectEqualToRect(scrollFrame, self.tableView.frame)) {
        self.tableView.frame = scrollFrame;
    }
}

- (void)updateNavigationBarButtons:(CGFloat)alpha {
    for (UIView *navView in self.navigationController.navigationBar.subviews) {
        NSString *desc = (NSString *)navView.description;
        if ([desc rangeOfString:@"UINavigationBarBackground"].length == 0 && [desc rangeOfString:@"UINavigationBarBackIndicatorView"].length == 0) {
            navView.alpha = alpha;
        }
    }
    self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:alpha] };
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}

- (void)willEnterForegroundCallback:(NSNotification *)notification {
    [self showNavBar];
}

- (void)removeOverlay {
    [self.disableViewOverlay removeFromSuperview];
    [self refreshPostsList];
}

- (void)showFeedbackViewController {
    self.feedbackVC = [[TDFeedbackViewController alloc] initWithNibName:@"TDFeedbackViewController" bundle:nil ];
    
    CGRect feedbackFrame = self.feedbackVC.view.frame;
    feedbackFrame.origin.x = SCREEN_WIDTH/2 - self.feedbackVC.view.frame.size.width/2;
    feedbackFrame.origin.y = SCREEN_HEIGHT/2 - self.feedbackVC.view.frame.size.height/2;
    self.feedbackVC.view.frame = feedbackFrame;
    [self addOverlay];
    [self.disableViewOverlay addSubview:self.feedbackVC.view];
}

#pragma mark - Instagram sharing

- (void)postToInstagram:(NSNotification *)n {
    NSString *caption  = [[n.userInfo objectForKey:@"caption"] stringByAppendingString:@"\nvia @ThrowdownUs"];
    NSString *location = [n.userInfo objectForKey:@"location"];
    if ([[n.userInfo objectForKey:@"isVideo"] boolValue]) {
        NSURL *instagramURL = [NSURL URLWithString:[NSString stringWithFormat:@"instagram://library?AssetPath=%@&InstagramCaption=%@", [location urlencodedString], [caption urlencodedString]]];

        if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
            [[UIApplication sharedApplication] openURL:instagramURL];
        }
    } else {
        self.instagramFileLocation = location;
        NSURL *fileURL = [NSURL fileURLWithPath:location];
        self.documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        self.documentController.delegate = self;
        [self.documentController setUTI:@"com.instagram.exclusivegram"];
        [self.documentController setAnnotation:@{ @"InstagramCaption" : caption }];
        [self.documentController presentOpenInMenuFromRect:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) inView:self.view animated:YES];
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    if (self.instagramFileLocation) {
        [TDFileSystemHelper removeFileAt:self.instagramFileLocation];
    }
}

#pragma mark TDGuestInfoCellDelegate
-(void)createPostButtonPressed {
    [self performSegueWithIdentifier:@"VideoButtonSegue" sender:self];
}

-(void)dismissForExistingUser {
    debug NSLog(@"dismissForExistingUser");
    [[TDCurrentUser sharedInstance] didAskForGoalsInitially:YES];
    [self.tableView reloadData];
}

- (void)goalsButtonPressed {
    [self showGoalsAndInterestsController];
}

- (void)reloadTableView {
    [[TDCurrentUser sharedInstance] didAskForGoalsFinal:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@"You may set your goals & interests any time through your Settings page."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil, nil];
    [alert show];

    [self.tableView reloadData];
}
@end
