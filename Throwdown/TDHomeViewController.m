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
#import "VideoCloseSegue.h"
#import "TDLikeView.h"
#import "TDHomeHeaderView.h"
#import "TDActivityCell.h"
#import "TDUserProfileViewController.h"
#import "TDNavigationController.h"
#import <QuartzCore/QuartzCore.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *badgeCountLabel;
@property (weak, nonatomic) IBOutlet NSNumber *badgeCount;

@property (nonatomic) BOOL didUpload;

@end

@implementation TDHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view insertSubview:self.bottomButtonHolderView aboveSubview:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadStarted:)
                                                 name:TDPostUploadStarted
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshPostsNotification:)
                                                 name:TDNotificationUpdate
                                               object:nil];

    [self.badgeCountLabel setFont:[TDConstants fontSemiBoldSized:11]];
    [self.badgeCountLabel.layer setCornerRadius:9.0];
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

- (void)viewWillDisappear:(BOOL)animated
{
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
- (void)fetchPostsUpStream {
    [[TDPostAPI sharedInstance] fetchPostsUpstream];
}

- (BOOL)fetchPostsDownStream {
    return [[TDPostAPI sharedInstance] fetchPostsDownstream];
}

- (NSArray *)postsForThisScreen {
    return [[TDPostAPI sharedInstance] getPosts];
}

- (NSNumber *)lowestIdOfPosts {
    return [[TDPostAPI sharedInstance] lowestIdOfPosts];
}

#pragma mark - Refresh Control
- (void)refreshControlUsed {
    debug NSLog(@"home-refreshControlUsed");
    [[TDPostAPI sharedInstance] fetchPostsUpstreamWithErrorHandlerStart:nil error:^{
        [self endRefreshControl];
        [[TDAppDelegate appDelegate] showToastWithText:@"Can't connect to server" type:kToastIconType_Warning payload:@{} delegate:nil];
    }];
}

#pragma mark - Frosted View behind Status bar
- (void)addFrostedBehindForStatusBar {
    UINavigationBar *statusBarBackground = [[UINavigationBar alloc] initWithFrame:statusBarFrame];
    statusBarBackground.barStyle = UIBarStyleDefault;
    statusBarBackground.translucent = YES;
    statusBarBackground.tag = 9920;
    [self.view insertSubview:statusBarBackground aboveSubview:self.tableView];
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
    self.bottomButtonHolderView.center = CGPointMake(self.bottomButtonHolderView.center.x,
                                                     [UIScreen mainScreen].bounds.size.height+(self.bottomButtonHolderView.frame.size.height/2.0)+1.0);
}

- (void)animateButtonsOnToScreen {
    debug NSLog(@"home-animateButtonsOnToScreen");

    // Hide 1st
    [self hideBottomButtons];

    UIDynamicAnimator* anAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator = anAnimator;
    
    UIGravityBehavior* gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:@[self.bottomButtonHolderView]];
    gravityBeahvior.magnitude = 4.0;
    gravityBeahvior.gravityDirection = CGVectorMake(0.0, -1.0);
    UICollisionBehavior* collisionBehavior1 = [[UICollisionBehavior alloc] initWithItems:@[self.bottomButtonHolderView]];
    collisionBehavior1.translatesReferenceBoundsIntoBoundary = NO;
    [collisionBehavior1 addBoundaryWithIdentifier:@"middle"
                                        fromPoint:CGPointMake(0.0,
                                                              origButtonViewCenter.y-self.bottomButtonHolderView.frame.size.height/2.0)
                                          toPoint:CGPointMake(self.view.frame.size.width,
                                                              origButtonViewCenter.y-self.bottomButtonHolderView.frame.size.height/2.0)];
    UIDynamicItemBehavior* propertiesBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.bottomButtonHolderView]];
    propertiesBehavior.elasticity = 0.4;
    propertiesBehavior.friction = 100.0;
    [self.animator addBehavior:gravityBeahvior];
    [self.animator addBehavior:collisionBehavior1];
    [self.animator addBehavior:propertiesBehavior];
}

#pragma mark - segues

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

- (void)showHomeController
{
    // stub to stop crash bug from segue: navigateToHomeFrom
}

#pragma mark - Post Delegate

- (void)userButtonPressedFromRow:(NSInteger)row {
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
    [self openProfile:post.user.userId];
}

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
    TDComment *comment = [post.comments objectAtIndex:commentNumber];
    TDUser *user = comment.user;
    [self openProfile:user.userId];
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
    UIViewController *top = [TDAppDelegate topMostController];
    if ([top class] == [UINavigationController class] || [top class] == [TDNavigationController class]) {
        for (UIViewController *vc in [[((UINavigationController *)top) viewControllers] reverseObjectEnumerator]) {
            if ([vc respondsToSelector:@selector(unwindToRoot)]) {
                [vc performSelector:@selector(unwindToRoot)];
                return;
            }
        }
    }
}

- (void)openProfile:(NSNumber *)userId {
    debug NSLog(@"gotoProfileForUser:%@", userId);

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

- (void)openDetailView:(NSNumber *)postId {
    [super openDetailView:postId];
}

/*- (void)openDetailView:(NSNumber *)postId {
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    vc.delegate = self;
    vc.postId = postId;
    [self.navigationController pushViewController:vc animated:YES];
} */

@end
