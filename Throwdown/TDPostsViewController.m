//
//  TDPostsViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPostsViewController.h"
#import "TDUserProfileViewController.h"

@interface TDPostsViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation TDPostsViewController

@synthesize posts;
@synthesize refreshControl;
@synthesize animator;
@synthesize profileUser;

- (void)viewDidLoad {
    [super viewDidLoad];

    tableOffset = CGPointZero;

    // Fix buttons for 3.5" screens
    self.bottomButtonHolderView.center = CGPointMake(self.bottomButtonHolderView.center.x,
                                                     [UIScreen mainScreen].bounds.size.height-self.bottomButtonHolderView.frame.size.height/2.0);
    origButtonViewCenter = self.bottomButtonHolderView.center;

    origRecordButtonCenter = self.recordButton.center;
    origNotificationButtonCenter = self.notificationButton.center;
    origProfileButtonCenter = self.profileButton.center;

    // Cell heights
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_POST_VIEW owner:self options:nil];
    TDPostView *cell = [topLevelObjects objectAtIndex:0];
    postViewHeight = cell.frame.size.height;
    cell = nil;
    topLevelObjects = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_LIKE_VIEW owner:self options:nil];
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
    TDActivityCell *profileCell = [topLevelObjects objectAtIndex:0];
    profileHeaderHeight = profileCell.frame.size.height;
    profileCell = nil;

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPostsList:) name:TDRefreshPostsNotification object:nil];
    [self refreshPostsList];
    [self fetchPostsUpStream];

    // Remember here so we don't lose this during statusBar animations
    statusBarFrame = [self.view convertRect: [UIApplication sharedApplication].statusBarFrame fromView: nil];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshControlUsed)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl setTintColor:[UIColor blackColor]];

    self.headerView = [[TDHomeHeaderView alloc] initWithTableView:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startSpinner:)
                                                 name:START_MAIN_SPINNER_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopSpinner:)
                                                 name:STOP_MAIN_SPINNER_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postDeleted:)
                                                 name:POST_DELETED_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logOutUser:)
                                                 name:LOG_OUT_NOTIFICATION
                                               object:nil];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {

    NSLog(@"dealloc:%@", [self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.posts = nil;
    self.refreshControl = nil;
    self.animator = nil;
    self.profileUser = nil;
}

# pragma mark - Figure out what's on each row
- (void)fetchPostsUpStream {
}

- (BOOL)fetchPostsDownStream {
    return NO;
}

- (NSArray *)postsForThisScreen {
    return nil;
}

- (NSNumber *)lowestIdOfPosts {
    return nil;
}

- (void)refreshPostsList:(NSNotification*)notification {

    // If it's not our user, we don't want it
    // because we're sharing the user array for profile users
    if (notification.userInfo && self.profileUser.userId) {
        if ([notification.userInfo isKindOfClass:[NSNumber class]]) {
            NSNumber *userId = (NSNumber *)notification.userInfo;
            if (![userId isEqualToNumber:self.profileUser.userId]) {
                return;
            }
        }
    }

    [self refreshPostsList];
}

/* Refreshes the list with currently downloaded posts */
- (void)refreshPostsList {

    // if this was from a bottom scroll refresh
    NSArray *visibleCells = [self.tableView visibleCells];
    [self stopSpinner];
    updatingAtBottom = NO;

    // If from refresh control
    [self endRefreshControl];

    posts = [self postsForThisScreen];
    [self.tableView reloadData];

    // If we had an offset, then go there
    if (!CGPointEqualToPoint(tableOffset, CGPointZero)) {

        // Double check that we're still at the bottom of the table
        // ie is a visible cell the bottom spinner?
        for (id cell in visibleCells) {
            if ([cell isKindOfClass:[TDActivityCell class]]) {
                [self.tableView setContentOffset:tableOffset
                                        animated:NO];
                break;
            }
        }
    }

    tableOffset = CGPointZero;
}

#pragma mark - refresh control

- (void)refreshControlUsed {
}

- (void)endRefreshControl {
    // uirefreshcontrol should be attached to a uitableviewcontroller - this stops a slight jutter
    [self.refreshControl performSelector:@selector(endRefreshing)
                              withObject:nil
                              afterDelay:0.1];

}

# pragma mark - table view delegate
-(void)updatePostsAtBottom
{
    NSLog(@"updatePostsAtBottom");

    if (updatingAtBottom) {
        return;
    }

    // Don't do if we're already at the bottom
    NSNumber *lowestId = [self lowestIdOfPosts];
    if ([lowestId isEqualToNumber:[NSNumber numberWithInt:1]]) {
        return;
    }

    // Don't do the bottom if the list is very short
    if ([self.posts count] < 2) {
        return;
    }

    updatingAtBottom = YES;
    [self startLoadingSpinner];

    if (![self fetchPostsDownStream]) {
        updatingAtBottom = NO;
        [self stopSpinner];
    }
}

- (void)reloadPosts:(NSNotification*)notification
{
    [self reloadPosts];
}

- (void)reloadPosts {
    NSLog(@"reload posts");
    self.posts = [self postsForThisScreen];
    [self.tableView reloadData];
}

#pragma mark - Delete Post
-(void)postDeleted:(NSNotification*)notification
{
    NSLog(@"delete notification:%@", notification);

    posts = [self postsForThisScreen];
    [self.tableView reloadData];
}

// 1 section per post, +1 if we need the Profile Header cell
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.posts count]+(showBottomSpinner ? 1 : 0)+(needsProfileHeader ? 1 : 0);
}

