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

static CGFloat const kHeightOfStatusBar = 64.0;
static NSInteger const kInviteButtonTag = 10001;
static CGFloat const kBioLabelInviteButtonPadding = 14;
static CGFloat const kInviteButtonStatButtonPadding = 25;

@interface TDPostsViewController ()

@property (nonatomic) TDCustomRefreshControl *customRefreshControl;

@end

@implementation TDPostsViewController

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
    inviteButtonHeight = profileCell.inviteButton.frame.size.height;
    statButtonHeight = profileCell.prButton.frame.size.height;
    profileCell = nil;
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
    self.tableView.backgroundColor = [TDConstants postViewBackgroundColor];

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
    self.animator = nil;
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

// 1 section per post, +1 if we need the Profile Header cell
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSArray *posts = [self postsForThisScreen];
    if ([posts count] == 0) {
        if (!self.loaded || self.errorLoading) {
            return 1 + [self noticeCount];
        }
        return (self.needsProfileHeader ? 2 : 1) + [self noticeCount];
    }
    
    return [posts count] + [self noticeCount] + (showBottomSpinner ? 1 : 0) + ([self hasMorePosts] ? 0 : 1) + (self.needsProfileHeader ? 1 : 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 1:
            return 15.0;
            break;
        default:
            return 0.;
            break;
    }
}

// Rows is 1 (for the video) + 1 for likes row + # of comments + 1 for like/comment buttons
// -1 if no likers
// +1 if total comments count > 2
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // 1st row for Profile Header
    if (self.needsProfileHeader && section == 0) {
        return 1;
    }

    if ([self noticeCount] > 0 && section < [self noticeCount]) {
        return 1;
    }

    // 'No Posts'
    if ([[self postsForThisScreen] count] == 0) {
        return 1;
    }

    NSInteger row = [[self postsForThisScreen] count] + [self noticeCount] + (self.needsProfileHeader ? 1 : 0);

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
        // +1 if total comments count > 2
        return  3 + ([post.commentsTotalCount integerValue] > 2 ? 3 : [post.commentsTotalCount integerValue]);
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger realRow = [[self postsForThisScreen] count] + [self noticeCount] + (self.needsProfileHeader ? 1 : 0);

    // debugging these table view buggers:
//    NSInteger postRow = indexPath.section - [self noticeCount] - (self.needsProfileHeader ? 1 : 0);
//    debug NSLog(@"s: %ld r: %ld n: %ld p: %lu rr: %ld pr: %ld", (long)indexPath.section, (long)indexPath.row, (long)[self noticeCount], (long)[[self postsForThisScreen] count], (long)realRow, (long)postRow);
    
    // 1st row for Profile Header
    if (self.needsProfileHeader && indexPath.section == 0 && self.loaded && !self.errorLoading) {
        debug NSLog(@"!!!!!!!!creating header");
        TDUserProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_PROFILE];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_PROFILE owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
            cell.origBioLabelRect = cell.bioLabel.frame;
        }

        cell.bioLabel.hidden = YES;
        cell.userImageView.hidden = YES;
        cell.bioLabel.frame = cell.origBioLabelRect;
        if ([self getUser]) {
            TDUser *user = [self getUser];
            cell.userNameLabel.text = user.name;
            cell.userImageView.hidden = NO;

            if ( (user.bio && ![user.bio isKindOfClass:[NSNull class]]) ) {
               cell.bioLabel.attributedText = (NSMutableAttributedString*)[TDViewControllerHelper makeParagraphedTextWithBioString:user.bio];
                [TDAppDelegate fixHeightOfThisLabel:cell.bioLabel];
                cell.bioLabel.hidden = NO;
                
                // Move the bio label frame down to the correct y position
                CGRect newBioLabelFrame = cell.bioLabel.frame;
                newBioLabelFrame.origin.y = topOfBioLabelInProfileHeader;
                cell.bioLabel.frame = newBioLabelFrame;
                
                // Now move the invite button down
                CGRect newInviteButtonFrame = cell.inviteButton.frame;
                newInviteButtonFrame.origin.y = cell.bioLabel.frame.origin.y + user.bioHeight+ kBioLabelInviteButtonPadding;
                cell.inviteButton.frame = newInviteButtonFrame;
                
                // Move the stat buttons down
                CGFloat yStatButtonPosition = newInviteButtonFrame.origin.y + newInviteButtonFrame.size.height + kInviteButtonStatButtonPadding;
                CGRect newPostButtonFrame = cell.postButton.frame;
                newPostButtonFrame.origin.y = yStatButtonPosition;
                cell.postButton.frame = newPostButtonFrame;
                
                CGRect newPrButtonFrame = cell.prButton.frame;
                newPrButtonFrame.origin.y = yStatButtonPosition;
                cell.prButton.frame = newPrButtonFrame;
                
                CGRect newFollowersFrame = cell.followerButton.frame;
                newFollowersFrame.origin.y = yStatButtonPosition;
                cell.followerButton.frame = newFollowersFrame;
                
                CGRect newFollowingFrame = cell.followingButton.frame;
                newFollowingFrame.origin.y = yStatButtonPosition;
                cell.followingButton.frame = newFollowingFrame;
                
                // Resize the cell height.
                CGRect newframe = cell.frame;
                newframe.size.height = [self tableView:tableView heightForRowAtIndexPath:indexPath];
                [cell setFrame:newframe];
            }
            
            if (![user hasDefaultPicture]) {
                [[TDAPIClient sharedInstance] setImage:@{@"imageView":cell.userImageView,
                                                         @"filename":user.picture,
                                                         @"width":@70,
                                                         @"height":@70}];
            }

            if( [self isKindOfClass:[TDUserProfileViewController class]]) {
                TDUserProfileViewController *vc = (TDUserProfileViewController*)self;
                if(vc.fromProfileType == kFromProfileScreenType_OtherUser) {
                    if(vc.getUser.following) // we are following this persion
                    {
                        UIImage * buttonImage = [UIImage imageNamed:@"btn-following.png"];
                        [cell.inviteButton setImage:buttonImage forState:UIControlStateNormal];
                        [cell.inviteButton setImage:[UIImage imageNamed:@"btn-following-hit.png"] forState:(UIControlStateHighlighted)];
                        [cell.inviteButton setImage:[UIImage imageNamed:@"btn-following-hit.png"] forState:(UIControlStateSelected)];
                        [cell.inviteButton setTag:kFollowingButtonTag];
                    } else {
                        if (vc.getUser.userId != [[TDCurrentUser sharedInstance] currentUserObject].userId) {
                            UIImage *buttonImage = [UIImage imageNamed:@"btn-follow.png"];
                            [cell.inviteButton setImage:buttonImage forState:(UIControlStateNormal)];
                            [cell.inviteButton setImage:[UIImage imageNamed:@"btn-follow-hit.png"] forState:(UIControlStateHighlighted)];
                            [cell.inviteButton setImage:[UIImage imageNamed:@"btn-follow-hit.png"] forState:(UIControlStateSelected)];
                            [cell.inviteButton setTag:kFollowButtonTag];
                        } else {
                            UIImage *buttonImage = [UIImage imageNamed:@"btn-invite-friends.png"];
                            [cell.inviteButton setImage:buttonImage forState:(UIControlStateNormal)];
                            [cell.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends-hit.png"] forState:(UIControlStateHighlighted)];
                            [cell.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends-hit.png"] forState:(UIControlStateSelected)];
                            [cell.inviteButton setTag:kInviteButtonTag];
                        }
                    }
                } else if (vc.fromProfileType == kFromProfileScreenType_OwnProfileButton) {
                    UIImage *buttonImage = [UIImage imageNamed:@"btn-invite-friends.png"];
                    [cell.inviteButton setImage:buttonImage forState:(UIControlStateNormal)];
                    [cell.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends-hit.png"] forState:(UIControlStateHighlighted)];
                    [cell.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends-hit.png"] forState:(UIControlStateSelected)];
                    [cell.inviteButton setTag:kInviteButtonTag];
                } else if (vc.fromProfileType == kFromProfileScreenType_OwnProfile) {
                    UIImage *buttonImage = [UIImage imageNamed:@"btn-invite-friends.png"];
                    [cell.inviteButton setImage:buttonImage forState:(UIControlStateNormal)];
                    [cell.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends-hit.png"] forState:(UIControlStateHighlighted)];
                    [cell.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends-hit.png"] forState:(UIControlStateSelected)];
                    [cell.inviteButton setTag:kInviteButtonTag];
                }
            }

            [cell modifyStatButtonAttributes:user];

            cell.whiteUnderView.frame = CGRectMake(cell.whiteUnderView.frame.origin.x,
                                                   cell.whiteUnderView.frame.origin.y,
                                                   cell.whiteUnderView.frame.size.width,
                                                   [self tableView:tableView heightForRowAtIndexPath:indexPath]);
            cell.bottomLine.frame = CGRectMake(cell.bottomLine.frame.origin.x,
                                               CGRectGetMaxY(cell.whiteUnderView.frame) - (1.0 / [[UIScreen mainScreen] scale]),
                                               cell.bottomLine.frame.size.width,
                                               (1.0 / [[UIScreen mainScreen] scale]));
        }
        cell.bottomLine.layer.borderWidth = TD_CELL_BORDER_WIDTH;
        cell.bottomLine.layer.borderColor = [[TDConstants commentTimeTextColor] CGColor];
        
        cell.whiteUnderView.layer.borderColor = [[TDConstants commentTimeTextColor] CGColor];
        
        debug NSLog(@"bottom width=%f", cell.bottomLine.layer.borderWidth);
        debug NSLog(@"white view width=%f", cell.whiteUnderView.layer.borderWidth);
        
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

        if (self.needsProfileHeader) {
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
        if (![self hasMorePosts] && indexPath.section == realRow) {
            TDNoMorePostsCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_NO_MORE_POSTS];
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_NO_MORE_POSTS owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
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
    TDComment *comment = [post commentAtIndex:commentNumber];
    if (comment) {
        [cell updateWithComment:comment];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 1st row is Profile Header
    if (self.needsProfileHeader == YES && indexPath.section == 0 && self.loaded && !self.errorLoading) {
        // min height is profileHeaderHeight
        if ([self getUser]) {
            CGFloat bioHeight = [self getUser].bioHeight;
            //spacing after bio, height of invite button, spacing after invite, height of stat buttons + extra padding for next section in view
            CGFloat padding = kBioLabelInviteButtonPadding + inviteButtonHeight + kInviteButtonStatButtonPadding + statButtonHeight;
            debug NSLog(@"bioHeight=%f", bioHeight);

            CGFloat cellHeight = topOfBioLabelInProfileHeader + bioHeight + (bioHeight > 0 ? padding : 5); // extra padding when we have a bio
            debug NSLog(@"   choosing between profileHeaderHeight=%f and cellHeight=%f", profileHeaderHeight, cellHeight);
            return fmaxf(profileHeaderHeight, cellHeight);
        } else {
            return 1.0;
        }
    }

    if ([self noticeCount] > 0 && indexPath.section < [self noticeCount]) {
        return [TDNoticeViewCell heightForNotice:[self getNoticeAt:indexPath.section]];
    }

    NSUInteger postsCount = [[self postsForThisScreen] count];

    // Just 'No Posts' cell
    if (postsCount == 0) {
        return [UIScreen mainScreen].bounds.size.height - self.tableView.contentInset.top;
    }

    NSInteger realRow = indexPath.section - [self noticeCount] - (self.needsProfileHeader ? 1 : 0);

    // Last row with Activity
    if (showBottomSpinner && realRow == postsCount) {
        return activityRowHeight;
    }

    // Last row with Load More
    if (![self hasMorePosts] && realRow == postsCount) {
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
    NSArray *comments = [post commentsForFeed];
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

    if (self.needsProfileHeader && indexPath.section == 0) {
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
    vc.needsProfileHeader = YES;
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
    vc.fromProfileType = kFromProfileScreenType_OwnProfile;
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
//                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[TDCurrentUser sharedInstance].currentUserObject userInfo:@{@"decreaseCount": @1}];
                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[TDCurrentUser sharedInstance].currentUserObject userInfo:@{TD_DECREMENT_STRING: @1}];
                [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowerCount object:userId userInfo:@{TD_DECREMENT_STRING: @1}];
            } else {
                debug NSLog(@"could not follow user=%@", userId);
                [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
                debug NSLog(@"could not follow user=%@", userId);
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
