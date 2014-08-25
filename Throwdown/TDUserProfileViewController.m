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

@end

@implementation TDUserProfileViewController

- (void)dealloc {
    self.user = nil;
    self.username = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    needsProfileHeader = YES;

    [super viewDidLoad];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.titleLabel.font = [TDConstants fontRegularSized:20];
    [self.navigationItem setTitleView:self.titleLabel];

//    if (!self.fromProfileType) {
//        if (self.userId) {
//            if ([self.userId isEqualToNumber:[[TDCurrentUser sharedInstance] currentUserObject].userId]) {
//                self.fromProfileType = kFromProfileScreenType_OwnProfile;
//            } else {
//                self.fromProfileType = kFromProfileScreenType_OtherUser;
//            }
//        } else {
//            if ([self.username isEqualToString:[[TDCurrentUser sharedInstance] currentUserObject].username]) {
//                self.fromProfileType = kFromProfileScreenType_OwnProfile;
//            } else {
//                self.fromProfileType = kFromProfileScreenType_OtherUser;
//            }
//        }
//    }


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

            UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.settingsButton]; // Settings
            self.navigationItem.rightBarButtonItem = rightBarButton;
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    if (!self.posts || goneDownstream) {
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

- (TDPost *)postForRow:(NSInteger)row {
    NSInteger realRow = row - 1; // 1 is for the header
    if (realRow < self.posts.count) {
        return [self.posts objectAtIndex:realRow];
    } else {
        return nil;
    }
}

- (void)fetchPostsUpStream {
    debug NSLog(@"userprofile-fetchPostsUpStream");
    NSString *fetch = self.username ? self.username : [self.userId stringValue];
    [[TDPostAPI sharedInstance] fetchPostsUpstreamForUsername:fetch success:^(NSDictionary *response) {
        [self handlePostsResponse:response fromStart:YES];
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
    NSString *fetch = self.username ? self.username : [self.userId stringValue];
    [[TDPostAPI sharedInstance] fetchPostsForUserUpstreamWithErrorHandlerStart:[super lowestIdOfPosts] username:fetch error:^{
        self.loaded = YES;
        self.errorLoading = YES;
    } success:^(NSDictionary *response) {
        [self handlePostsResponse:response fromStart:NO];
    }];
    return YES;
}

- (void)handlePostsResponse:(NSDictionary *)response fromStart:(BOOL)start {
    self.loaded = YES;
    self.errorLoading = NO;

    if (start) {
        self.posts = nil;
        self.removingPosts = nil;
        // TODO update user info
        self.user = [[TDUser alloc] initWithDictionary:[response valueForKeyPath:@"user"]];
        self.titleLabel.text = self.user.username;
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
    if ([response valueForKey:@"next_start"] == [NSNull null]) {
        noMorePostsAtBottom = YES;
    }

    self.posts = newPosts;
    [self refreshPostsList];
}

#pragma mark - TDPostsViewController overrides

- (TDUser *)getUser {
    return self.user;
}

- (NSArray *)postsForThisScreen {
    debug NSLog(@"userprofile-postsForThisScreen");
    NSMutableArray *postsWithUsers = [NSMutableArray array];
    for (TDPost *aPost in self.posts) {
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
    TDPost *post = [self postForRow:row];
    if (post) {
        [self showUserProfile:post.user];
    }
}

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
    debug NSLog(@"profile-userButtonPressedFromRow:%ld commentNumber:%ld, %@ %@", (long)row, (long)commentNumber, self.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);

    TDPost *post = [self postForRow:row];
    if (post && post.comments && [post.comments count] > commentNumber) {
        TDComment *comment = [post.comments objectAtIndex:commentNumber];
        [self showUserProfile:comment.user];
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
