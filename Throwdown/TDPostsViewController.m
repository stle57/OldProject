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
#import "TDHomeViewController.h"
#import "TDCustomRefreshControl.h"

static CGFloat const kHeightOfStatusBar = 65.0;

@interface TDPostsViewController ()

@property (nonatomic) TDCustomRefreshControl *customRefreshControl;

@end

@implementation TDPostsViewController

@synthesize posts;
@synthesize animator;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Cell heights
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_LIKE_VIEW owner:self options:nil];
    TDLikeView *likeCell = [topLevelObjects objectAtIndex:0];
    likeHeight = likeCell.frame.size.height;
    likeCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_COMMENT_VIEW owner:self options:nil];
    TDTwoButtonView *commentCell = [topLevelObjects objectAtIndex:0];
    commentButtonsHeight = commentCell.frame.size.height;
    commentCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDDetailsCommentsCell" owner:self options:nil];
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
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_PROFILE owner:self options:nil];
    TDUserProfileCell *profileCell = [topLevelObjects objectAtIndex:0];
    profileHeaderHeight = profileCell.frame.size.height;
    topOfBioLabelInProfileHeader = profileCell.bioLabel.frame.origin.y;
    profileCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoPostsCell" owner:self options:nil];
    TDNoPostsCell *noPostsCell = [topLevelObjects objectAtIndex:0];
    noPostsHeight = noPostsCell.frame.size.height - (needsProfileHeader ? profileHeaderHeight + kHeightOfStatusBar : 0);
    noPostsCell = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDUploadMoreCell" owner:self options:nil];
    TDUploadMoreCell *uploadMoreCell = [topLevelObjects objectAtIndex:0];
    uploadMoreHeight = uploadMoreCell.frame.size.height;
    uploadMoreCell = nil;

    self.loaded = NO;
    self.errorLoading = NO;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    // Add refresh control
    self.customRefreshControl = [[TDCustomRefreshControl alloc] init];
    [self.customRefreshControl addTarget:self action:@selector(refreshControlUsed) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.customRefreshControl];

    // Remember here so we don't lose this during statusBar animations
    statusBarFrame = [self.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    if ([self class] == [TDHomeViewController class]) {
        self.headerView = [[TDHomeHeaderView alloc] initWithTableView:self.tableView];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSpinner:) name:START_MAIN_SPINNER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopSpinner:) name:STOP_MAIN_SPINNER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOutUser:) name:LOG_OUT_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPostsList:) name:TDRefreshPostsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePost:) name:TDNotificationRemovePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePostFailed:) name:TDNotificationRemovePostFailed object:nil];

    [self refreshPostsList];
    [self fetchPostsUpStream];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // If we're coming back from the details screen, we need to
    // order the comments to only the most recent 2
    if ([self.posts count] > 0) {
        for (TDPost *post in self.posts) {
            [post orderCommentsForHomeScreen];
        }
    }

    [self.tableView reloadData];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    debug NSLog(@"dealloc:%@", [self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.posts = nil;
    self.removingPosts = nil;
    self.customRefreshControl = nil;
    self.animator = nil;
    self.userId = nil;
}

# pragma mark - Figure out what's on each row

- (TDPost *)postForRow:(NSInteger)row {
    NSInteger realRow = row - [self noticeCount] - (needsProfileHeader ? 1 : 0);
    if (realRow <= self.posts.count) {
        return [self.posts objectAtIndex:realRow];
    } else {
        return nil;
    }
}

- (NSUInteger)noticeCount {
    return 0;
}

- (void)fetchPostsUpStream {
}

- (BOOL)fetchPostsDownStream {
    return NO;
}

- (NSArray *)postsForThisScreen {
    return nil;
}

- (NSNumber *)lowestIdOfPosts {
    NSNumber *lowestId = [NSNumber numberWithLongLong:LONG_LONG_MAX];
    for (TDPost *post in posts) {
        if ([lowestId compare:post.postId] == NSOrderedDescending) {
            lowestId = post.postId;
        }
    }
    long lowest = [lowestId longValue]-1;
    lowestId = [NSNumber numberWithLong:lowest];
    return lowestId;
}

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

/* Refreshes the list with currently downloaded posts */
- (void)refreshPostsList {
    [self stopSpinner];

    updatingAtBottom = NO;

    // If from refresh control
    [self endRefreshControl];

    self.posts = [self postsForThisScreen];
    [self.tableView reloadData];
}

# pragma mark - handle removing posts

- (void)removePost:(NSNotification *)n {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL changeMade = NO;
        NSNumber *postId = (NSNumber *)[n.userInfo objectForKey:@"postId"];
        NSMutableArray *newList = [[NSMutableArray array] init];
        for (TDPost *post in self.posts) {
            if ([post.postId isEqualToNumber:postId]) {
                debug NSLog(@"removing post from vc with id %@", postId);
                changeMade = YES;
                if (!self.removingPosts) {
                    self.removingPosts = [[NSMutableDictionary alloc] init];
                }
                [self.removingPosts setObject:post forKey:post.postId];
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

- (void)removePostFailed:(NSNotification *)n {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSNumber *postId = (NSNumber *)[n.userInfo objectForKey:@"postId"];
        if (self.removingPosts && [self.removingPosts objectForKey:postId]) {
            NSMutableArray *newList = [[NSMutableArray array] initWithArray:self.posts];
            [newList addObject:[self.removingPosts objectForKey:postId]];
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postId" ascending:NO];
            self.posts = [newList sortedArrayUsingDescriptors:@[valueDescriptor]];
            // clean up cache
            [self.removingPosts removeObjectForKey:postId];
            if ([self.removingPosts count] == 0) {
                self.removingPosts = nil;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [TDViewControllerHelper showAlertMessage:@"There was a problem deleting the post, please try again." withTitle:nil];
            });
        }
    });
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
    if (updatingAtBottom || noMorePostsAtBottom) {
        return;
    }
    debug NSLog(@"updatePostsAtBottom");

    updatingAtBottom = YES;
    [self startLoadingSpinner];

    if (![self fetchPostsDownStream]) {
        noMorePostsAtBottom = YES;
        updatingAtBottom = NO;
        [self stopSpinner];
    }
}

- (void)reloadPosts:(NSNotification*)notification {
    [self reloadPosts];
}

- (void)reloadPosts {
    debug NSLog(@"reload posts");
    [self endRefreshControl];
    self.posts = [self postsForThisScreen];
    [self.tableView reloadData];
}

// 1 section per post, +1 if we need the Profile Header cell
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.posts count] == 0) {
        if (!self.loaded || self.errorLoading) {
            return 1 + [self noticeCount];
        }
        return (needsProfileHeader ? 2 : 1) + [self noticeCount];
    }

    return [self.posts count] + [self noticeCount] + (showBottomSpinner ? 1 : 0) + (noMorePostsAtBottom ? 1 : 0) + (needsProfileHeader ? 1 : 0);
}

