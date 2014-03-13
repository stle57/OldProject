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
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDUserAPI.h"
#import "VideoButtonSegue.h"
#import "VideoCloseSegue.h"
#import "TDLikeCommentView.h"
#import "TDHomeHeaderView.h"

#define CELL_IDENTIFIER @"TDPostView"
#import "TDDetailViewController.h"

@interface TDHomeViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *posts;
    UIRefreshControl *refreshControl;
    BOOL goneDownstream;
    CGPoint origRecordButtonCenter;
    CGPoint origNotificationButtonCenter;
    CGPoint origProfileButtonCenter;
    UIDynamicAnimator *animator;
    CGFloat postViewHeight;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (nonatomic, retain) UIDynamicAnimator *animator;
@property (strong, nonatomic) TDHomeHeaderView *headerView;

@end

@implementation TDHomeViewController

@synthesize refreshControl;
@synthesize animator;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view insertSubview:self.recordButton aboveSubview:self.tableView];
    [self.view insertSubview:self.notificationButton aboveSubview:self.tableView];
    [self.view insertSubview:self.profileButton aboveSubview:self.tableView];
    
    // Fix buttons for 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.recordButton.center = CGPointMake(self.recordButton.center.x, [UIScreen mainScreen].bounds.size.height-(568.0-528.0));
        self.notificationButton.center = CGPointMake(self.notificationButton.center.x, [UIScreen mainScreen].bounds.size.height-(568.0-538.0));
        self.profileButton.center = CGPointMake(self.profileButton.center.x, [UIScreen mainScreen].bounds.size.height-(568.0-538.0));
    }
    
    origRecordButtonCenter = self.recordButton.center;
    origNotificationButtonCenter = self.notificationButton.center;
    origProfileButtonCenter = self.profileButton.center;

    // Cell height
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_POST_VIEW owner:self options:nil];
    TDPostView *cell = [topLevelObjects objectAtIndex:0];
    postViewHeight = cell.frame.size.height;
    cell = nil;
    
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
    [self.refreshControl setTintColor:[TDConstants brandingRedColor]];


//    self.header = 
//    self.progressIndicator = [[TDProgressIndicator alloc] initWithTableView:self.tableView postUpload:nil];
    self.headerView = [[TDHomeHeaderView alloc] initWithTableView:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStarted:) name:@"TDPostUploadStarted" object:nil];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.refreshControl = nil;
    self.animator = nil;
}

#pragma mark - video upload indicator

- (void)uploadStarted:(NSNotification *)notification {
    TDPostUpload *upload = (TDPostUpload *)notification.object;
    [self.headerView addUpload:upload];
}


