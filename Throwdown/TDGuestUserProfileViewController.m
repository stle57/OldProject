//
//  TDGuestUserProfileViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 12/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//
#import "TDGuestUserProfileViewController.h"
#import "TDViewControllerHelper.h"
#import "TDLocation.h"
#import "TDSignupStepOneViewController.h"
#import "TDGuestUserJoinView.h"
#import "TDAPIClient.h"
#import "TDAnalytics.h"
#import "TDLoginViewController.h"

@interface TDGuestUserProfileViewController ()
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *findButton;
@property (nonatomic) NSArray *posts;
@property (nonatomic) NSNumber *nextStart;
@property (nonatomic) UIView *headerView;
@property (nonatomic) UIView *disableViewOverlay;
@property (nonatomic) NSMutableArray *goalsList;
@property (nonatomic) NSMutableArray *interestsList;
@property (nonatomic) TDUser *user;
@property (nonatomic) BOOL initialLoadDone;
@property (nonatomic) NSDictionary *initialPosts;
@property (nonatomic) CGFloat previousScrollViewYOffset;

@end


@implementation TDGuestUserProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil goalsList:(NSMutableArray*)goalsList interestsLists:(NSMutableArray*)interestsList guestPosts:(NSDictionary*)guestPosts {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.goalsList = [goalsList copy];
        self.interestsList = [interestsList copy];
        self.initialPosts = guestPosts;
        [self handleNextStart:[self.initialPosts objectForKey:@"next_start"]];
        [self handlePostsResponse:self.initialPosts fromStart:YES];
    }
    self.initialLoadDone = YES;

    return self;
}

- (void)dealloc {
    self.headerView = nil;
    self.interestsList = nil;
    self.goalsList = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TDAnalytics sharedInstance] logEvent:@"guest_user_view"];

    self.view.backgroundColor = [TDConstants lightBackgroundColor];
    self.view.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height+ self.navigationController.navigationBar.frame.size.height, SCREEN_WIDTH, SCREEN_HEIGHT);
    // Background
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setBarStyle:UIBarStyleBlack];
    navigationBar.translucent = NO;

    // Title
    UIImage *image = [UIImage imageNamed:@"td_logo_white_nav_bar"];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:image];
    
    UIImage *findImage = [UIImage imageNamed:@"nav-add-follower"];
    CGRect buttonFrame = CGRectMake(0, 0, findImage.size.width, findImage.size.height);
    
    self.findButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [self.findButton setImage:findImage forState:UIControlStateNormal];
    [self.findButton setImage:[UIImage imageNamed:@"nav-add-follower-hit"] forState:UIControlStateHighlighted];
    [self.findButton addTarget:self action:@selector(findButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.findButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOverlay) name:TDRemoveGuestViewControllerOverlay object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(signupButtonPressed) name:TDGuestViewControllerSignUp object:nil];

    self.previousScrollViewYOffset = 0;

    self.disableViewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0.0f,0,SCREEN_WIDTH,SCREEN_HEIGHT)];
}

- (void)findButtonHit:(id)sender {
    [self openGuestUserJoin:kFollow_LabelType username:nil];
}

- (void)editInterestButton {
    debug NSLog(@"open the goals view");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.tableView reloadData];
    
    if (!self.posts || goneDownstream) {
        [self refreshPostsList];
        [self fetchPosts];
    }
    goneDownstream = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Posts

- (NSArray *)postsForThisScreen {
    return self.posts;
}

- (BOOL)hasMorePosts {
    return self.nextStart != nil;
}

- (TDPost *)postForRow:(NSInteger)row {
    NSInteger realRow = 0;
    if (row < 7) {
        realRow = row - 2; // 1 is for the header section, 1 is for edit goals section
    } else if (row > 7) {
        realRow = row -3;
    }
    
    if (realRow < self.posts.count) {
        return [self.posts objectAtIndex:realRow];
    } else {
        return nil;
    }
}

- (void)refreshControlUsed {
    [self fetchPosts];
}

- (void)endRefreshControl {
}

