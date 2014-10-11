//
//  TDPostsViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPostsViewController.h"
#import "TDUserProfileViewController.h"
#import "TDViewControllerHelper.h"
#import "TDAPIClient.h"
#import "TDUserAPI.h"
#import "TDHomeViewController.h"
#import "TDCustomRefreshControl.h"
#import "TDFollowViewController.h"
#import "TDInviteViewController.h"

static CGFloat const kWhiteBottomPadding = 6;
static CGFloat const kPostMargin = 22;
static CGFloat const kHeightOfStatusBar = 64.0;

@interface TDPostsViewController ()

@property (nonatomic) TDCustomRefreshControl *customRefreshControl;

@end

@implementation TDPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Cell heights
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_LIKE_VIEW owner:self options:nil];
    TDFeedLikeCommentCell *likeCell = [topLevelObjects objectAtIndex:0];
    likeHeight = likeCell.frame.size.height;
    likeCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_COMMENT_DETAILS owner:self options:nil];
    TDDetailsCommentsCell *commentDetailsCell = [topLevelObjects objectAtIndex:0];
    commentRowHeight = commentDetailsCell.frame.size.height;
    commentDetailsCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_MORE_COMMENTS owner:self options:nil];
    TDMoreComments *moreCommentsCell = [topLevelObjects objectAtIndex:0];
    moreCommentRowHeight = moreCommentsCell.frame.size.height;
    moreCommentsCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_ACTIVITY owner:self options:nil];
    TDActivityCell *activityCell = [topLevelObjects objectAtIndex:0];
    activityRowHeight = activityCell.frame.size.height;
    activityCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoPostsCell" owner:self options:nil];
    TDNoPostsCell *noPostsCell = [topLevelObjects objectAtIndex:0];
    noPostsHeight = noPostsCell.frame.size.height - kHeightOfStatusBar;
    noPostsCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_NO_MORE_POSTS owner:self options:nil];
    TDNoMorePostsCell *uploadMoreCell = [topLevelObjects objectAtIndex:0];
    uploadMoreHeight = uploadMoreCell.frame.size.height;
    uploadMoreCell = nil;

    self.loaded = NO;
    self.errorLoading = NO;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    // Background color
    self.tableView.backgroundColor = [TDConstants darkBackgroundColor];

    // Add refresh control
    self.customRefreshControl = [[TDCustomRefreshControl alloc] init];
    [self.customRefreshControl addTarget:self action:@selector(refreshControlUsed) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.customRefreshControl];

    // Remember here so we don't lose this during statusBar animations
    statusBarFrame = [self.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSpinner:) name:START_MAIN_SPINNER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopSpinner:) name:STOP_MAIN_SPINNER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOutUser:) name:LOG_OUT_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPostsList:) name:TDRefreshPostsNotification object:nil];

    [self refreshPostsList];
    [self fetchPostsRefresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    debug NSLog(@"dealloc:%@", [self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.removingPosts = nil;
    self.customRefreshControl = nil;
    self.userId = nil;
}

#pragma mark - Notices methods to override

- (NSUInteger)noticeCount {
    return 0;
}

- (TDNotice *)getNoticeAt:(NSUInteger)index {
    return nil;
}

- (BOOL)removeNoticeAt:(NSUInteger)index {
    return NO;
}


# pragma mark - Figure out what's on each row

// Override this to return the correct post for index row
- (TDPost *)postForRow:(NSInteger)row {
    return nil;
}

// Override this for updates at bottom of feed
- (BOOL)hasMorePosts {
    return NO;
}

// Override this to get posts from a pull-to-refresh
- (void)fetchPostsRefresh {
}

// Override this to get more posts at the bottom of the feed
// Returns BOOL, YES if fetch was initiated.
- (BOOL)fetchMorePostsAtBottom {
    return NO;
}

// Override this to return the current set of posts for the current feedƒ- 1
- (NSArray *)postsForThisScreen {
    return nil;
}

// Override to return user object if we're on profile view
- (TDUser *)getUser {
    return nil;
}

- (void)refreshPostsList:(NSNotification*)notification {
    // Notification comes in when posts have been fetched
    self.loaded = YES;
    self.errorLoading = NO;
    if (self.userId && notification.userInfo && [notification.userInfo objectForKey:@"userId"]) {
        NSNumber *userId = (NSNumber *)[notification.userInfo objectForKey:@"userId"];
        if (![userId isEqualToNumber:self.userId]) {
            return;
        }
    }

    [self refreshPostsList];
}

/* Refreshes the tableview with current posts list */
- (void)refreshPostsList {
    [self stopBottomLoadingSpinner];

    updatingAtBottom = NO;

    // If from refresh control
    [self endRefreshControl];
    [self.tableView reloadData];
}

#pragma mark - refresh control

- (void)refreshControlUsed {
}

- (void)endRefreshControl {
    debug NSLog(@"endRefreshControl");
    [self.customRefreshControl endRefreshing];
}

# pragma mark - table view delegate
- (void)updatePostsAtBottom {
    if (updatingAtBottom || ![self hasMorePosts]) {
        return;
    }
    debug NSLog(@"updatePostsAtBottom");

    updatingAtBottom = YES;
    [self startLoadingSpinner];

    if (![self fetchMorePostsAtBottom]) {
        updatingAtBottom = NO;
        [self stopBottomLoadingSpinner];
    }
}

- (void)reloadPosts:(NSNotification*)notification {
    [self reloadPosts];
}

- (void)reloadPosts {
    [self stopBottomLoadingSpinner];
    [self endRefreshControl];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSArray *posts = [self postsForThisScreen];

    if ([posts count] == 0) {
        return 1;
    }

    // 1 section per post, +1 if we need the Profile Header cell
    return [posts count] + [self noticeCount] + (showBottomSpinner ? 1 : 0) + ([self hasMorePosts] ? 0 : 1) + (self.profileType != kFeedProfileTypeNone ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // 'No Posts'
    if ([[self postsForThisScreen] count] == 0) {
        return 1;
    }

    // 1st row for Profile Header
    if (self.profileType != kFeedProfileTypeNone && section == 0) {
        return 1;
    }

    // One row per notice (each in it's own section)
    if ([self noticeCount] > 0 && section < [self noticeCount]) {
        return 1;
    }

    NSInteger row = [[self postsForThisScreen] count] + [self noticeCount] + (self.profileType != kFeedProfileTypeNone ? 1 : 0);

    // Last row with Activity
    if (showBottomSpinner && section == row) {
        return 1;
    }

    // Last row with no more posts
    if (![self hasMorePosts] && section == row) {
        return 1;
    }

    TDPost *post = [self postForRow:section];
    if (post) {
        // 1 for profile header and media/text
        // 1 for likes and comment button row
        // 0-2 comments
        // 1 'more comments' if total comments count > 2
        // 1 for bottom padding
        return  3 + ([post.commentsTotalCount integerValue] > 2 ? 3 : [post.commentsTotalCount integerValue]);
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger realRow = [[self postsForThisScreen] count] + [self noticeCount] + (self.profileType != kFeedProfileTypeNone ? 1 : 0);
    // 'Loading' or 'No Posts' cell
    if ([[self postsForThisScreen] count] == 0) {
        TDNoPostsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoPostsCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoPostsCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        
        if (!self.loaded) {
            cell.noPostsLabel.text = @"Loading…";
        } else if (self.errorLoading) {
            cell.noPostsLabel.text = @"Error loading posts";
        } else {
            cell.noPostsLabel.text = @"No posts yet";
        }

        // Center label (could be improved!)
        CGRect frame = cell.noPostsLabel.frame;
        frame.origin.y = SCREEN_HEIGHT/2 - self.navigationController.navigationBar.frame.size.height;
        cell.noPostsLabel.frame = frame;
        return cell;
    }

    // 1st row for Profile Header
    if (self.profileType != kFeedProfileTypeNone && indexPath.section == 0 && self.loaded && !self.errorLoading) {
        TDUserProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_PROFILE];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_PROFILE owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }

        TDUser *user = [self getUser];
        if (!user || self.profileType == kFeedProfileTypeNone) {
            [cell setUser:user withButton:UserProfileButtonTypeUnknown];
        } else if (self.profileType == kFeedProfileTypeOther) {
            [cell setUser:user withButton:(user.following ? UserProfileButtonTypeFollowing : UserProfileButtonTypeFollow)];
        } else {
            [cell setUser:user withButton:UserProfileButtonTypeInvite];
        }
        return cell;
    }

    // Notices on Home Screen
    if ([self noticeCount] > 0 && indexPath.section < [self noticeCount]) {
        TDNotice *notice = [self getNoticeAt:indexPath.section];
        TDNoticeViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoticeViewCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoticeViewCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell setNotice:notice];

        return cell;
    }

    // Last row with Activity
    if (showBottomSpinner && indexPath.section == realRow) {
        TDActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_ACTIVITY];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_ACTIVITY owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        [cell startSpinner];
        return cell;
    }

    // Last row if no more
    if (![self hasMorePosts] && indexPath.section == realRow) {
        TDNoMorePostsCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_NO_MORE_POSTS];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_NO_MORE_POSTS owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }

    // The actual post row
    TDPost *post = [self postForRow:indexPath.section];
    if (indexPath.row == 0) {
        TDPostView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_POST_VIEW];
        if (!cell) {
            cell = [[TDPostView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTIFIER_POST_VIEW];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        [cell setPost:post];
        cell.row = indexPath.section;
        return cell;
    }

    // Likes and comment button
    if (indexPath.row == 1) {
        TDFeedLikeCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_LIKE_VIEW];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_LIKE_VIEW owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        cell.row = indexPath.section;
        [cell setUserLiked:(post ? post.liked : NO) totalLikes:(post ? [post.likersTotalCount integerValue] : 0)];
        return cell;
    }

    // Like Comment Buttons - last row
    NSInteger totalRows = [self tableView:nil numberOfRowsInSection:indexPath.section];
    NSInteger lastRow = totalRows - 1;

    // More Comments Row
    if ([post.commentsTotalCount intValue] > 2 && indexPath.row == (lastRow - 1)) {
        TDMoreComments *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_MORE_COMMENTS];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_MORE_COMMENTS owner:self options:nil];
            cell = (TDMoreComments *)[topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell moreCount:[post.commentsTotalCount intValue]];
        return cell;
    }

    // Last row is just a blank row with white padding and grey margin
    if (indexPath.row == lastRow) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_POST_PADDING];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTIFIER_POST_PADDING];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [TDConstants darkBackgroundColor];

            UIView *white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, kWhiteBottomPadding)];
            white.backgroundColor = [UIColor whiteColor];
            [cell addSubview:white];

            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, kWhiteBottomPadding, [UIScreen mainScreen].bounds.size.width, 1 / [[UIScreen mainScreen] scale])];
            line.backgroundColor = [TDConstants darkBorderColor];
            [cell addSubview:line];
        }
        return cell;
    }

    // The comments are the remaining cells
    TDDetailsCommentsCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_COMMENT_DETAILS];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_COMMENT_DETAILS owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSInteger commentNumber = indexPath.row - 2;
    cell.commentNumber = commentNumber;
    cell.row = indexPath.section;
    TDComment *comment = [post commentAtIndex:commentNumber];
    if (comment) {
        [cell updateWithComment:comment showIcon:(commentNumber == 0)];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger postsCount = [[self postsForThisScreen] count];

    // Just 'No Posts' cell
    if (postsCount == 0) {
        return [UIScreen mainScreen].bounds.size.height - self.tableView.contentInset.top;
    }

    // 1st row is Profile Header
    if (self.profileType != kFeedProfileTypeNone && indexPath.section == 0) {
        TDUser *user = [self getUser];
        return (user ? [TDUserProfileCell heightForUserProfile:user] : 0);
    }

    NSUInteger noticeCount = [self noticeCount];
    if (noticeCount > 0 && indexPath.section < noticeCount) {
        return [TDNoticeViewCell heightForNotice:[self getNoticeAt:indexPath.section]];
    }

    NSInteger realSection = indexPath.section - [self noticeCount] - (self.profileType != kFeedProfileTypeNone ? 1 : 0);

    // Last row with Activity
    if (showBottomSpinner && realSection == postsCount) {
        return activityRowHeight;
    }

    // Last row with Load More
    if (![self hasMorePosts] && realSection == postsCount) {
        return uploadMoreHeight;
    }

    NSInteger lastRow = [self tableView:nil numberOfRowsInSection:indexPath.section] - 1;

    // Last row in each post section is just background padding and bottom line
    if (indexPath.row == lastRow) {
        return kPostMargin;
    }

    TDPost *post = [self postForRow:indexPath.section];
    if (!post) {
        return 0;
    }
    if (indexPath.row == 0) {
        return [TDPostView heightForPost:post];
    }

    // More comments
    if (indexPath.row == (lastRow - 1) && [post.commentsTotalCount intValue] > 2) {
        return moreCommentRowHeight;
    }

    NSArray *comments = [post commentsForFeed];

    // Like and Comment buttons
    if (indexPath.row == 1) {
        return likeHeight - ([comments count] > 0 ? 0 : kWhiteBottomPadding);
    }

    // Comments
    NSInteger commentNumber = indexPath.row - 2;
    if ([comments count] > commentNumber) {
        TDComment *comment = [comments objectAtIndex:commentNumber];

        if ((indexPath.row - 2) == ([comments count] - 1)) {
            return kCommentCellUserHeight + kCommentLastPadding + comment.messageHeight;
        }
        return kCommentCellUserHeight + kCommentPadding + comment.messageHeight;
    } else {
        return 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    if ([self noticeCount] > 0 && indexPath.section < [self noticeCount]) {
        TDNotice *notice = [self getNoticeAt:indexPath.section];
        if (notice) {
            [notice callAction];
            if (notice.dismissOnCall) {
                if ([self removeNoticeAt:indexPath.section]) {
                    [self.tableView reloadData];
                }
            }
        }
        return;
    }

    if (self.profileType != kFeedProfileTypeNone && indexPath.section == 0) {
        return;
    }

    TDPost *post = [self postForRow:indexPath.section];
    if (post) {
        [self openDetailView:post.postId];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.customRefreshControl containingScrollViewDidEndDragging:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.customRefreshControl containingScrollViewDidEndDragging:scrollView];

    if ([[self postsForThisScreen] count] == 0) {
        return;
    }

    if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height - 10.0) {
        [self updatePostsAtBottom];
    }
}