// Rows is 1 (for the video) + 1 for likes row + # of comments + 1 for like/comment buttons
// -1 if no likers
// +1 if total comments count > 2
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // 1st row for Profile Header
    if (needsProfileHeader && section == 0) {
        return 1;
    }

    if ([self noticeCount] > 0 && section < [self noticeCount]) {
        return 1;
    }

    // 'No Posts'
    if ([self.posts count] == 0) {
        return 1;
    }

    NSInteger row = [self.posts count] + [self noticeCount] + (needsProfileHeader ? 1 : 0);

    // Last row with Activity
    if (showBottomSpinner && section == row) {
        return 1;
    }

    // Last row with Upload More
    if (noMorePostsAtBottom && section == row) {
        return 1;
    }

    TDPost *post = [self postForRow:section];
    if (post) {
        NSInteger count = 3 + ([post.comments count] > 2 ? 2 : [post.comments count]);
        // +1 if total comments count > 2
        if ([post.commentsTotalCount intValue] > 2) {
            count++;
        }
        return count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger realRow = [self.posts count] + [self noticeCount] + (needsProfileHeader ? 1 : 0);

    // debugging these table view buggers:
    // NSInteger postRow = indexPath.section - [self noticeCount] - (needsProfileHeader ? 1 : 0);
    // debug NSLog(@"s: %ld r: %ld n: %ld p: %lu rr: %ld pr: %ld", (long)indexPath.section, (long)indexPath.row, (long)[self noticeCount], (long)[self.posts count], (long)realRow, (long)postRow);

    // 1st row for Profile Header
    if (needsProfileHeader && indexPath.section == 0 && self.loaded && !self.errorLoading) {
        TDUserProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_PROFILE];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_PROFILE owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.origBioLabelRect = cell.bioLabel.frame;
        }

        cell.bioLabel.hidden = YES;
        cell.userImageView.hidden = YES;
        cell.bioLabel.frame = cell.origBioLabelRect;
        
        if ([self getUser]) {
            TDUser *user = [self getUser];
            cell.userNameLabel.text = user.name;
            cell.userImageView.hidden = NO;

            if (user.bio && ![user.bio isKindOfClass:[NSNull class]]) {
                cell.bioLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithString:user.bio];
                [TDAppDelegate fixHeightOfThisLabel:cell.bioLabel];
                cell.bioLabel.hidden = NO;
            }
            if (![user hasDefaultPicture]) {
                [[TDAPIClient sharedInstance] setImage:@{@"imageView":cell.userImageView,
                                                         @"filename":user.picture,
                                                         @"width":@60,
                                                         @"height":@60}];
            }

            cell.whiteUnderView.frame = CGRectMake(cell.whiteUnderView.frame.origin.x,
                                                   cell.whiteUnderView.frame.origin.y,
                                                   cell.whiteUnderView.frame.size.width,
                                                   [self tableView:tableView heightForRowAtIndexPath:indexPath] - 5.0);
            cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                               CGRectGetMaxY(cell.whiteUnderView.frame) - (1.0 / [[UIScreen mainScreen] scale]),
                                               cell.bottomLine.frame.size.width,
                                               (1.0 / [[UIScreen mainScreen] scale]));
        }

        return cell;
    }

    // Notices on Home Screen
    if ([self noticeCount] > 0 && indexPath.section < [self noticeCount]) {
        TDNotice *notice = [[TDPostAPI sharedInstance] getNoticeAt:indexPath.section];
        TDNoticeViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoticeViewCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoticeViewCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        [cell setNotice:notice];
        return cell;
    }

    // 'Loading' or 'No Posts' cell
    if ([self.posts count] == 0) {
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

        if (needsProfileHeader) {
            CGRect frame = cell.view.frame;
            // 20 is for status bar height
            frame.size.height = [UIScreen mainScreen].bounds.size.height - self.tableView.contentInset.top - (self.loaded ? profileHeaderHeight + 20 : 0);
            cell.view.frame = frame;
        }

        // Center label (could be improved!)
        cell.noPostsLabel.center = CGPointMake(cell.view.center.x, cell.view.frame.size.height / 2);

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
    if (noMorePostsAtBottom && indexPath.section == realRow) {

        TDUploadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDUploadMoreCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDUploadMoreCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.uploadMoreArrow.hidden = needsProfileHeader;
        return cell;
    }

    // The post
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

    // Likes
    if (indexPath.row == 1) {
        TDLikeView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_LIKE_VIEW];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_LIKE_VIEW owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        cell.row = indexPath.section;
        if (post) {
            [cell setLike:post.liked];
            [cell setLikesArray:post.likers totalLikersCount:[post.likersTotalCount integerValue]];
        } else {
            [cell setLike:NO];
            [cell setLikesArray:@[] totalLikersCount:0];
        }
        return cell;
    }

    // Like Comment Buttons - last row
    NSInteger totalRows = [self tableView:nil numberOfRowsInSection:indexPath.section];
    NSInteger lastRow = totalRows - 1;

    if (indexPath.row == lastRow) {
        TDTwoButtonView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_COMMENT_VIEW];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_COMMENT_VIEW owner:self options:nil];
            cell = (TDTwoButtonView *)[topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }

        [cell setLike:post.liked];
        cell.row = indexPath.section;
        if (post.kind == TDPostKindText) {
            cell.buttonBorder.hidden = NO;
        } else {
            cell.buttonBorder.hidden = [post.likersTotalCount intValue] == 0 && [post.commentsTotalCount intValue] == 0;
        }

        return cell;
    }

    // More Comments Row
    if ([post.commentsTotalCount intValue] > 2 && indexPath.row == (lastRow - 1)) {
        TDMoreComments *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_MORE_COMMENTS];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_MORE_COMMENTS owner:self options:nil];
            cell = (TDMoreComments *)[topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }

        [cell moreCount:[post.commentsTotalCount intValue]];

        return cell;
    }

    // The comments are the remaining cells
    TDDetailsCommentsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDDetailsCommentsCell"];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDDetailsCommentsCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSInteger commentNumber = indexPath.row - 2;
    cell.commentNumber = commentNumber;
    cell.row = indexPath.section;
    TDComment *comment = [post.comments objectAtIndex:commentNumber];
    [cell updateWithComment:comment];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 1st row is Profile Header
    if (needsProfileHeader && indexPath.section == 0 && self.loaded && !self.errorLoading) {
        // min height is profileHeaderHeight
        if ([self getUser]) {
            CGFloat bioHeight = [self getUser].bioHeight;
            CGFloat cellHeight = topOfBioLabelInProfileHeader + bioHeight + (bioHeight > 0 ? 20.0 : 15.0); // extra padding when we have a bio
            return fmaxf(profileHeaderHeight, cellHeight);
        } else {
            return 1.0;
        }
    }

    if ([self noticeCount] > 0 && indexPath.section < [self noticeCount]) {
        return [TDNoticeViewCell heightForNotice:[[TDPostAPI sharedInstance] getNoticeAt:indexPath.section]];
    }

    // Just 'No Posts' cell
    if ([self.posts count] == 0) {
        // 20 is for status bar height
        return [UIScreen mainScreen].bounds.size.height - self.tableView.contentInset.top - (self.loaded ? profileHeaderHeight + 20 : 0);
    }

    NSInteger realRow = indexPath.section - [self noticeCount] - (needsProfileHeader ? 1 : 0);

    // Last row with Activity
    if (showBottomSpinner && realRow == [self.posts count]) {
        return activityRowHeight;
    }

    // Last row with Load More
    if (noMorePostsAtBottom && realRow == [self.posts count]) {
        return uploadMoreHeight;
    }

    TDPost *post = [self postForRow:indexPath.section];
    if (indexPath.row == 0) {
        if (post) {
            return [TDPostView heightForPost:post];
        } else {
            return 0;
        }
    }

    if (indexPath.row == 1) {
        return [post.likers count] > 0 ? likeHeight : 0;
    }

    NSInteger lastRow = [self tableView:nil numberOfRowsInSection:indexPath.section] - 1;

    if (indexPath.row == lastRow) {
        return commentButtonsHeight;
    }

    if (indexPath.row == (lastRow - 1) && [post.commentsTotalCount intValue] > 2) {
        return moreCommentRowHeight;
    }

    // Comments
    NSInteger commentNumber = indexPath.row - 2;
    TDComment *comment = [post.comments objectAtIndex:commentNumber];

    if ((indexPath.row - 2) == ([post.comments count] - 1)) {
        return kCommentCellUserHeight + kCommentLastPadding + comment.messageHeight;
    }
    return kCommentCellUserHeight + kCommentPadding + comment.messageHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self noticeCount] > 0 && indexPath.section < [self noticeCount]) {
        TDNotice *notice = [[TDPostAPI sharedInstance] getNoticeAt:indexPath.section];
        if (notice) {
            [notice callAction];
            if (notice.dismissOnCall) {
                if ([[TDPostAPI sharedInstance] removeNoticeAt:indexPath.section]) {
                    [self.tableView reloadData];
                }
            }
        }
        return;
    }

    if (!self.posts || [self.posts count] == 0 || (needsProfileHeader && indexPath.section == 0)) {
        return;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:NO];

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

    if (!self.posts || [self.posts count] == 0) {
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
    vc.fromProfileType = kFromProfileScreenType_OtherUser;
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
        // Add the like for the update
        [post addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];

        [self reloadAllRowsButTopForSection:row];

        // Send to server
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api likePostWithId:post.postId];
    }
}

