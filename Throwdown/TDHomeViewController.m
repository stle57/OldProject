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

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *posts;
    UIRefreshControl *refreshControl;
    BOOL goneDownstream;
    CGPoint origRecordButtonCenter;
    CGPoint origNotificationButtonCenter;
    CGPoint origProfileButtonCenter;
    CGPoint origButtonViewCenter;
    UIDynamicAnimator *animator;
    CGFloat postViewHeight;
    CGFloat likeHeight;
    CGFloat commentButtonsHeight;
    CGFloat commentRowHeight;
    CGFloat moreCommentRowHeight;
    CGFloat activityRowHeight;
    BOOL updatingAtBottom;
    BOOL showBottomSpinner;
    CGPoint tableOffset;
}
@property (nonatomic, retain) NSArray *posts;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (weak, nonatomic) IBOutlet UIButton *logOutFeedbackButton;
@property (weak, nonatomic) IBOutlet UIView *bottomButtonHolderView;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (nonatomic, retain) UIDynamicAnimator *animator;
@property (strong, nonatomic) TDHomeHeaderView *headerView;
@property (strong, nonatomic) UIActivityIndicatorView *playerSpinner;


@end

@implementation TDHomeViewController

@synthesize posts;
@synthesize refreshControl;
@synthesize animator;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view insertSubview:self.bottomButtonHolderView aboveSubview:self.tableView];

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


    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPostsList:) name:@"TDRefreshPostsNotification" object:nil];
    [self refreshPostsList];
    [[TDPostAPI sharedInstance] fetchPostsUpstream];

    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshControlUsed)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
//    [self.refreshControl setTintColor:[TDConstants brandingRedColor]];
    [self.refreshControl setTintColor:[UIColor blackColor]];

    self.headerView = [[TDHomeHeaderView alloc] initWithTableView:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadStarted:)
                                                 name:@"TDPostUploadStarted"
                                               object:nil];
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

    // Frosted behind status bar
   [self addFrostedBehindForStatusBar];
}

-(void)viewWillAppear:(BOOL)animated {
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

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (goneDownstream) {
        [self animateButtonsOnToScreen];
    }
    goneDownstream = NO;
}