#pragma mark - TDPostViewDelegate

- (void)postTouchedFromRow:(NSInteger)row {
    TDPost *post = [self postForRow:row];
    if (post) {
        [self openDetailView:post.postId];
    }
}

- (void)userButtonPressedFromRow:(NSInteger)row {
}

#pragma mark - TDPostViewDelegate and TDDetailsCommentsCellDelegate

- (void)userProfilePressedWithId:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;
    vc.profileType = kFeedProfileTypeOther;
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - TDDetailsCommentsCellDelegate

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
}

#pragma mark - TDLikeCommentViewDelegates

- (void)likeButtonPressedFromRow:(NSInteger)row {   // 'row' is actually the section
    debug NSLog(@"Home-likeButtonPressedFromRow:%ld", (long)row);

    TDPost *post = [self postForRow:row];
    if (post && post.postId) {
        [post addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self.tableView reloadData];
        [[TDPostAPI sharedInstance] likePostWithId:post.postId];
    }
}

- (void)unLikeButtonPressedFromRow:(NSInteger)row {   // 'row' is actually the section
    debug NSLog(@"Home-unLikeButtonPressedFromRow:%ld", (long)row);

    TDPost *post = [self postForRow:row];
    if (post && post.postId) {
        [post removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self.tableView reloadData];
        [[TDPostAPI sharedInstance] unLikePostWithId:post.postId];
    }
}