// Rows is 1 (for the video) + 1 for likes row + # of comments + 1 for like/comment buttons
// -1 if no likers
// +1 if total comments count > 2
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // 1st row for Profile Header
    if (needsProfileHeader && section == 0) {
        return 1;
    }

    // Last row with Activity
    if (showBottomSpinner && section == ([self.posts count]+(needsProfileHeader ? 1 : 0))) {
        return 1;
    }

    TDPost *post = (TDPost *)[self.posts objectAtIndex:(section-(needsProfileHeader ? 1 : 0))];
    NSInteger count;
    if ([post.likers count] > 0) {
        count = 3+([post.comments count] > 2 ? 2 : [post.comments count]);
    } else {
        count = 2+([post.comments count] > 2 ? 2 : [post.comments count]);
    }

    // +1 if total comments count > 2
    if ([post.commentsTotalCount intValue] > 2) {
        count++;
    }

    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // 1st row for Profile Header
    if (needsProfileHeader && indexPath.section == 0) {

        TDUserProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_PROFILE];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_PROFILE owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        if (self.profileUser) {
            cell.userNameLabel.text = self.profileUser.name;
        }

        return cell;
    }

    // Last row with Activity
    if (showBottomSpinner && indexPath.section == ([self.posts count]+(needsProfileHeader ? 1 : 0))) {

        TDActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_ACTIVITY];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_ACTIVITY owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        [cell startSpinner];
        return cell;
    }

    // The video
    TDPost *post = (TDPost *)[self.posts objectAtIndex:(indexPath.section-(needsProfileHeader ? 1 : 0))];

    if (indexPath.row == 0) {
        TDPostView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_POST_VIEW];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_POST_VIEW owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            //        cell.likeView.delegate = self;
            cell.delegate = self;
        }

        [cell setPost:post];
        cell.row = indexPath.section;
        return cell;
    }

    // Likes
    if ([post.likers count] > 0 && indexPath.row == 1) {
        TDLikeView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_LIKE_VIEW];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_LIKE_VIEW owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }

