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

@property (nonatomic) TDUser *user;
@property (nonatomic) NSArray *posts;
@property (nonatomic) NSNumber *nextStart;

@end

@implementation TDUserProfileViewController

- (void)dealloc {
    self.user = nil;
    self.username = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    debug NSLog(@"inside TDUserProfileViewController:viewDidLoad");
    //needsProfileHeader = YES;

    [super viewDidLoad];

    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setBarStyle:UIBarStyleBlack];
    navigationBar.translucent = NO;
    self.tableView.contentInset = UIEdgeInsetsZero;
     
    // Background color
    self.tableView.backgroundColor = [TDConstants postViewBackgroundColor];
    
    // Title
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    [self.navigationItem setTitleView:self.titleLabel];

    // Bar Button Items
    switch (self.fromProfileType) {
        case kFromProfileScreenType_OwnProfileButton: {
            UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];     // 'X'
            self.navigationItem.leftBarButtonItem = leftBarButton;
            UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.settingsButton]; // Settings
            self.navigationItem.rightBarButtonItem = rightBarButton;
        }
        break;
        case kFromProfileScreenType_OwnProfile: {
            UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];    // <
            self.navigationItem.leftBarButtonItem = leftBarButton;
            self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

            if (self.needsProfileHeader) {
                UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.settingsButton]; // Settings
                self.navigationItem.rightBarButtonItem = rightBarButton;
            }
        }
        break;

        case kFromProfileScreenType_OtherUser:
        default:
        {
            UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];    // <
            self.navigationItem.leftBarButtonItem = leftBarButton;
            self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
        }
        break;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePost:) name:TDNotificationRemovePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserFollowingCount:) name:TDUpdateFollowingCount object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserFollowerCount:) name:TDUpdateFollowerCount object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    if (!self.posts || goneDownstream) {
        [self refreshPostsList];
        [self fetchPostsRefresh];
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
    self.posts  = nil;
    self.removingPosts = nil;
}

- (IBAction)settingsButtonHit:(id)sender {
    goneDownstream = YES;

    TDUserProfileEditViewController *vc = [[TDUserProfileEditViewController alloc] initWithNibName:@"TDUserProfileEditViewController" bundle:nil ];
    vc.profileUser = [[TDCurrentUser sharedInstance] currentUserObject];
    vc.fromProfileType = self.fromProfileType;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)closeButtonHit:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)unwindToRoot {
    // Looks weird but ensures the profile closes on both own profile page and when tapped from feed
    [self.navigationController popViewControllerAnimated:NO];
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}


#pragma mark - Posts

- (BOOL)hasMorePosts {
    return self.nextStart != nil;
}

- (TDPost *)postForRow:(NSInteger)row {
    
    NSInteger realRow = 0;
    if (self.needsProfileHeader) {
        realRow = row - 1; // 1 is for the header
    } else {
        realRow = row;
    }
    if (realRow < self.posts.count) {
        return [self.posts objectAtIndex:realRow];
    } else {
        return nil;
    }
}

- (void)fetchPostsRefresh {
    NSString *fetch = self.username ? self.username : [self.userId stringValue];
    if (self.needsProfileHeader) {
        [[TDPostAPI sharedInstance] fetchPostsForUser:fetch start:nil success:^(NSDictionary *response) {
            [self handleNextStart:[response objectForKey:@"next_start"]];
            [self handlePostsResponse:response fromStart:YES];
            self.user = [[TDUser alloc] initWithDictionary:[response valueForKeyPath:@"user"]];
            self.titleLabel.text = self.user.username;
        } error:^{
            [self endRefreshControl];
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
            self.loaded = YES;
            self.errorLoading = YES;
            [self.tableView reloadData];
        }];
    } else {
        [[TDPostAPI sharedInstance] fetchPRPostsForUser:fetch success:^(NSDictionary *response) {
            [self handleNextStart:[response objectForKey:@"next_start"]];
            [self handlePostsResponse:response fromStart:YES];
            self.user = [[TDUser alloc] initWithDictionary:[response valueForKeyPath:@"user"]];
            self.titleLabel.text = [NSString stringWithFormat:@"%@ %@", self.user.username, @"PRs"];
        } error:^{
            [self endRefreshControl];
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
            self.loaded = YES;
            self.errorLoading = YES;
            [self.tableView reloadData];
        }];
    }
}

- (void)handleNextStart:(NSNumber *)start {
    // start can be [NSNull null] here
    if (start && [[start class] isSubclassOfClass:[NSNumber class]]) {
        self.nextStart = start;
    } else {
        self.nextStart = nil;
    }
}