- (void)refreshPosts:(NSDictionary *)response {
    [self handleNextStart:[response objectForKey:@"next_start"]];
    [self handlePostsResponse:response fromStart:YES];
}
- (void)fetchPosts {
    if (self.initialLoadDone) {
        return;
    }

    [[TDAPIClient sharedInstance] saveGoalsAndInterestsForGuest:self.goalsList interestsList:self.interestsList callback:^(BOOL success, NSDictionary *response) {
        if (response) {
            [self handleNextStart:[response objectForKey:@"next_start"]];
            [self handlePostsResponse:response fromStart:YES];
        } else {
            [self endRefreshControl];
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
            self.loaded = YES;
            self.errorLoading = YES;
            [self.tableView reloadData];
        }
    }];
}

- (void)handleNextStart:(NSNumber *)start {
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
    }
    
    NSMutableArray *newPosts;
    if (self.posts) {

        newPosts = [[NSMutableArray alloc] initWithArray:self.posts];
    } else {
        newPosts = [[NSMutableArray alloc] init];
    }
    
    for (NSDictionary *postObject in [response valueForKeyPath:@"posts"]){
        TDPost *post = [[TDPost alloc] initWithDictionary:postObject];
        [newPosts addObject:post];
    }
    
    self.posts = newPosts;
    [self refreshPostsList];
}

- (BOOL)fetchMorePostsAtBottom {
    
    if (![self hasMorePosts]) {
        return NO;
    }
    [[TDAPIClient sharedInstance] saveGoalsAndInterestsForGuest:self.goalsList interestsList:self.interestsList callback:^(BOOL success, NSDictionary *response) {
        if (response) {
            [self handleNextStart:[response objectForKey:@"next_start"]];
            [self handlePostsResponse:response fromStart:YES];
        } else {
            [self endRefreshControl];
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
            self.loaded = YES;
            self.errorLoading = YES;
            [self.tableView reloadData];
        }
    }];
    return YES;
}

- (BOOL)onGuestFeed {
    return YES;
}

- (void)signupButtonPressed {
    TDSignupStepOneViewController *signupVC = [[TDSignupStepOneViewController alloc] init];
    
    //UIViewController *srcViewController = (UIViewController *) self;
    UIViewController *destViewController = (UIViewController *) signupVC;
    
    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromTop;
    [destViewController.view.window.layer addAnimation:transition forKey:nil];

    [self presentViewController:destViewController animated:YES completion:nil];
    //[srcViewController presentViewController:destViewController animated:NO completion:nil];
}

- (void)loginButtonPressed {
    TDLoginViewController *loginViewController = [[TDLoginViewController alloc] initWithNibName:@"TDLoginViewController" bundle:nil withCloseButton:YES];

    //UIViewController *srcViewController = (UIViewController *) self;
    UIViewController *destViewController = (UIViewController *) loginViewController;

    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromTop;
    [destViewController.view.window.layer addAnimation:transition forKey:nil];

    [self presentViewController:destViewController animated:YES completion:nil];
}
- (IBAction)addButtonPressed:(id)sender {
    [self openGuestUserJoin:kPost_LabelType username:nil];

}

- (void)addOverlay {
    self.disableViewOverlay.backgroundColor = [UIColor blackColor];
    self.disableViewOverlay.alpha = .6;
    
    [self.view addSubview:self.disableViewOverlay];
    [UIView beginAnimations:@"FadeIn" context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView commitAnimations];
}

- (void)removeOverlay {
    [self.disableViewOverlay removeFromSuperview];
}

- (void)openGuestUserJoin:(kLabelType)type username:(NSString*)username{
    [self addOverlay];
    
    TDGuestUserJoinView * joinView = [TDGuestUserJoinView guestUserJoinView:type username:username];
    [self.view addSubview:joinView];
}

-(void)dismissButtonPressed {
    [self.tableView reloadData];
}

- (void)showGuestController:(TDGuestUserProfileViewController*)guestViewController {
    // stub to stop crash bug from segue: navigateToHomeFrom
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[event allTouches] anyObject];
    if (touch.view == self.disableViewOverlay) {

    [[NSNotificationCenter defaultCenter] postNotificationName:TDRemoveGuestJoinView
                                                        object:self

                                                      userInfo:nil];
    }
}
@end
