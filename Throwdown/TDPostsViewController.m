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
#import "TDNoFollowingCell.h"
#import "TDLocationFeedViewController.h"
#import "TDTagFeedViewController.h"
#import "TDGuestInfoCell.h"
#import "TDWelcomeViewController.h"
#import "TDGuestUserJoinView.h"
#import "TDViewControllerHelper.h"

static CGFloat const kWhiteBottomPadding = 6;
static CGFloat const kPostMargin = 22;
static CGFloat const kReviewAppCellHeight = 128;
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
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowingCell" owner:self options:nil];
    TDNoFollowingCell *noFollowingCell = [topLevelObjects objectAtIndex:0];
    noFollowingHeight = noFollowingCell.frame.size.height - kHeightOfStatusBar;
    noFollowingCell = nil;

    self.loaded = NO;
    self.errorLoading = NO;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Background color

    // Add refresh control
    if (![self onGuestFeed]) {
        self.customRefreshControl = [[TDCustomRefreshControl alloc] init];
        [self.customRefreshControl addTarget:self action:@selector(refreshControlUsed) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.customRefreshControl];
    }
    // Remember here so we don't lose this during statusBar animations
    statusBarFrame = [self.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSpinner:) name:START_MAIN_SPINNER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopSpinner:) name:STOP_MAIN_SPINNER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOutUser:) name:LOG_OUT_NOTIFICATION object:nil];

    [self refreshPostsList];
    [self fetchPosts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [TDConstants darkBackgroundColor];

    [self.tableView reloadData];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
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

// Override this to get posts from a pull-to-refresh and to load posts onload
- (void)fetchPosts {
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

// Override this to return which feed we are on
- (BOOL)onAllFeed {
    return NO;
}

// Override this to return guest feed.
- (BOOL)onGuestFeed {
    return NO;
}

- (void)openGuestUserJoin:(kLabelType)type username:(NSString*)username{
}

// Override to return user object if we're on profile view
- (TDUser *)getUser {
    return nil;
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
    [self.customRefreshControl endRefreshing];
}

# pragma mark - table view delegate
- (void)updatePostsAtBottom {
    if (updatingAtBottom || ![self hasMorePosts]) {
        return;
    }
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
    [self endRefreshControl];
    [self stopBottomLoadingSpinner]; // reloads table
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSArray *posts = [self postsForThisScreen];

    BOOL hasAskedForGoal = YES;
    BOOL hasAskedForGoalsFinal = YES;
    if (![self onGuestFeed]) {
        hasAskedForGoal = [[TDCurrentUser sharedInstance] didAskForGoalsInitially];

        hasAskedForGoalsFinal = [[TDCurrentUser sharedInstance] didAskForGoalsFinal];
        if (!hasAskedForGoal && !hasAskedForGoalsFinal) {
            hasAskedForGoalsFinal = YES; // We don't want to add another section if both values are no.  So override this boolean
        }
    }

    if ([posts count] == 0) {
        return 1 + (self.profileType != kFeedProfileTypeNone ? 1 : 0);
    }

    return [posts count] + [self noticeCount] + (showBottomSpinner ? 1 : 0) + ([self hasMorePosts] ? 0 : 1) + (self.profileType != kFeedProfileTypeNone ? 1 : 0) + ([self onGuestFeed] ? 5 : 0) + ([[TDCurrentUser sharedInstance] isNewUser] ? 1 : 0) + (hasAskedForGoal ? 0 : 1) + (hasAskedForGoalsFinal ? 0 :1) + ((![self onGuestFeed] && [iRate sharedInstance].shouldPromptForRating) ? 1 :0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 1st row for Profile Header
    if (self.profileType != kFeedProfileTypeNone && section == 0) {
        return 1;
    }

    // 'No Posts'
    if ([[self postsForThisScreen] count] == 0) {
        return 1;
    }

    if ([self onGuestFeed] && (section == 0 || section == 1 || section == 7)) {
        return 1;
    }
    
    // One row per notice (each in it's own section)
    if ([self noticeCount] > 0 && section < [self noticeCount]) {
        return 1;
    }

    // 1st row for New User Header
    if ([[TDCurrentUser sharedInstance] isNewUser] && section == [self noticeCount] && [self isKindOfClass:[TDHomeViewController class]]) {
        return 1;
    }

    // 1st row for existing user - information row
    if ((![self onGuestFeed]) && (![[TDCurrentUser sharedInstance] didAskForGoalsInitially]) && section == [self noticeCount] && [[TDCurrentUser sharedInstance] isLoggedIn] && [self isKindOfClass:[TDHomeViewController class]]) {
        return 1;
    }

    if ((![self onGuestFeed]) && (![[TDCurrentUser sharedInstance] didAskForGoalsFinal]) && ([[TDCurrentUser sharedInstance] didAskForGoalsInitially]) && (section == [self noticeCount]) && [[TDCurrentUser sharedInstance] isLoggedIn] && [self isKindOfClass:[TDHomeViewController class]]) {
        return 1;
    }

    BOOL hasAskedForGoal = YES;
    BOOL hasAskedForGoalsFinal = YES;
    if (![self onGuestFeed]) {
        hasAskedForGoal = [[TDCurrentUser sharedInstance] didAskForGoalsInitially];

        hasAskedForGoalsFinal = [[TDCurrentUser sharedInstance] didAskForGoalsFinal];
        if (!hasAskedForGoal && !hasAskedForGoalsFinal) {
            hasAskedForGoalsFinal = YES; // We don't want to add another section if both values are no.  So override the boolean
        }
    }

    NSInteger realRow = [[self postsForThisScreen] count] + [self noticeCount] + (self.profileType != kFeedProfileTypeNone ? 1 : 0) + ([[TDCurrentUser sharedInstance] isNewUser] ? 1 : 0) + (hasAskedForGoal ? 0 : 1) + (hasAskedForGoalsFinal ? 0 :1) + ((![self onGuestFeed] && [iRate sharedInstance].shouldPromptForRating) ? 1: 0);

    // Last row with Activity
    if (showBottomSpinner && section == realRow) {
        return 1;
    }

    //When on guest feed, we've added 4 or 5 sections, to display the first 2 sections, 1 middle section, and 2 sections at the end
    if ([self onGuestFeed] &&  ((section == realRow+4)|| (section == realRow+5))) {
        // Returns number of rows for last two sections on guest feed.
        return 1;
    }


    NSInteger postNumber = section - [self noticeCount] - (self.profileType != kFeedProfileTypeNone ? 1 : 0) - ([self onGuestFeed] ? 5 : 0) - ([[TDCurrentUser sharedInstance] isNewUser] ? 1 : 0) - (hasAskedForGoal ? 0 : 1) - (hasAskedForGoalsFinal ? 0 :1);

    // Show the review cell if we've met the conditions
    if ((![self onGuestFeed] && [iRate sharedInstance].shouldPromptForRating) && ((postNumber) == TD_REVIEW_APP_CELL_POST_NUM)) {
        return 1;
    }

    // Last row with no more posts
    if ( ![self onGuestFeed] && ![self hasMorePosts] && section == realRow) {
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
    NSInteger realRow = [[self postsForThisScreen] count] + [self noticeCount] + (self.profileType != kFeedProfileTypeNone ? 1 : 0) + ([self onGuestFeed] ? 5 : 0 )+ ([[TDCurrentUser sharedInstance] isNewUser] ? 1 : 0) + ([[TDCurrentUser sharedInstance] didAskForGoalsInitially] ? 0 : 1) + ((![self onGuestFeed] && [iRate sharedInstance].shouldPromptForRating) ? 1 :0);

    // 1st row for Profile Header
    if (self.profileType != kFeedProfileTypeNone && indexPath.section == 0) {
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
        } else if ([[TDCurrentUser sharedInstance].userId isEqualToNumber:user.userId]) {
            [cell setUser:user withButton:UserProfileButtonTypeInvite];
        } else if (self.profileType == kFeedProfileTypeOther) {
                [cell setUser:user withButton:(user.following ? UserProfileButtonTypeFollowing : UserProfileButtonTypeFollow)];

        } else {
            [cell setUser:user withButton:UserProfileButtonTypeInvite];
        }

        return cell;
    }


    if ([self onGuestFeed] && indexPath.section == 0) {
        TDGuestInfoCell *cell =[tableView dequeueReusableCellWithIdentifier:@"TDGuestInfoCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGuestInfoCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        
        cell.label4.hidden = YES;
        cell.label1.hidden = NO;
        cell.label2.hidden = NO;
        cell.label3.hidden = NO;
        cell.button.hidden = NO;
        [cell setGuestUserCell];
        
        cell.bottomLine.hidden = NO;
        cell.topLine.hidden = NO;
        cell.topLine.frame = CGRectMake(0, 15, cell.topLine.frame.size.width, .5);
        cell.topLine.backgroundColor = [TDConstants darkBorderColor];
        
        return cell;
    }
    
    if ([self onGuestFeed] && indexPath.section == 1) {
        TDGuestInfoCell *cell =[tableView dequeueReusableCellWithIdentifier:@"TDGuestInfoCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGuestInfoCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        cell.label1.hidden = NO;
        cell.label2.hidden = YES;
        cell.label3.hidden = YES;
        cell.label4.hidden = YES;
        cell.button.hidden = YES;
        [cell setEditGoalsCell:NO];
        
        cell.bottomLine.hidden = YES;
        cell.topLine.hidden = YES;
        
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
        cell.noPostsLabel.hidden = NO;
        if (!self.loaded) {
            cell.noPostsLabel.text = @"Loading…";
        } else if (self.errorLoading) {
            cell.noPostsLabel.text = @"Error loading posts";
        } else {
            TDUser *user = [self getUser];
            if (user) {
                // We are in the TDUserProfileViewController
                if (![self onAllFeed] && ([user.followingCount intValue] == 0) && [self isKindOfClass:[TDHomeViewController class]]) {
                    TDNoFollowingCell *noFollowingCell = [self createNoFollowingCell:tableView];
                    return noFollowingCell;
                } else {
                    cell.noPostsLabel.text = @"No posts yet";
                }
            } else {
                if ( ![self onAllFeed] && ([[TDCurrentUser sharedInstance].currentUserObject.followingCount intValue] == 0) && [self isKindOfClass:[TDHomeViewController class]]) {
                    TDNoFollowingCell *noFollowingCell = [self createNoFollowingCell:tableView];
                    return noFollowingCell;
                } else {
                    cell.noPostsLabel.text = @"No posts yet";
                }
            }
        }

        CGFloat height = [UIScreen mainScreen].bounds.size.height - kHeightOfStatusBar - self.tableView.contentInset.top - (self.profileType == kFeedProfileTypeNone ? 0 : [TDUserProfileCell heightForUserProfile:[self getUser]]);
        cell.noPostsLabel.center = CGPointMake(cell.view.center.x, height / 2);
        return cell;
    }

    if ([self onGuestFeed] && indexPath.section == 7) {
        // Create a info cell
        TDGuestInfoCell *cell =[tableView dequeueReusableCellWithIdentifier:@"TDGuestInfoCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGuestInfoCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.label4.hidden = NO;
        cell.label1.hidden = NO;
        cell.label2.hidden = NO;
        cell.label3.hidden = NO;
        [cell setInfoCell];
        
        CGRect frame = cell.frame;
        frame.size.height = [TDGuestInfoCell heightForInfoCell];
        cell.frame = frame;
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


    if ((![self onGuestFeed]) && [[TDCurrentUser sharedInstance] isNewUser] && indexPath.section == [self noticeCount]  && [self isKindOfClass:[TDHomeViewController class]]) {
        TDGuestInfoCell *cell =[tableView dequeueReusableCellWithIdentifier:@"TDGuestInfoCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGuestInfoCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        cell.label4.hidden = YES;
        cell.label1.hidden = NO;
        cell.label2.hidden = NO;
        cell.label3.hidden = NO;
        cell.button.hidden = NO;
        cell.bottomLine.hidden = NO;
        cell.topLine.hidden = NO;
        [cell setNewUserCell:(![self noticeCount])];

        CGRect cellFrame = cell.frame;
        cellFrame.size.height = [TDGuestInfoCell heightForNewUserCell:(! [self noticeCount])];
        cell.frame = cellFrame;

        return cell;
    }

    if ((![self onGuestFeed]) && (![[TDCurrentUser sharedInstance] didAskForGoalsInitially]) && (indexPath.section == [self noticeCount]) && [[TDCurrentUser sharedInstance] isLoggedIn] && [self isKindOfClass:[TDHomeViewController class]]) {
        TDGuestInfoCell *cell =[tableView dequeueReusableCellWithIdentifier:@"TDGuestInfoCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGuestInfoCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        cell.label4.hidden = NO;
        cell.label1.hidden = NO;
        cell.label2.hidden = NO;
        cell.label3.hidden = NO;
        cell.button.hidden = NO;
        [cell setExistingUserCell:(![self noticeCount])];

        cell.bottomLine.hidden = NO;
        cell.topLine.hidden = NO;
        return cell;
    }

    if ((![self onGuestFeed]) &&(![[TDCurrentUser sharedInstance] didAskForGoalsFinal]) && ([[TDCurrentUser sharedInstance] didAskForGoalsInitially]) && (indexPath.section == [self noticeCount]) && [[TDCurrentUser sharedInstance] isLoggedIn] && [self isKindOfClass:[TDHomeViewController class]]) {
        TDGuestInfoCell *cell =[tableView dequeueReusableCellWithIdentifier:@"TDGuestInfoCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGuestInfoCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        cell.label1.hidden = NO;
        cell.label2.hidden = YES;
        cell.label3.hidden = YES;
        cell.label4.hidden = YES;
        cell.button.hidden = YES;
        [cell setEditGoalsCell:YES];

        cell.bottomLine.hidden = YES;
        cell.topLine.hidden = YES;

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

    // Creating second to last row on guest feed. 'realRow' represents the total number of sections in the feed
    if ([self onGuestFeed] && ![self hasMorePosts] && indexPath.section == realRow-2) {
        TDGuestInfoCell *cell =[tableView dequeueReusableCellWithIdentifier:@"TDGuestInfoCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGuestInfoCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        cell.label4.hidden = YES;
        cell.label1.hidden = YES;
        cell.label2.hidden = NO;
        cell.label3.hidden = YES;
        cell.button.hidden = NO;
        
        [cell setLastCell];
        
        CGRect cellFrame = cell.frame;
        cellFrame.size.height = [TDGuestInfoCell heightForLastCell];
        cell.frame = cellFrame;
        cell.bottomLine.hidden = NO;
        cell.topLine.hidden = NO;
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 1 / [[UIScreen mainScreen] scale])];
        line.backgroundColor = [TDConstants darkBorderColor];
        [cell addSubview:line];
        cell.topLine.frame = CGRectMake(0, 0, cell.topLine.frame.size.width, .5);
        cell.bottomLine.frame = CGRectMake(0, cell.frame.size.height - .5, cell.bottomLine.frame.size.width, .5);
        cell.bottomLine.backgroundColor = [TDConstants darkBorderColor];
        cell.topLine.backgroundColor = [TDConstants darkBorderColor];

        return cell;

    }

    // Creating LAST row on guest feed. 'realRow' represents the total number of sections in the feed
    if ([self onGuestFeed] && ![self hasMorePosts] && indexPath.section == realRow-1) {
        TDGuestInfoCell*cell =[tableView dequeueReusableCellWithIdentifier:@"TDGuestInfoCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGuestInfoCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        cell.label4.hidden = YES;
        cell.label1.hidden = YES;
        cell.label2.hidden = NO;
        cell.label3.hidden = YES;
        cell.button.hidden = NO;
        
        cell.backgroundColor = [TDConstants darkBackgroundColor];
        
        cell.bottomLine.hidden = YES;
        cell.topLine.hidden = YES;
        
        return cell;
    }

    BOOL hasAskedForGoal = YES;
    BOOL hasAskedForGoalsFinal = YES;
    if (![self onGuestFeed]) {
        hasAskedForGoal = [[TDCurrentUser sharedInstance] didAskForGoalsInitially];

        hasAskedForGoalsFinal = [[TDCurrentUser sharedInstance] didAskForGoalsFinal];
        if (!hasAskedForGoal && !hasAskedForGoalsFinal) {
            hasAskedForGoalsFinal = YES; // We don't want to add another section if both values are no.  So override this boolean
        }
    }

    NSInteger postNumber = indexPath.section - [self noticeCount] - (self.profileType != kFeedProfileTypeNone ? 1 : 0) - ([self onGuestFeed] ? 5 : 0) - ([[TDCurrentUser sharedInstance] isNewUser] ? 1 : 0) - (hasAskedForGoal ? 0 : 1) - (hasAskedForGoalsFinal ? 0 :1);

    if ((![self onGuestFeed] && [iRate sharedInstance].shouldPromptForRating)  && ((postNumber) == TD_REVIEW_APP_CELL_POST_NUM)) {
        TDReviewAppCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_REVIEW_APP_CELL];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_REVIEW_APP_CELL owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }
        return cell;
    }

    // Last row if no more
    if (![self onGuestFeed]  && ![self hasMorePosts] && (indexPath.section == realRow)) {
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
        [cell setPost:post showDate:![self onGuestFeed]];
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
        [cell updateWithComment:comment showIcon:(commentNumber == 0) showDate:![self onGuestFeed]];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger postsCount = [[self postsForThisScreen] count];
    // 1st row is Profile Header
    if (self.profileType != kFeedProfileTypeNone && indexPath.section == 0) {
        return [TDUserProfileCell heightForUserProfile:[self getUser]];
    }

    if ([self onGuestFeed] && indexPath.section == 0) {
        return [TDGuestInfoCell heightForGuestUserCell];
    }
    
    if ([self onGuestFeed] && indexPath.section == 1) {
        return [TDGuestInfoCell heightForEditGoalsCell];
    }
    
    if ([self onGuestFeed] && indexPath.section == 7 ) {
        return [TDGuestInfoCell heightForInfoCell];
    }
    
    // Just 'No Posts' cell
    if (postsCount == 0) {
        return [UIScreen mainScreen].bounds.size.height - kHeightOfStatusBar - self.tableView.contentInset.top - (self.profileType == kFeedProfileTypeNone ? 0 : [TDUserProfileCell heightForUserProfile:[self getUser]]);
    }
    
    NSUInteger noticeCount = [self noticeCount];
    if (noticeCount > 0 && indexPath.section < noticeCount) {
        return [TDNoticeViewCell heightForNotice:[self getNoticeAt:indexPath.section]];
    }

    if ((![self onGuestFeed]) && [[TDCurrentUser sharedInstance] isNewUser] && (indexPath.section == [self noticeCount])  && [self isKindOfClass:[TDHomeViewController class]]) {
        return [TDGuestInfoCell heightForNewUserCell:(![self noticeCount])];
    }

    if ((![self onGuestFeed]) && (![[TDCurrentUser sharedInstance] didAskForGoalsInitially]) && (indexPath.section == [self noticeCount]) && [[TDCurrentUser sharedInstance] isLoggedIn] && [self isKindOfClass:[TDHomeViewController class]]) {
        return [TDGuestInfoCell heightForExistingUserCell:(![self noticeCount])];
    }

    if ((![self onGuestFeed]) && (![[TDCurrentUser sharedInstance] didAskForGoalsFinal]) && ([[TDCurrentUser sharedInstance] didAskForGoalsInitially]) && (indexPath.section == [self noticeCount]) && [[TDCurrentUser sharedInstance] isLoggedIn] && [self isKindOfClass:[TDHomeViewController class]]) {
        return [TDGuestInfoCell heightForEditGoalsCell];
    }

    NSInteger realSection = indexPath.section - [self noticeCount] - (self.profileType != kFeedProfileTypeNone ? 1 : 0)- ([self onGuestFeed] ? 5 : 0) - ([[TDCurrentUser sharedInstance] isNewUser] ? 1 : 0) - ([[TDCurrentUser sharedInstance] didAskForGoalsInitially] ? 0 : 1);

    // Last row with Activity
    if (showBottomSpinner && realSection == postsCount) {
        return activityRowHeight;
    }

    // Second to last row on guest feed.  +4 because the second to last row is the 4th extra section to the guest feed.
    if ([self onGuestFeed] && ![self hasMorePosts] && (indexPath.section == postsCount+4)){
        return [TDGuestInfoCell heightForLastCell];
    }

    // Last row on guest feed.  +5 because the last row is the 5th EXTRA section to guest feed.
    if ([self onGuestFeed] && ![self hasMorePosts] && (indexPath.section == postsCount+5)) {
        return SCREEN_HEIGHT/3;
    }
    BOOL hasAskedForGoal = YES;
    BOOL hasAskedForGoalsFinal = YES;
    if (![self onGuestFeed]) {
        hasAskedForGoal = [[TDCurrentUser sharedInstance] didAskForGoalsInitially];

        hasAskedForGoalsFinal = [[TDCurrentUser sharedInstance] didAskForGoalsFinal];
        if (!hasAskedForGoal && !hasAskedForGoalsFinal) {
            hasAskedForGoalsFinal = YES; // We don't want to add another section if both values are no.  So override this boolean
        }
    }

    NSInteger postNumber = indexPath.section - [self noticeCount] - (self.profileType != kFeedProfileTypeNone ? 1 : 0) - ([self onGuestFeed] ? 5 : 0) - ([[TDCurrentUser sharedInstance] isNewUser] ? 1 : 0) - (hasAskedForGoal ? 0 : 1) - (hasAskedForGoalsFinal ? 0 :1);


    // We do realsection+1 because realSection is 0 based index
    if ((![self onGuestFeed] && [iRate sharedInstance].shouldPromptForRating) && ((postNumber) == TD_REVIEW_APP_CELL_POST_NUM) ){
        return kReviewAppCellHeight;
    }

    if ( ![self onGuestFeed] && ![self hasMorePosts] && realSection == postsCount) {
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

    if ((![self onGuestFeed]) && (![[TDCurrentUser sharedInstance] didAskForGoalsFinal]) && ([[TDCurrentUser sharedInstance] didAskForGoalsInitially]) && (indexPath.section == [self noticeCount]) && [[TDCurrentUser sharedInstance] isLoggedIn] && [self isKindOfClass:[TDHomeViewController class]]) {
        [self showGoalsAndInterestsController];
        return;
    }

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

    if ([self onGuestFeed] && indexPath.section == 0) {
        return;
    }
    
    if ([self onGuestFeed] && indexPath.section== 1) {
        [self showGoalsAndInterestsController];
        return;
    }
    
    if (self.profileType != kFeedProfileTypeNone && indexPath.section == 0) {
        return;
    }

    if ([self onGuestFeed]) {
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

    TDPost *post = [self postForRow:row];
    if (post) {
        if ([self onGuestFeed]) {
            [self openGuestUserJoin:kUserProfile_LabelType username:post.user.name];
            return;
        }
        [self openProfile:post.user.userId];
    }
}

- (void)horizontalScrollingStarted {
    self.tableView.scrollEnabled = NO;
}

- (void)horizontalScrollingEnded {
    self.tableView.scrollEnabled = YES;
}


#pragma mark - TDPostViewDelegate and TDDetailsCommentsCellDelegate

// When an @-mention or #hashtag is pressed in a text only.
- (void)userTappedURL:(NSURL *)url {
    if ([[url host] isEqualToString:@"user"]) {
        TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
        vc.userId = [NSNumber numberWithInteger:[[[url path] lastPathComponent] integerValue]];
        vc.profileType = kFeedProfileTypeOther;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (![self onGuestFeed] && [[url host] isEqualToString:@"tag"]) {
        TDTagFeedViewController *vc = [[TDTagFeedViewController alloc] initWithNibName:@"TDTagFeedViewController" bundle:nil ];
        vc.tagName = [[url path] lastPathComponent];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)userProfilePressedWithId:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;
    vc.profileType = kFeedProfileTypeOther;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)locationButtonPressedFromRow:(NSInteger)row {

    TDPost *post = [self postForRow:row];
    if ([self onGuestFeed]) {
        return;
    }

    if (post && post.locationId) {
        TDLocationFeedViewController *vc = [[TDLocationFeedViewController alloc] initWithNibName:@"TDLocationFeedViewController" bundle:nil];
        vc.locationId = post.locationId;
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - TDDetailsCommentsCellDelegate

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
}

#pragma mark - TDLikeCommentViewDelegates

- (void)likeButtonPressedFromRow:(NSInteger)row {   // 'row' is actually the section
    if ([self onGuestFeed]) {
        [self openGuestUserJoin:kLike_LabelType username:nil];
    } else {
        TDPost *post = [self postForRow:row];
        if (post && post.postId) {
            [post addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
            [self.tableView reloadData];
            [[TDPostAPI sharedInstance] likePostWithId:post.postId];
            if ([[iRate sharedInstance] shouldPromptForRating]) {
                [[iRate sharedInstance] promptIfNetworkAvailable];
            }
        }
    }
}

- (void)unLikeButtonPressedFromRow:(NSInteger)row {   // 'row' is actually the section
    TDPost *post = [self postForRow:row];
    if (post && post.postId) {
        [post removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self.tableView reloadData];
        [[TDPostAPI sharedInstance] unLikePostWithId:post.postId];
    }
}

- (void)commentButtonPressedFromRow:(NSInteger)row {
    if ([self onGuestFeed]) {
        [self openGuestUserJoin:kComment_LabelType username:nil];
    } else {
        TDPost *post = [self postForRow:row];
        [self openDetailView:post.postId];
    }
}

- (void)miniLikeButtonPressedForLiker:(NSDictionary *)liker {
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

- (void)showGoalsAndInterestsController {
    //[self dismissViewControllerAnimated:NO completion:nil];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];
    TDWelcomeViewController *viewController = navigationController.viewControllers[0];
    // setup "inner" view controller
    viewController.editViewOnly = YES;
    [self presentViewController:navigationController animated:YES completion:nil];

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

- (void)openProfile:(NSNumber *)userId {
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

- (void)openTagFeedController:(NSURL*)url {
    TDTagFeedViewController *vc = [[TDTagFeedViewController alloc] initWithNibName:@"TDTagFeedViewController" bundle:nil ];
    vc.tagName = [[url path] lastPathComponent];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TDUserProfileCellDelegate

- (void)postsStatButtonPressed {
    debug NSLog(@"segue to posts button");
}

- (void)prStatButtonPressed {
    if ([[self getUser].prCount intValue] != 0) {
        TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
        vc.userId = self.userId;
        vc.noProfileHeader = YES;
        vc.profileType = kFeedProfileTypeNone;
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (void)followingStatButtonPressed {
    TDFollowViewController *vc = [[TDFollowViewController alloc] initWithNibName:@"TDFollowViewController" bundle:nil ];
    vc.followControllerType = kUserListType_Following;
    vc.profileUser = self.getUser;
    //vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

 - (void)followerStatButtonPressed {
     TDFollowViewController *vc = [[TDFollowViewController alloc] initWithNibName:@"TDFollowViewController" bundle:nil ];
     vc.profileUser = self.getUser;
     vc.followControllerType = kUserListType_Followers;
     [self.navigationController pushViewController:vc animated:YES];
}

- (void)inviteButtonPressedFromRow:(NSInteger)tag {
    if (tag == kFollowButtonTag) {
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
        NSString *reportText = [NSString stringWithFormat:@"Unfollow @%@", [self getUser].username];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:reportText
                                                         otherButtonTitles:nil, nil];
        [actionSheet showInView:self.view];

    } else if (tag == kInviteButtonTag) {
        TDInviteViewController *vc = [[TDInviteViewController alloc] initWithNibName:@"TDInviteViewController" bundle:nil ];
        vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        navController.navigationBar.barStyle = UIBarStyleDefault;
        navController.navigationBar.translucent = NO;
        [self.navigationController presentViewController:navController animated:YES completion:nil];

    }
}

- (TDNoFollowingCell*)createNoFollowingCell:(UITableView*)tableView {
    TDNoFollowingCell *noFollowingCell = [tableView dequeueReusableCellWithIdentifier:@"TDNoFollowingCell"];
    if (!noFollowingCell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoFollowingCell" owner:self options:nil];
        noFollowingCell = [topLevelObjects objectAtIndex:0];
        noFollowingCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    noFollowingCell.backgroundColor = [UIColor whiteColor];
    self.tableView.backgroundColor = [UIColor whiteColor];
    return noFollowingCell;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    NSNumber *userId = nil;
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
    NSNumber * profileId = [self getUser].userId;
    [[TDUserAPI sharedInstance] unFollowUser:profileId callback:^(BOOL success) {
        if (success) {
            debug NSLog(@"Successfully unfollwed user=%@", userId);
            // send notification to update user follow count-subtract
            [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[TDCurrentUser sharedInstance].currentUserObject userInfo:@{TD_DECREMENT_STRING: @1}];
            [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowerCount object:profileId userInfo:@{TD_DECREMENT_STRING: @1}];
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
    
}

- (void)dismissButtonPressed {
    [self.tableView reloadData];
}

- (void)reloadTable {
    [self dismissButtonPressed];
}

@end