- (void)commentButtonPressedFromRow:(NSInteger)row {
    debug NSLog(@"Home-commentButtonPressedFromRow:%ld", (long)row);
    TDPost *post = [self postForRow:row];
    [self openDetailView:post.postId];
}

- (void)miniLikeButtonPressedForLiker:(NSDictionary *)liker {
    debug NSLog(@"Home-miniLikeButtonPressedForLiker:%@", liker);
}

# pragma mark - navigation

- (IBAction)profileButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
    [self openUserProfile:[TDCurrentUser sharedInstance].userId];
}

#pragma mark - Open Different subviews

- (void)openUserProfile:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;
    vc.needsProfileHeader = YES;
    if ([userId isEqualToNumber:[TDCurrentUser sharedInstance].userId]) {
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
}

#pragma mark - Log Out User Notification
- (void)logOutUser:(NSNotification *)notification {
    debug NSLog(@"Home-logOutUser notification:%@", notification);

    [[TDUserAPI sharedInstance] logout];
    [self showWelcomeController];
}

- (void)showWelcomeController {
    [self dismissViewControllerAnimated:NO completion:nil];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *welcomeViewController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];

    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = welcomeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Loading Spinner
- (void)startSpinner:(NSNotification *)notification {
    [self startLoadingSpinner];
}