- (void)unLikeButtonPressedFromRow:(NSInteger)row {   // 'row' is actually the section
    debug NSLog(@"Home-unLikeButtonPressedFromRow:%ld", (long)row);

    TDPost *post = [self postForRow:row];
    if (post && post.postId) {

        // Remove the like for the update
        [post removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];

        [self reloadAllRowsButTopForSection:row];

        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api unLikePostWithId:post.postId];
    }
}

- (void)reloadAllRowsButTopForSection:(NSInteger)section {
    NSInteger totalRows = [self tableView:nil numberOfRowsInSection:section];
    NSMutableArray *rowArray = [NSMutableArray array];
    for (int i = 1; i < totalRows; i++) {
        [rowArray addObject:[NSIndexPath indexPathForRow:i
                                               inSection:section]];
    }
    [self.tableView reloadRowsAtIndexPaths:rowArray withRowAnimation:UITableViewRowAnimationFade];
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

    if (userId == [TDCurrentUser sharedInstance].userId)
    vc.fromProfileType = kFromProfileScreenType_OwnProfileButton;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
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

#pragma mark - Update Posts After User Change Notification
- (void)updatePostsAfterUserUpdate:(NSNotification *)notification {
    debug NSLog(@"%@ updatePostsAfterUserUpdate:%@", [self class], [[TDCurrentUser sharedInstance] currentUserObject]);

    for (TDPost *aPost in self.posts) {
        if ([[[TDCurrentUser sharedInstance] currentUserObject].userId isEqualToNumber:aPost.user.userId]) {
            [aPost replaceUserAndLikesAndCommentsWithUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        }
    }

    [self.tableView reloadData];
}

#pragma mark - Loading Spinner
- (void)startSpinner:(NSNotification *)notification {
    [self startLoadingSpinner];
}

- (void)stopSpinner:(NSNotification *)notification {
    [self stopSpinner];
}

- (void)startLoadingSpinner {
    if (showBottomSpinner) {
        return;
    }
    showBottomSpinner = YES;

    // Add a bottom row
    [self.tableView reloadData];
}

- (void)stopSpinner {
    showBottomSpinner = NO;
    [self.tableView reloadData];
}

- (void)openDetailView:(NSNumber *)postId {
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    vc.postId = postId;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)replacePostId:(NSNumber *)postId withPost:(TDPost *)post {
    debug NSLog(@"replacePostID:%@ Post:%@", postId, post);
    NSMutableArray *newPostsArray = [NSMutableArray arrayWithArray:self.posts];
    for (TDPost *aPost in self.posts) {
        if ([aPost.postId isEqualToNumber:postId]) {
            [newPostsArray replaceObjectAtIndex:[self.posts indexOfObject:aPost] withObject:post];
            self.posts = [NSArray arrayWithArray:newPostsArray];
            [self.tableView reloadData];
            break;
        }
    }
}

@end