-(void)viewDidLayoutSubviews {
    if (goneDownstream) {
        [self hideBottomButtons];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

-(void)addFrostedBehindForStatusBar
{
    CGRect statusBarFrame = [self.view convertRect: [UIApplication sharedApplication].statusBarFrame fromView: nil];
    UINavigationBar *statusBarBackground = [[UINavigationBar alloc] initWithFrame:statusBarFrame];
    statusBarBackground.barStyle = UIBarStyleDefault;
    statusBarBackground.translucent = YES;
    [self.view insertSubview:statusBarBackground aboveSubview:self.tableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.posts = nil;
    self.refreshControl = nil;
    self.animator = nil;
}

#pragma mark - video upload indicator

- (void)uploadStarted:(NSNotification *)notification {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];

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
    // Hide 1st
    [self hideBottomButtons];

    // First position
/*    CGPoint firstPosition = CGPointMake(origButtonViewCenter.x,
                                        origButtonViewCenter.y-18.0);
    CGPoint secondPosition = CGPointMake(origButtonViewCenter.x,
                                         origButtonViewCenter.y+3.0);

    // Animate on
    [UIView animateWithDuration: 0.3
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{

                         self.bottomButtonHolderView.center = firstPosition;
                     }
                     completion:^(BOOL springInFinished){

                         if (springInFinished)
                         {
                             [UIView animateWithDuration: 0.2
                                                   delay: 0.0
                                                 options: UIViewAnimationOptionCurveLinear
                                              animations:^{

                                                  self.bottomButtonHolderView.center = secondPosition;
                                              }
                                              completion:^(BOOL springBackFinished){
                                                  
                                                  if (springBackFinished)
                                                  {
                                                      [UIView animateWithDuration: 0.1
                                                                            delay: 0.0
                                                                          options: UIViewAnimationOptionCurveLinear
                                                                       animations:^{

                                                                           self.bottomButtonHolderView.center = origButtonViewCenter;
                                                                       }
                                                                       completion:^(BOOL springDownFinished){

                                                                           if (springDownFinished)
                                                                           {
                                                                           }
                                                                       }];
                                                  }
                                              }];
                         }
                     }];
 */


    UIDynamicAnimator* anAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator = anAnimator;
    //self.animator.delegate = self;
    
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
    
//    collisionBehavior.collisionDelegate = self;
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

#pragma mark - refresh control

- (void)refreshControlUsed {
    debug NSLog(@"refreshControlUsed");
    [[TDPostAPI sharedInstance] fetchPostsUpstreamWithErrorHandlerStart:nil error:^{
        [self endRefreshControl];
    }];
}

- (void)endRefreshControl {
    // uirefreshcontrol should be attached to a uitableviewcontroller - this stops a slight jutter
    [self.refreshControl performSelector:@selector(endRefreshing)
                              withObject:nil
                              afterDelay:0.1];

}

# pragma mark - Figure out what's on each row

- (void)refreshPostsList:(NSNotification*)notification {
    [self refreshPostsList];
}

/* Refreshes the list with currently downloaded posts */
- (void)refreshPostsList {
    debug NSLog(@"refresh post list");

    // if this was from a bottom scroll refresh
    [self stopSpinner];
    updatingAtBottom = NO;

    // If from refresh control
    [self endRefreshControl];

    posts = [[TDPostAPI sharedInstance] getPosts];
    [self.tableView reloadData];

    // If we had an offset, then go there
    if (!CGPointEqualToPoint(tableOffset, CGPointZero)) {
        [self.tableView setContentOffset:tableOffset
                                animated:NO];
    }

    tableOffset = CGPointZero;
}

# pragma mark - table view delegate
-(void)updatePostsAtBottom
{
    if (updatingAtBottom) {
        return;
    }

    updatingAtBottom = YES;
    [self startLoadingSpinner];

    if (![[TDPostAPI sharedInstance] fetchPostsDownstream]) {
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
    self.posts = [[TDPostAPI sharedInstance] getPosts];
    [self.tableView reloadData];
}

// 1 section per post
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.posts count]+(showBottomSpinner ? 1 : 0);
}

// Rows is 1 (for the video) + 1 for likes row + # of comments + 1 for like/comment buttons
// -1 if no likers
// +1 if total comments count > 2
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Last row with Activity
    if (showBottomSpinner && section == [self.posts count]) {
        return 1;
    }

    TDPost *post = (TDPost *)[self.posts objectAtIndex:section];
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

    // Last row with Activity
    if (showBottomSpinner && indexPath.section == [self.posts count]) {

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
    TDPost *post = (TDPost *)[self.posts objectAtIndex:indexPath.section];

    if (indexPath.row == 0)
    {
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
    if ([post.likers count] > 0 && indexPath.row == 1)
    {
        TDLikeView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_LIKE_VIEW];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_LIKE_VIEW owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }

        TDPost *post = (TDPost *)[self.posts objectAtIndex:indexPath.section];
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

    NSInteger commentNumber = indexPath.row-1-([post.likers count] > 0 ? 1 : 0);
    TDComment *comment = [post.comments objectAtIndex:commentNumber];
    [cell makeText:comment.body];
    [cell makeTime:comment.createdAt name:comment.user.username];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Last row with Activity
    if (showBottomSpinner && indexPath.section == [self.posts count]) {
        return activityRowHeight;
    }

    if (indexPath.row == 0) {
        return postViewHeight;
    }

    TDPost *post = (TDPost *)[self.posts objectAtIndex:indexPath.section];
    if ([post.likers count] > 0 && indexPath.row == 1) {
        return likeHeight;
    }

    NSInteger lastRow = [self tableView:nil numberOfRowsInSection:indexPath.section]-1;

    if (indexPath.row == lastRow) {
        return commentButtonsHeight;
    }

    if (indexPath.row == (lastRow-1) && [post.commentsTotalCount intValue] > 2) {
        return moreCommentRowHeight;
    }

    // Comments
    NSInteger commentNumber = indexPath.row-1-([post.likers count] > 0 ? 1 : 0);
    TDComment *comment = [post.comments objectAtIndex:commentNumber];
    return 40.0+comment.messageHeight;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    TDPost *post = (TDPost *)[self.posts objectAtIndex:indexPath.section];
    vc.post = post;
    vc.delegate = self;
    [self.navigationController pushViewController:vc
                                         animated:YES];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
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
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
    vc.post = post;
    vc.delegate = self;
    [self.navigationController pushViewController:vc
                                         animated:YES];
}

#pragma mark - TDLikeCommentViewDelegates
-(void)likeButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-likeButtonPressedFromRow:%ld", (long)row);
    
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
    
    if (post.postId) {

        // Add the like for the update
        [post addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];

        // Send to server
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api likePostWithId:post.postId];
    }
}