- (void)stopSpinner:(NSNotification *)notification {
    [self stopBottomLoadingSpinner];
}

- (void)startLoadingSpinner {
    if (showBottomSpinner) {
        return;
    }
    showBottomSpinner = YES;

    // Add a bottom row
    [self.tableView reloadData];
}

- (void)stopBottomLoadingSpinner {
    showBottomSpinner = NO;
    [self.tableView reloadData];
}

- (void)openDetailView:(NSNumber *)postId {
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    vc.postId = postId;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TDUserProfileCellDelegate

- (void)postsStatButtonPressed {
    debug NSLog(@"segue to posts button");
}
- (void)prStatButtonPressed {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = self.userId;
    vc.needsProfileHeader = NO;
    vc.profileType = kFeedProfileTypeNone;
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)followingStatButtonPressed {
    TDFollowViewController *vc = [[TDFollowViewController alloc] initWithNibName:@"TDFollowViewController" bundle:nil ];
    vc.followControllerType = kUserListType_Following;
    vc.profileUser = self.getUser;
    //vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

 - (void)followerStatButtonPressed {
     debug NSLog(@"segue to follwers list");
     TDFollowViewController *vc = [[TDFollowViewController alloc] initWithNibName:@"TDFollowViewController" bundle:nil ];
     vc.profileUser = self.getUser;
     vc.followControllerType = kUserListType_Followers;
     [self.navigationController pushViewController:vc animated:YES];
}

- (void)inviteButtonPressedFromRow:(NSInteger)tag {
    if (tag == kFollowButtonTag) {
        debug NSLog(@"follow this person");
        TDUserProfileCell * cell = nil;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        UITableViewCell * modifyCell = [self.tableView cellForRowAtIndexPath:indexPath];
        if(modifyCell != nil && [modifyCell isKindOfClass:[TDUserProfileCell class]]) {
            cell = (TDUserProfileCell*)modifyCell;
            // Got the cell, change the button
            UIImage * buttonImage = [UIImage imageNamed:@"btn-following.png"];
            [cell.inviteButton setImage:buttonImage forState:UIControlStateNormal];
            [cell.inviteButton setImage:[UIImage imageNamed:@"btn-following.png"] forState:UIControlStateHighlighted];
            [cell.inviteButton setImage:[UIImage imageNamed:@"btn-following.png"] forState:UIControlStateSelected];
            [cell.inviteButton setTag:kFollowingButtonTag];
            
        }
        // Send follow user to server
        NSNumber *userId = [self getUser].userId;
        [[TDUserAPI sharedInstance] followUser:userId callback:^(BOOL success) {
            if (success) {
                // Send notification to update user profile stat button-add
                debug NSLog(@"updating the following count of %@", [TDCurrentUser sharedInstance].currentUserObject);
//                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:userId userInfo:@{@"incrementCount": @1}];
                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[[TDCurrentUser sharedInstance] currentUserObject].userId userInfo:@{TD_INCREMENT_STRING: @1}];
                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowerCount object:userId userInfo:@{TD_INCREMENT_STRING: @1}];
            } else {
                [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
                // Switch button back
                if (cell != nil) {
                    // Got the cell, change the button
                    UIImage * buttonImage = [UIImage imageNamed:@"btn-follow.png"];
                    [cell.inviteButton setImage:buttonImage forState:UIControlStateNormal];
                    [cell.inviteButton setImage:[UIImage imageNamed:@"btn-follow-hit.png"] forState:UIControlStateHighlighted];
                    [cell.inviteButton setImage:[UIImage imageNamed:@"btn-follow-hit.png"] forState:UIControlStateSelected];
                    [cell.inviteButton setTag:kFollowButtonTag];
                }
            }
        }];
    } else if (tag == kFollowingButtonTag) {
        debug NSLog(@"unfollow this person");
        TDUserProfileCell *cell = nil;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        UITableViewCell * modifyCell = [self.tableView cellForRowAtIndexPath:indexPath];
        if(modifyCell != nil) {
            cell = (TDUserProfileCell*)modifyCell;
            // Got the cell, change the button
            UIImage * buttonImage = [UIImage imageNamed:@"btn-follow.png"];
            [cell.inviteButton setImage:buttonImage forState:UIControlStateNormal];
            [cell.inviteButton setImage:[UIImage imageNamed:@"btn-follow-hit.png"] forState:UIControlStateHighlighted];
            [cell.inviteButton setImage:[UIImage imageNamed:@"btn-follow-hit.png"] forState:UIControlStateSelected];
            [cell.inviteButton setTag:kFollowButtonTag];
            
        }
        // Send unfollow user to server
        NSNumber * userId = [self getUser].userId;
        [[TDUserAPI sharedInstance] unFollowUser:userId callback:^(BOOL success) {
            if (success) {
                debug NSLog(@"Successfully unfollwed user=%@", userId);
                // send notification to update user follow count-subtract
                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[TDCurrentUser sharedInstance].currentUserObject userInfo:@{TD_DECREMENT_STRING: @1}];
                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowerCount object:userId userInfo:@{TD_DECREMENT_STRING: @1}];
            } else {
                [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];

                //TODO: Display toast saying error processing, TRY AGAIN
                // Switch button back to cell
                UIImage * buttonImage = [UIImage imageNamed:@"btn-following.png"];
                [cell.inviteButton setImage:buttonImage forState:UIControlStateNormal];
                [cell.inviteButton setImage:[UIImage imageNamed:@"btn-following.png"] forState:UIControlStateHighlighted];
                [cell.inviteButton setImage:[UIImage imageNamed:@"btn-following.png"] forState:UIControlStateSelected];
                [cell.inviteButton setTag:kFollowingButtonTag];
            }
        }];
        
    } else if (tag == kInviteButtonTag) {
        TDInviteViewController *vc = [[TDInviteViewController alloc] initWithNibName:@"TDInviteViewController" bundle:nil ];
        vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        navController.navigationBar.barStyle = UIBarStyleDefault;
        navController.navigationBar.translucent = NO;
        [self.navigationController presentViewController:navController animated:YES completion:nil];

    }
}
@end