- (void)handlePostsResponse:(NSDictionary *)response fromStart:(BOOL)start {
    self.loaded = YES;
    self.errorLoading = NO;

    if (start) {
        self.posts = nil;
        self.removingPosts = nil;
    }

    NSMutableArray *newPosts;
    if (self.posts) {
        newPosts = [[NSMutableArray alloc] initWithArray:self.posts];
    } else {
        newPosts = [[NSMutableArray alloc] init];
    }

    for (NSDictionary *postObject in [response valueForKeyPath:@"posts"]) {
        TDPost *post = [[TDPost alloc] initWithDictionary:postObject];
        [post replaceUser:self.user];
        [newPosts addObject:post];
    }

    self.posts = newPosts;
    [self refreshPostsList];
}

- (BOOL)fetchMorePostsAtBottom {
    if (![self hasMorePosts]) {
        return NO;
    }
    NSString *fetch = self.username ? self.username : [self.userId stringValue];
    [[TDPostAPI sharedInstance] fetchPostsForUser:fetch start:self.nextStart success:^(NSDictionary *response) {
        [self handleNextStart:[response objectForKey:@"next_start"]];
        [self handlePostsResponse:response fromStart:NO];
    } error:^{
        self.loaded = YES;
        self.errorLoading = YES;
    }];
    return YES;
}

#pragma mark - TDPostsViewController overrides

- (TDUser *)getUser {
    return self.user;
}

- (NSArray *)postsForThisScreen {
    return self.posts;
}

#pragma mark - Refresh Control

- (void)refreshControlUsed {
    [self fetchPostsRefresh];
}

#pragma mark - PostView Delegate

- (void)userButtonPressedFromRow:(NSInteger)row {
    debug NSLog(@"profile-userButtonPressedFromRow:%ld %@ %@", (long)row, self.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);
    TDPost *post = [self postForRow:row];
    if (post) {
        [self showUserProfile:post.user];
    }
}

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
    debug NSLog(@"profile-userButtonPressedFromRow:%ld commentNumber:%ld, %@ %@", (long)row, (long)commentNumber, self.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);
    TDPost *post = [self postForRow:row];
    if (post) {
        TDComment *comment = [post commentAtIndex:commentNumber];
        if (comment) {
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
    vc.needsProfileHeader = YES;
    vc.fromProfileType = kFromProfileScreenType_OtherUser;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)updatePostsAfterUserUpdate:(NSNotification *)notification {
    if ([[[TDCurrentUser sharedInstance] currentUserObject].userId isEqualToNumber:self.userId]) {
        self.user = [[TDCurrentUser sharedInstance] currentUserObject];
    }

    for (TDPost *aPost in self.posts) {
        [aPost updateUserInfoFor:[[TDCurrentUser sharedInstance] currentUserObject]];
    }

    [self.tableView reloadData];
}

- (void)removePost:(NSNotification *)n {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
                [self.tableView reloadData];
            });
        }
    });
}

#pragma mark - Update Following Count after User follow notification
- (void)updateUserFollowingCount:(NSNotification *)notification {
     debug NSLog(@"%@ updateUserFollowingCount:%@", [self class], notification.object);
    if (self.getUser.userId == notification.object) {
        if ([notification.userInfo objectForKey:TD_INCREMENT_STRING]) {
            // We are following someone on their profile screen
            self.getUser.followingCount = [NSNumber numberWithLong:[self.getUser.followingCount integerValue] + [((NSNumber *)[notification.userInfo objectForKey:TD_INCREMENT_STRING]) integerValue]];
        } else if ([notification.userInfo objectForKey:TD_DECREMENT_STRING]) {
            self.getUser.followingCount = [NSNumber numberWithLong:[self.getUser.followingCount integerValue] - [((NSNumber *)[notification.userInfo objectForKey:TD_DECREMENT_STRING]) integerValue]];
        }
    }
    [self.tableView reloadData];
}

- (void)updateUserFollowerCount:(NSNotification *)notification {
     debug NSLog(@"%@ updateUserFollowerCount:%@", [self class], notification.object);
    if (notification.object == self.getUser.userId) {
        if ([notification.userInfo objectForKey:TD_INCREMENT_STRING]) {
            self.getUser.followerCount = [[NSNumber alloc] initWithInt:(self.getUser.followerCount.intValue+1)];
            self.getUser.following = YES;
        } else if ([notification.userInfo objectForKey:TD_DECREMENT_STRING]) {
            self.getUser.followerCount =[[NSNumber alloc] initWithInt:(self.getUser.followerCount.intValue-1)];
            self.getUser.following = NO;
        }
        [self.tableView reloadData];
    }
}
@end