#pragma mark - Bottom Buttons Bounce
-(void)hideBottomButtons
{
    // Place off screen
    [self.recordButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.notificationButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.profileButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    self.recordButton.center = CGPointMake(self.recordButton.center.x, origRecordButtonCenter.y+self.recordButton.frame.size.height*1.2);
    self.notificationButton.center = CGPointMake(self.notificationButton.center.x, origNotificationButtonCenter.y+self.recordButton.frame.size.height*1.2);
    self.profileButton.center = CGPointMake(self.profileButton.center.x, origProfileButtonCenter.y+self.recordButton.frame.size.height*1.2);
}

-(void)animateButtonsOnToScreen
{
    UIDynamicAnimator* anAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator = anAnimator;
    //self.animator.delegate = self;
    
    UIGravityBehavior* gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:@[self.recordButton, self.notificationButton, self.profileButton]];
    gravityBeahvior.magnitude = 4.0;
    gravityBeahvior.gravityDirection = CGVectorMake(0.0, -1.0);
    UICollisionBehavior* collisionBehavior1 = [[UICollisionBehavior alloc] initWithItems:@[self.recordButton]];
    collisionBehavior1.translatesReferenceBoundsIntoBoundary = NO;
    [collisionBehavior1 addBoundaryWithIdentifier:@"middle"
                                        fromPoint:CGPointMake(0.0,
                                                              origRecordButtonCenter.y-self.recordButton.frame.size.height/2.0)
                                          toPoint:CGPointMake(self.view.frame.size.width,
                                                              origRecordButtonCenter.y-self.recordButton.frame.size.height/2.0)];
    UICollisionBehavior* collisionBehavior2 = [[UICollisionBehavior alloc] initWithItems:@[self.notificationButton]];
    collisionBehavior2.translatesReferenceBoundsIntoBoundary = NO;
    [collisionBehavior2 addBoundaryWithIdentifier:@"middle"
                                        fromPoint:CGPointMake(0.0,
                                                              origNotificationButtonCenter.y-self.notificationButton.frame.size.height/2.0)
                                          toPoint:CGPointMake(self.view.frame.size.width,
                                                              origNotificationButtonCenter.y-self.notificationButton.frame.size.height/2.0)];
    UICollisionBehavior* collisionBehavior3 = [[UICollisionBehavior alloc] initWithItems:@[self.profileButton]];
    collisionBehavior3.translatesReferenceBoundsIntoBoundary = NO;
    [collisionBehavior3 addBoundaryWithIdentifier:@"middle"
                                        fromPoint:CGPointMake(0.0,
                                                              origProfileButtonCenter.y-self.profileButton.frame.size.height/2.0)
                                          toPoint:CGPointMake(self.view.frame.size.width,
                                                              origProfileButtonCenter.y-self.profileButton.frame.size.height/2.0)];
    UIDynamicItemBehavior* propertiesBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.recordButton, self.notificationButton, self.profileButton]];
    propertiesBehavior.elasticity = 0.3;
    [self.animator addBehavior:gravityBeahvior];
    [self.animator addBehavior:collisionBehavior1];
    [self.animator addBehavior:collisionBehavior2];
    [self.animator addBehavior:collisionBehavior3];
    [self.animator addBehavior:propertiesBehavior];
    
//    collisionBehavior.collisionDelegate = self;
}

#pragma mark - seques

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

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
    [[TDPostAPI sharedInstance] fetchPostsUpstream];
}

# pragma mark - table view delegate

- (void)refreshPostsList:(NSNotification*)notification {
    [self refreshPostsList];
}

/* Refreshes the list with currently downloaded posts */
- (void)refreshPostsList {
    debug NSLog(@"refresh post list");

    // uirefreshcontrol should be attached to a uitableviewcontroller - this stops a slight jutter
    [self.refreshControl performSelector:@selector(endRefreshing)
                              withObject:nil
                              afterDelay:0.1];

    posts = [[TDPostAPI sharedInstance] getPosts];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDPostView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_POST_VIEW];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_POST_VIEW owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.likeCommentView.delegate = self;
    }

    TDPost *post = (TDPost *)[posts objectAtIndex:indexPath.row];
    [cell setPost:post];
    cell.likeCommentView.row = indexPath.row;
    return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    DetailVC *dvc = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailVC"];
//    dvc.tweet = [self.tweetsArray objectAtIndex:indexPath.row];
//    [self.navigationController pushViewController:dvc animated:YES];
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return postViewHeight;
}

#pragma mark - TDLikeCommentViewDelegates
-(void)likeButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-likeButtonPressedFromRow:%ld", (long)row);
    
    TDPost *post = (TDPost *)[posts objectAtIndex:row];
    
    if (post.postId) {
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api likePostWithId:post.postId];
    }
}

-(void)unLikeButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-unLikeButtonPressedFromRow:%ld", (long)row);

    TDPost *post = (TDPost *)[posts objectAtIndex:row];

    if (post.postId) {
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api unLikePostWithId:post.postId];
    }
}

-(void)commentButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"Home-commentButtonPressedFromRow:%ld", (long)row);

    // Goto Detail View
    TDDetailViewController *vc = [[TDDetailViewController alloc] initWithNibName:@"TDDetailViewController" bundle:nil ];
    TDPost *post = (TDPost *)[posts objectAtIndex:row];
    vc.post = post;
    [self.navigationController pushViewController:vc
                                         animated:YES];
}

-(void)miniLikeButtonPressedForLiker:(NSDictionary *)liker
{
    NSLog(@"Home-miniLikeButtonPressedForLiker:%@", liker);
}

# pragma mark - navigation

// HACK to get log out to work
- (IBAction)profileButtonPressed:(id)sender {
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


@end