-(void)unLikeButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-unLikeButtonPressedFromRow:%ld", (long)row);

    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];

    if (post.postId) {

        // Remove the like for the update
        [post removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];

        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api unLikePostWithId:post.postId];
    }
}

-(void)commentButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-commentButtonPressedFromRow:%ld", (long)row);

    // Goto Detail View
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
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
}

- (IBAction)logOutFeedbackButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    self.logOutFeedbackButton.enabled = NO;

    // ActionSheet
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Send Feedback"
                                                    otherButtonTitles:@"Log Out", nil];
    actionSheet.tag = 3546;
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // user clicked out / Cancel = 2
    // Feedback = 1
    // Log out = 0

    if (actionSheet.tag == 3546) {

        if (buttonIndex == 0)   // Feedback
        {
            [self displayFeedbackEmail];
        }

        if (buttonIndex == 1)   // Log out
        {
            [[TDUserAPI sharedInstance] logout];
            [self showWelcomeController];
        }

        self.logOutFeedbackButton.enabled = YES;
    }
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

#pragma mark - Email Feedback
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
    [emailBody appendString:[NSString stringWithFormat:@"\nModel:%@", [UIDevice currentDevice].model]];
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
                              self.tableView.contentOffset.y+activityRowHeight);

    showBottomSpinner = YES;

    // Add a bottom row
    [self.tableView reloadData];
}

- (void)stopSpinner {

    showBottomSpinner = NO;
    [self.tableView reloadData];
}

#pragma mark - Delete Post
/*-(void)postDeleted:(TDPost *)deletedPost
{
    // Remove the post from 'posts'
    if ([posts indexOfObject:deletedPost]) {
        NSMutableArray *mutablePosts = [NSMutableArray arrayWithArray:posts];
        [mutablePosts removeObject:deletedPost];
        posts = [NSArray arrayWithArray:mutablePosts];
        [self.tableView reloadData];
    }
} */

-(void)postDeleted:(NSNotification*)notification
{
    NSLog(@"Home-delete notification:%@", notification);

    NSNumber *deletedPostId = [notification object];

    NSLog(@"DELETE:%@", deletedPostId);

    NSLog(@"COUNT BEFORE:%lu", (unsigned long)[posts count]);

    // Remove the post from 'posts'
    NSMutableArray *mutablePosts = [NSMutableArray arrayWithCapacity:0];
    for (TDPost *post in posts) {
        if (![post.postId isEqualToNumber:deletedPostId]) {
            [mutablePosts addObject:post];
        }
    }
    self.posts = [NSArray arrayWithArray:mutablePosts];

    NSLog(@"COUNT AFTER:%lu", (unsigned long)[posts count]);
    [self.tableView reloadData];
}



@end