//        TDPost *post = (TDPost *)[self.posts objectAtIndex:indexPath.section];
        cell.row = indexPath.section;
        [cell setLike:post.liked];
        [cell setLikesArray:post.likers totalLikersCount:[post.likersTotalCount integerValue]];
        return cell;
    }

    // Like Comment Buttons - last row
    NSInteger totalRows = [self tableView:nil numberOfRowsInSection:indexPath.section];
    NSInteger lastRow = totalRows-1;

    if (indexPath.row == lastRow)
    {
        TDTwoButtonView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_COMMENT_VIEW];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_COMMENT_VIEW owner:self options:nil];
            cell = (TDTwoButtonView *)[topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }

        [cell setLike:post.liked];
        cell.row = indexPath.section;

        return cell;
    }

    // More Comments Row
    if ([post.commentsTotalCount intValue] > 2 && indexPath.row == (lastRow-1))
    {
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
        cell.origTimeFrame = cell.timeLabel.frame;
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSInteger commentNumber = indexPath.row - 1 - ([post.likers count] > 0 ? 1 : 0);
    cell.commentNumber = commentNumber;
    TDComment *comment = [post.comments objectAtIndex:commentNumber];
    [cell makeText:comment.body];
    [cell makeTime:comment.createdAt name:comment.user.username];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 1st row is Profile Header
    if (needsProfileHeader && indexPath.section == 0) {
        return profileHeaderHeight;
    }

    // Last row with Activity
    if (showBottomSpinner && indexPath.section == [self.posts count]) {
        return activityRowHeight;
    }

    if (indexPath.row == 0) {
        return postViewHeight;
    }

    TDPost *post = (TDPost *)[self.posts objectAtIndex:(indexPath.section-(needsProfileHeader ? 1 : 0))];
    if ([post.likers count] > 0 && indexPath.row == 1) {
        return likeHeight;
    }

    NSInteger lastRow = [self tableView:nil numberOfRowsInSection:indexPath.section]-1;

    // last row has to be 100 higher to allow press on Like / Comment
    if (indexPath.row == lastRow && indexPath.section == ([self.posts count]-1)) {
        return 100.0+commentButtonsHeight;
    }

    if (indexPath.row == lastRow) {
        return commentButtonsHeight;
    }

    if (indexPath.row == (lastRow - 1) && [post.commentsTotalCount intValue] > 2) {
        return moreCommentRowHeight;
    }

    // Comments
    NSInteger commentNumber = indexPath.row - 1 - ([post.likers count] > 0 ? 1 : 0);
    TDComment *comment = [post.comments objectAtIndex:commentNumber];
    return TDCommentCellProfileHeight + comment.messageHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.posts || [self.posts count] == 0 || (needsProfileHeader && indexPath.section == 0)) {
        return;
    }


    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    TDPost *post = (TDPost *)[self.posts objectAtIndex:indexPath.section];
    vc.post = post;
    vc.delegate = self;
    [self.navigationController pushViewController:vc
                                         animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.posts || [self.posts count] == 0) {
        return;
    }
    if ((scrollView.contentOffset.y+scrollView.frame.size.height) >= scrollView.contentSize.height-10.0) {
        [self updatePostsAtBottom];
    }
}

#pragma mark - TDPostView Delegate
-(void)postTouchedFromRow:(NSInteger)row
{
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row-(needsProfileHeader ? 1 : 0)];
    vc.post = post;
    vc.delegate = self;
    [self.navigationController pushViewController:vc
                                         animated:YES];
}

-(void)userButtonPressedFromRow:(NSInteger)row
{
}

#pragma mark - TDLikeCommentViewDelegates
-(void)likeButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-likeButtonPressedFromRow:%ld", (long)row);

    TDPost *post = (TDPost *)[self.posts objectAtIndex:row-(needsProfileHeader ? 1 : 0)];

    if (post.postId) {

        // Add the like for the update
        [post addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];

        // reload row
        [self.tableView reloadData];

        // Send to server
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api likePostWithId:post.postId];
    }
}

-(void)unLikeButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-unLikeButtonPressedFromRow:%ld", (long)row);

    TDPost *post = (TDPost *)[self.posts objectAtIndex:row-(needsProfileHeader ? 1 : 0)];

    if (post.postId) {

        // Remove the like for the update
        [post removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];

        // reload row
        [self.tableView reloadData];

        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api unLikePostWithId:post.postId];
    }
}

-(void)commentButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-commentButtonPressedFromRow:%ld", (long)row);

    // Goto Detail View
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row-(needsProfileHeader ? 1 : 0)];
    vc.post = post;
    [self.navigationController pushViewController:vc
                                         animated:YES];
}

-(void)miniLikeButtonPressedForLiker:(NSDictionary *)liker
{
    NSLog(@"Home-miniLikeButtonPressedForLiker:%@", liker);
}

