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

@interface TDGuestUserProfileViewController ()
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *findButton;
@property (nonatomic) NSArray *posts;
@property (nonatomic) NSNumber *nextStart;
@property (nonatomic) UIView *headerView;
@property (nonatomic) UIView *viewOverlay;
@property (nonatomic) UIView *disableViewOverlay;

@property (nonatomic) TDUser *user;
@end


@implementation TDGuestUserProfileViewController

- (void)dealloc {
    self.headerView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
    
    self.disableViewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0.0f,0,SCREEN_WIDTH,SCREEN_HEIGHT)];
}

- (void)findButtonHit:(id)sender {
    [self openGuestUserJoin:kFollow_LabelType];
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
    if (row < 12) {
        realRow = row - 2; // 1 is for the header section, 1 is for edit goals section
    } else if (row > 12) {
        realRow = row -3;
    }
    
    //debug NSLog(@"REAL ROW = %ld", (long)realRow);
    if (realRow < self.posts.count) {
        return [self.posts objectAtIndex:realRow];
    } else {
        return nil;
    }
}

- (void)refreshControlUsed {
    [self fetchPosts];
}

- (void)fetchPosts {
    [[TDPostAPI sharedInstance] fetchPostsForGU:@"male" start:nil success:^(NSDictionary *response) {
        self.user = [[TDUser alloc] initWithDictionary:[response valueForKeyPath:@"user"]];
        //self.titleLabel.text = self.user.username;
        [self handleNextStart:[response objectForKey:@"next_start"]];
        [self handlePostsResponse:response fromStart:YES];
    } error:^{
        [self endRefreshControl];
        [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
        self.loaded = YES;
        self.errorLoading = YES;
        [self.tableView reloadData];
    }];
}

- (void)handleNextStart:(NSNumber *)start {
    // start can be [NSNull null] here
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
        newPosts = [[self.posts subarrayWithRange:NSMakeRange(0, 20)] mutableCopy];
        

        //newPosts = [[NSMutableArray alloc] initWithArray:self.posts];
    } else {
        newPosts = [[NSMutableArray alloc] init];
    }
    
    int count = 0;
    for (NSDictionary *postObject in [response valueForKeyPath:@"posts"]){
        if (count < 20) {
            TDPost *post = [[TDPost alloc] initWithDictionary:postObject];
            [newPosts addObject:post];
            count++;
        } else {
            debug NSLog(@"****breaking after 20 posts");
            break;
        }
        
    }
    
    self.posts = newPosts;
    [self refreshPostsList];
}

- (BOOL)fetchMorePostsAtBottom {
//    if (![self hasMorePosts] || !self.locationId) {
//        return NO;
//    }
//    [[TDPostAPI sharedInstance] fetchPostsForGuestUser:self.guestGoalsAndInterests start:self.nextStart success:^(NSDictionary *response) {
//        [self handleNextStart:[response objectForKey:@"next_start"]];
//        [self handlePostsResponse:response fromStart:NO];
//    } error:^{
//        self.errorLoading = YES;
//    }];
    
    if (![self hasMorePosts]) {
        return NO;
    }
    [[TDPostAPI sharedInstance] fetchPostsForGU:@"male" start:self.nextStart success:^(NSDictionary *response) {
        [self handleNextStart:[response objectForKey:@"next_start"]];
        [self handlePostsResponse:response fromStart:NO];
    } error:^{
        self.loaded = YES;
        self.errorLoading = YES;
    }];
    return YES;
}

- (BOOL)onGuestFeed {
    return YES;
}

- (void)signupButtonPressed {
    TDSignupStepOneViewController *signupVC = [[TDSignupStepOneViewController alloc] init];
    
    UIViewController *srcViewController = (UIViewController *) self;
    UIViewController *destViewController = (UIViewController *) signupVC;
    
    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromBottom;
    [srcViewController.view.window.layer addAnimation:transition forKey:nil];

    [srcViewController presentViewController:destViewController animated:NO completion:nil];
    
}

- (IBAction)addButtonPressed:(id)sender {
    [self openGuestUserJoin:kPost_LabelType];

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

- (void)openGuestUserJoin:(kLabelType)type {
    [self addOverlay];
    
    TDGuestUserJoinView * joinView = [TDGuestUserJoinView guestUserJoinView:type];
    [self.view addSubview:joinView];
}

-(void)dismissButtonPressed {
    [self.tableView reloadData];
}

//- (void)showGuestController {
//    // stub to stop crash bug from segue: navigateToHomeFrom
//}
@end
