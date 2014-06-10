//
//  TDUserProfileViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserProfileViewController.h"
#import "TDPostAPI.h"
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDComment.h"
#import "TDViewControllerHelper.h"
#import "AFNetworking.h"
#import "TDCurrentUser.h"

@interface TDUserProfileViewController ()

@property (nonatomic) NSMutableArray *userPosts;
@property (nonatomic) TDUser *user;

@end

@implementation TDUserProfileViewController

- (void)dealloc {
    self.user = nil;
    self.userPosts = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TDUpdateWithUserChangeNotification
                                                  object:nil];
}

- (void)viewDidLoad {
    needsProfileHeader = YES;

    [super viewDidLoad];

    self.userPosts = [[NSMutableArray alloc] init];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.titleLabel.font = [TDConstants fontRegularSized:20];
    [self.navigationItem setTitleView:self.titleLabel];

    // Bar Button Items
    switch (self.fromProfileType) {
        case kFromProfileScreenType_OwnProfileButton:
        {
            UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];     // 'X'
            self.navigationItem.leftBarButtonItem = leftBarButton;
            UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.settingsButton]; // Settings
            self.navigationItem.rightBarButtonItem = rightBarButton;
        }
        break;
        case kFromProfileScreenType_OwnProfile:
        {
            UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];    // <
            self.navigationItem.leftBarButtonItem = leftBarButton;
            self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

            UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.settingsButton]; // Settings
            self.navigationItem.rightBarButtonItem = rightBarButton;
        }
        break;
        case kFromProfileScreenType_OtherUser:
        {
            UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];    // <
            self.navigationItem.leftBarButtonItem = leftBarButton;
            self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
        }
        break;

        default:
        break;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    if (!self.userPosts || goneDownstream) {
        [self refreshPostsList];
        [self fetchPostsUpStream];
    }
    goneDownstream = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.user = nil;
    self.userPosts  = nil;
}

- (IBAction)settingsButtonHit:(id)sender {
    goneDownstream = YES;

    TDUserProfileEditViewController *vc = [[TDUserProfileEditViewController alloc] initWithNibName:@"TDUserProfileEditViewController" bundle:nil ];
    vc.profileUser = [[TDCurrentUser sharedInstance] currentUserObject];
    vc.fromFrofileType = self.fromProfileType;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)closeButtonHit:(id)sender {
    self.closeButton.enabled = NO;
    [self.navigationController dismissViewControllerAnimated:YES
                                                  completion:nil];
}

- (void)unwindToRoot {
    // Looks weird but ensures the profile closes on both own profile page and when tapped from feed
    [self.navigationController popViewControllerAnimated:NO];
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}


#pragma mark - Posts

- (TDPost *)postForRow:(NSInteger)row {
    NSInteger realRow = row - (needsProfileHeader ? 1 : 0);
    return [self.posts objectAtIndex:realRow];
}

- (void)fetchPostsUpStream {
    debug NSLog(@"userprofile-fetchPostsUpStream");
    [[TDPostAPI sharedInstance] fetchPostsUpstreamForUser:self.userId success:^(NSDictionary *response) {
        [self handlePostsResponse:response fromStart:YES];
        [self endRefreshControl];
    } error:^{
        [self endRefreshControl];
        [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastIconType_Warning payload:@{} delegate:nil];
        self.loaded = YES;
        self.errorLoading = YES;
        [self.tableView reloadData];
    }];
}

- (BOOL)fetchPostsDownStream {
    if (noMorePostsAtBottom) {
        return NO;
    }
    debug NSLog(@"userprofile-fetchPostsDownStream");
    [[TDPostAPI sharedInstance] fetchPostsForUserUpstreamWithErrorHandlerStart:[self lowestIdOfPosts] userId:self.userId error:^{
        self.loaded = YES;
        self.errorLoading = YES;
    } success:^(NSDictionary *response) {
        [self handlePostsResponse:response fromStart:NO];
    }];
    return YES;
}

- (NSNumber *)lowestIdOfPosts {
    NSNumber *lowestId = [NSNumber numberWithLongLong:LONG_LONG_MAX];
    for (TDPost *post in self.userPosts) {
        if ([lowestId compare:post.postId] == NSOrderedDescending) {
            lowestId = post.postId;
        }
    }
    long lowest = [lowestId longValue]-1;
    lowestId = [NSNumber numberWithLong:lowest];
    return lowestId;
}

- (void)handlePostsResponse:(NSDictionary *)response fromStart:(BOOL)start {
    [self endRefreshControl];

    self.loaded = YES;
    self.errorLoading = NO;

    if (start) {
        self.userPosts = nil;
        // TODO update user info
        self.user = [[TDUser alloc] initWithDictionary:[response valueForKeyPath:@"user"]];
        self.titleLabel.text = self.user.username;
    }

    if (!self.userPosts) {
        self.userPosts = [[NSMutableArray alloc] init];
    }

    for (NSDictionary *postObject in [response valueForKeyPath:@"posts"]) {
        [self.userPosts addObject:[[TDPost alloc]initWithDictionary:postObject]];
    }
    if ([response valueForKey:@"next_start"] == [NSNull null]) {
        noMorePostsAtBottom = YES;
    }

    [self refreshPostsList];
}

#pragma mark - TDPostsViewController overrides

- (TDUser *)getUser {
    return self.user;
}

- (NSArray *)postsForThisScreen {
    debug NSLog(@"userprofile-postsForThisScreen");
    NSMutableArray *postsWithUsers = [NSMutableArray array];
    for (TDPost *aPost in self.userPosts) {
        [aPost replaceUser:self.user];
        [postsWithUsers addObject:aPost];
    }
    return postsWithUsers;
}


#pragma mark - Refresh Control

- (void)refreshControlUsed {
    [self fetchPostsUpStream];
}

#pragma mark - PostView Delegate

- (void)userButtonPressedFromRow:(NSInteger)row {
    debug NSLog(@"profile-userButtonPressedFromRow:%ld %@ %@", (long)row, self.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);

    if (self.posts && [self.posts count] > row) {
        TDPost *post = [self postForRow:row];
        [self showUserProfile:post.user];
    }
}

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
    debug NSLog(@"profile-userButtonPressedFromRow:%ld commentNumber:%ld, %@ %@", (long)row, (long)commentNumber, self.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);

    // row - 1 because we have a profile header at row 0
    if (self.posts && [self.posts count] > row - 1) {
        TDPost *post = [self postForRow:row];
        if (post.comments && [post.comments count] > commentNumber) {
            TDComment *comment = [post.comments objectAtIndex:commentNumber];
            [self showUserProfile:comment.user];
        }
    }
}

- (void)showUserProfile:(TDUser *)user {
    if ([self.userId isEqualToNumber:user.userId]) {
        // Same user - do nothing
        return;
    }

    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = user.userId;
    vc.fromProfileType = kFromProfileScreenType_OtherUser;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)updatePostsAfterUserUpdate:(NSNotification *)notification {
    debug NSLog(@"%@ updatePostsAfterUserUpdate:%@", [self class], [[TDCurrentUser sharedInstance] currentUserObject]);

    if ([[[TDCurrentUser sharedInstance] currentUserObject].userId isEqualToNumber:self.userId]) {
        self.user = [[TDCurrentUser sharedInstance] currentUserObject];
    }

    [self.tableView reloadData];
}

@end
