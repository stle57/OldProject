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
#import "TDPostUpload.h"
#import "TDConstants.h"
#import "TDUserAPI.h"
#import "VideoButtonSegue.h"
#import "VideoCloseSegue.h"
#import "TDLikeView.h"
#import "TDHomeHeaderView.h"
#import "TDActivityCell.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "TDUserProfileViewController.h"
#import <QuartzCore/QuartzCore.h>

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController ()
@property (weak, nonatomic) IBOutlet UILabel *badgeCountLabel;

@property (nonatomic) BOOL didUpload;

@end

@implementation TDHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view insertSubview:self.bottomButtonHolderView aboveSubview:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadStarted:)
                                                 name:@"TDPostUploadStarted"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshPostsNotification:)
                                                 name:TDNotificationUpdate
                                               object:nil];

    [self.badgeCountLabel setFont:[TDConstants fontLightSized:10]];
    [self.badgeCountLabel.layer setCornerRadius:7.0];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:NO];

    // Frosted behind status bar
    [self addFrostedBehindForStatusBar];
}

-(void)viewDidAppear:(BOOL)animated {
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

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self removeFrostedView];
}

-(void)viewDidLayoutSubviews {
    if (goneDownstream) {
        [self hideBottomButtons];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Posts
-(void)fetchPostsUpStream
{
    [[TDPostAPI sharedInstance] fetchPostsUpstream];
}

-(BOOL)fetchPostsDownStream
{
    return [[TDPostAPI sharedInstance] fetchPostsDownstream];
}

-(NSArray *)postsForThisScreen
{
    return [[TDPostAPI sharedInstance] getPosts];
}

-(NSNumber *)lowestIdOfPosts
{
    return [[TDPostAPI sharedInstance] lowestIdOfPosts];
}

#pragma mark - Refresh Control
- (void)refreshControlUsed {
    debug NSLog(@"home-refreshControlUsed");
    [[TDPostAPI sharedInstance] fetchPostsUpstreamWithErrorHandlerStart:nil error:^{
        [self endRefreshControl];
    }];
}

#pragma mark - Frosted View behind Status bar
-(void)addFrostedBehindForStatusBar
{
    UINavigationBar *statusBarBackground = [[UINavigationBar alloc] initWithFrame:statusBarFrame];
    statusBarBackground.barStyle = UIBarStyleDefault;
    statusBarBackground.translucent = YES;
    statusBarBackground.tag = 9920;
    [self.view insertSubview:statusBarBackground aboveSubview:self.tableView];
}

-(void)removeFrostedView
{
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
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];

    if (![[TDCurrentUser sharedInstance] isRegisteredForPush]) {
        self.didUpload = YES;
    }

    TDPostUpload *upload = (TDPostUpload *)notification.object;
    [self.headerView addUpload:upload];
}

#pragma mark - Bottom Buttons Bounce
-(void)hideBottomButtons
{
    // Place off screen
    self.bottomButtonHolderView.center = CGPointMake(self.bottomButtonHolderView.center.x,
                                                     [UIScreen mainScreen].bounds.size.height+(self.bottomButtonHolderView.frame.size.height/2.0)+1.0);
}

-(void)animateButtonsOnToScreen
{
    NSLog(@"home-animateButtonsOnToScreen");

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

#pragma mark - seques

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
-(void)userButtonPressedFromRow:(NSInteger)row
{
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
    [self gotoProfileForUser:post.user post:post];
}

-(void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber
{
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
    TDComment *comment = [post.comments objectAtIndex:commentNumber];
    TDUser *user = comment.user;

    [self gotoProfileForUser:user post:post];
}

-(void)gotoProfileForUser:(TDUser *)user post:(TDPost *)post
{
    NSLog(@"gotoProfileForUser:%@", user);

    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.profileUser = user;

    // Slightly different if current user
    if ([user.userId isEqualToNumber:[[TDCurrentUser sharedInstance] currentUserObject].userId]) {
        vc.fromProfileType = kFromProfileScreenType_OwnProfile;
    } else {
        vc.fromProfileType = kFromProfileScreenType_OtherUser;
    }
    [self.navigationController pushViewController:vc
                                         animated:YES];
}

#pragma mark - Notification Badge Count

- (void)refreshPostsNotification:(NSNotification *)notification {
    if (notification.userInfo && [notification.userInfo objectForKey:@"notificationCount"]) {
        NSNumber *count = [notification.userInfo objectForKey:@"notificationCount"];
        if ([count integerValue] > 0) {
            self.badgeCountLabel.hidden = NO;
            self.badgeCountLabel.text = [NSString stringWithFormat:@"%@", count];
            CGRect frame = self.badgeCountLabel.frame;
            if ([count integerValue] < 10) {
                frame.size.width = 14;
            } else if ([count integerValue] < 100) {
                frame.size.width = 20;
            } else if ([count integerValue] < 1000) {
                frame.size.width = 25;
            } else {
                frame.size.width = 30;
            }
            self.badgeCountLabel.frame = frame;
        } else {
            self.badgeCountLabel.hidden = YES;
        }
    }
}

@end