# pragma mark - navigation

- (IBAction)profileButtonPressed:(id)sender {
/*    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.profileUser = [[TDCurrentUser sharedInstance] currentUserObject];

    vc.fromFrofileType = kFromProfileScreenType_OwnProfileButton;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController
                                            animated:YES
                                          completion:nil]; */

    self.profileButton.enabled = NO;

    // ActionSheet
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Send Feedback", @"Your Profile", nil];
    actionSheet.tag = 3546;
    [actionSheet showInView:self.view];
}

- (IBAction)logOutFeedbackButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    self.logOutFeedbackButton.enabled = NO;

    // ActionSheet
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Send Feedback", @"Log Out", nil];
    actionSheet.tag = 3546;
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 3546) {

        if (buttonIndex == 0)   // Feedback
        {
            [self displayFeedbackEmail];
        }

        if (buttonIndex == 1)   // Your Profile
        {
            TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
            vc.profileUser = [[TDCurrentUser sharedInstance] currentUserObject];

            vc.fromProfileType = kFromProfileScreenType_OwnProfileButton;
            vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
            navController.navigationBar.barStyle = UIBarStyleDefault;
            navController.navigationBar.translucent = YES;
            [self.navigationController presentViewController:navController
                                                    animated:YES
                                                  completion:nil];
        }

        self.profileButton.enabled = YES;
    }
}

#pragma mark - Email Feedback
- (NSString *) platform{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char *machine = malloc(size);
	sysctlbyname("hw.machine", machine, &size, NULL, 0);
	NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
	free(machine);
	return platform;
}

-(void)displayFeedbackEmail
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    [picker setSubject:@"Throwdown Feedback"];

    // Set up the recipients.
    NSArray *toRecipients = [NSArray arrayWithObjects:@"feedback@throwdown.us",
                             nil];

    [picker setToRecipients:toRecipients];

    // Fill out the email body text.
    NSMutableString *emailBody = [NSMutableString string];
    [emailBody appendString:[NSString stringWithFormat:@"Thanks for using Throwdown! We appreciate any thoughts you have on making it better or if you found a bug, let us know here."]];

    [emailBody appendString:[NSString stringWithFormat:@"\n\n\n\n\nApp Version:%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    [emailBody appendString:[NSString stringWithFormat:@"\nApp Build #:%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
    [emailBody appendString:[NSString stringWithFormat:@"\nOS:%@", [[UIDevice currentDevice] systemVersion]]];
    [emailBody appendString:[NSString stringWithFormat:@"\nModel:%@", [self platform]]];
    [emailBody appendString:[NSString stringWithFormat:@"\nID:%@", [TDCurrentUser sharedInstance].userId]];
    [emailBody appendString:[NSString stringWithFormat:@"\nName:%@", [TDCurrentUser sharedInstance].username]];

    [picker setMessageBody:emailBody isHTML:NO];

    // Present the mail composition interface.
    [self presentViewController:picker
                       animated:YES
                     completion:nil];
}

// The mail compose view controller delegate method
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - Log Out User Notification
-(void)logOutUser:(NSNotification *)notification
{
    NSLog(@"Home-logOutUser notification:%@", notification);

    [[TDUserAPI sharedInstance] logout];
    [self showWelcomeController];
}

- (void)showWelcomeController
{
    [self dismissViewControllerAnimated:NO completion:nil];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *welcomeViewController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];

    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = welcomeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - Loading Spinner
-(void)startSpinner:(NSNotification *)notification
{
    [self startLoadingSpinner];
}

-(void)stopSpinner:(NSNotification *)notification
{
    [self stopSpinner];
}

- (void)startLoadingSpinner {

    if (showBottomSpinner) {
        return;
    }

    tableOffset = CGPointMake(self.tableView.contentOffset.x,
                              self.tableView.contentOffset.y);//+activityRowHeight);

    showBottomSpinner = YES;

    // Add a bottom row
    [self.tableView reloadData];
}

- (void)stopSpinner {

    showBottomSpinner = NO;
    [self.tableView reloadData];
}

@end
