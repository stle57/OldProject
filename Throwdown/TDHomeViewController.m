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
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDUserAPI.h"
#import "VideoButtonSegue.h"
#import "VideoCloseSegue.h"
#import "TDLikeCommentView.h"

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *posts;
    UIRefreshControl *refreshControl;
    BOOL goneDownstream;
    CGPoint origRecordButtonCenter;
    CGPoint origNotificationButtonCenter;
    CGPoint origProfileButtonCenter;
    UIDynamicAnimator *animator;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (nonatomic, retain) UIDynamicAnimator *animator;

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

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPosts:) name:@"TDReloadPostsNotification" object:nil];
    [self reloadPosts];
    [[TDPostAPI sharedInstance] fetchPostsUpstream];
    
    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshControlUsed)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl setTintColor:[TDConstants brandingRedColor]];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (goneDownstream) {
        [self animateButtonsOnToScreen];
    }
    goneDownstream = NO;
}

-(void)viewDidLayoutSubviews
{
    if (goneDownstream) {
        [self hideBottomButtons];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.refreshControl = nil;
    self.animator = nil;
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
    propertiesBehavior.elasticity = 0.5;
    [self.animator addBehavior:gravityBeahvior];
    [self.animator addBehavior:collisionBehavior1];
    [self.animator addBehavior:collisionBehavior2];
    [self.animator addBehavior:collisionBehavior3];
    [self.animator addBehavior:propertiesBehavior];
    
//    collisionBehavior.collisionDelegate = self;
}

#pragma mark - video seque
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue isKindOfClass:[VideoButtonSegue class]]) {
        goneDownstream = YES;
    }
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    
    // Instantiate a new VideoCloseSegue
    VideoCloseSegue *segue = [[VideoCloseSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    return segue;
}

- (IBAction)unwindToHome:(UIStoryboardSegue *)sender {
    
}


#pragma mark - refresh control
-(void)refreshControlUsed
{
    debug NSLog(@"refreshControlUsed");
    
    [self reloadPosts];
    // uirefreshcontrol should be attached to a uitableviewcontroller - this stops a slight jutter
    [self.refreshControl performSelector:@selector(endRefreshing)
                              withObject:nil
                              afterDelay:0.1];
}

# pragma mark - table view delegate


- (void)reloadPosts:(NSNotification*)notification
{
    [self reloadPosts];
}

- (void)reloadPosts {
    debug NSLog(@"reload posts");
    posts = [[TDPostAPI sharedInstance] getPosts];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDPostView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER owner:self options:nil];
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
    return 404.0f+48.0;
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
}

# pragma mark - navigation

// HACK to get log out to work
- (IBAction)profileButtonPressed:(id)sender {
    [[TDUserAPI sharedInstance] logout];
    [self showWelcomeController];
}

- (void)returnToRoot {
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
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
