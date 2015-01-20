//
//  TDTagFeedViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/17/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDTagFeedViewController.h"
#import "TDViewControllerHelper.h"
#import "TDPostAPI.h"
#import "TDDetailInfoViewController.h"
#import "TDUsersViewController.h"
#import "TDTagUserFeedViewController.h"

@interface TDTagFeedViewController ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) NSArray *posts;
@property (nonatomic) NSNumber *nextStart;
@property (nonatomic) TDCampaignView *campaignView;
@property (nonatomic) UIView *headerView;
@property (nonatomic) NSDictionary *campaignData;
@end

@implementation TDTagFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TDConstants lightBackgroundColor];

    // Background
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];

    // Title
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    self.titleLabel.text = @"";
    [self.navigationItem setTitleView:self.titleLabel];

    self.backButton = [TDViewControllerHelper navBackButton];
    [self.backButton addTarget:self action:@selector(backButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];
    [self.view addSubview:self.tableView];

    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.y = -(navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removePost:) name:TDNotificationRemovePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePost:) name:TDNotificationUpdatePost object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.tagName) {
        self.titleLabel.text = [@"#" stringByAppendingString:self.tagName];
    }
    [self.tableView reloadData];
}

- (void)backButtonHit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)userButtonPressed:(id)sender {
    TDTagUserFeedViewController *vc = [[TDTagUserFeedViewController alloc] initWithNibName:@"TDTagUserFeedViewController" bundle:nil];
    [vc setUserId:[TDCurrentUser sharedInstance].userId tagName:self.tagName];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Posts

- (NSArray *)postsForThisScreen {
    return self.posts;
}

- (BOOL)hasMorePosts {
    return self.nextStart != nil;
}

- (void)updatePost:(NSNotification *)n {
    BOOL changeMade = NO;
    NSNumber *postId = (NSNumber *)[n.userInfo objectForKey:@"postId"];

    for (TDPost *post in self.posts) {
        if ([post.postId isEqualToNumber:postId]) {
            [post updateFromNotification:n];
            changeMade = YES;
            break;
        }
    }

    if (changeMade) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

- (void)removePost:(NSNotification *)n {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Main posts
        BOOL changeMade = NO;
        NSNumber *postId = (NSNumber *)[n.userInfo objectForKey:@"postId"];
        NSMutableArray *newList = [[NSMutableArray array] init];
        for (TDPost *post in self.posts) {
            if ([post.postId isEqualToNumber:postId]) {
                changeMade = YES;
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

- (void)updatePostsAfterUserUpdate:(NSNotification *)notification {
    for (TDPost *aPost in self.posts) {
        [aPost updateUserInfoFor:[[TDCurrentUser sharedInstance] currentUserObject]];
    }
    [self.tableView reloadData];
}

- (TDPost *)postForRow:(NSInteger)row {
    if (row < self.posts.count) {
        return [self.posts objectAtIndex:row];
    } else {
        return nil;
    }
}

- (void)refreshControlUsed {
    [self fetchPosts];
}

- (void)fetchPosts {
    if (!self.tagName) {
        return;
    }
    [[TDPostAPI sharedInstance] fetchPostsForTagName:self.tagName start:nil success:^(NSDictionary *response) {
        debug NSLog(@"got data");
        if ([response valueForKey:TDCampaginStr]) {
            debug NSLog(@"creating campaign view with data = %@", [response valueForKey:TDCampaginStr]);
            self.campaignData = [response valueForKey:TDCampaginStr];
            [self loadCampaignView:[response valueForKey:TDCampaginStr] ];
        }
        [self handleNextStart:[response objectForKey:@"next_start"]];
        [self handlePostsResponse:response fromStart:YES];
    } error:^{
        [self endRefreshControl];
        [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
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
        newPosts = [[NSMutableArray alloc] initWithArray:self.posts];
    } else {
        newPosts = [[NSMutableArray alloc] init];
    }

    for (NSDictionary *postObject in [response valueForKeyPath:@"posts"]) {
        TDPost *post = [[TDPost alloc] initWithDictionary:postObject];
        [newPosts addObject:post];
    }

    self.posts = newPosts;
    [self refreshPostsList];
}

- (BOOL)fetchMorePostsAtBottom {
    if (![self hasMorePosts] || !self.tagName) {
        return NO;
    }
    [[TDPostAPI sharedInstance] fetchPostsForTagName:self.tagName start:self.nextStart success:^(NSDictionary *response) {
        [self handleNextStart:[response objectForKey:@"next_start"]];
        [self handlePostsResponse:response fromStart:NO];
    } error:^{
        self.errorLoading = YES;
    }];
    return YES;
}

- (void)loadCampaignView:(NSDictionary*)campaignData {
    if (self.headerView) {
        return;
    }

    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, [TDCampaignView heightForCampaignHeader:campaignData])];
    self.campaignView =
        [[TDCampaignView alloc] initWithFrame:(CGRectMake(0, 0, width, [TDCampaignView heightForCampaignHeader:campaignData])) campaignData:campaignData];
    self.campaignView.delegate = self;
    [self.headerView addSubview:self.campaignView];
    [self.tableView setTableHeaderView:self.headerView];
}

#pragma mark - View delegate and event overrides

- (void)userTappedURL:(NSURL *)url {
    if ([[url host] isEqualToString:@"tag"]) {
        NSString *tagName = [[url path] lastPathComponent];
        if (self.tagName != nil && [self.tagName isEqualToString:tagName]) {
            // Return here, user pressed the same hashtag, would just open a clone of this view.
            return;
        }
    }
    [super userTappedURL:url];
}

#pragma mark - TDGuestInfoCellDelegate 
- (void)loadDetailView {
    debug NSLog(@"LOAD LEARN MORE from TDTagFeedViewController");
    TDDetailInfoViewController *viewController = [[TDDetailInfoViewController alloc] initWithNibName:@"TDDetailInfoViewController" bundle:nil title:@"Learn More" campaignData:self.campaignData];
    viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.navigationBar.barStyle = UIBarStyleDefault;
    navController.navigationBar.translucent = YES;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

-(void)loadChallengersView {
    debug NSLog(@"Load challengers feed");
    TDUsersViewController *vc = [[TDUsersViewController alloc] initWithNibName:@"TDUsersViewController" bundle:nil title:@"Challengers"];
    vc.tagName = self.tagName;
    [self.navigationController pushViewController:vc animated:NO];
}
@end
