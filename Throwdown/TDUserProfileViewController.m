//
//  TDUserProfileViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserProfileViewController.h"
#import "TDPostAPI.h"
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDComment.h"
#import "TDViewControllerHelper.h"
#import "AFNetworking.h"

@interface TDUserProfileViewController ()

@end

@implementation TDUserProfileViewController

- (void)dealloc
{
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"UserProfile:%@", self.profilePost);

    needsProfileHeader = YES;

    [super viewDidLoad];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.titleLabel.text = self.profilePost.user.username;
    self.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:20.0];
    [self.navigationItem setTitleView:self.titleLabel];

    // Bar Button Items
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.settingsButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];
    self.navigationItem.leftBarButtonItem = leftBarButton;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)settingsButtonHit:(id)sender
{
    
}

-(IBAction)closeButtonHit:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES
                                                  completion:nil];
}

#pragma mark - Posts
-(void)fetchPostsUpStream
{
    NSLog(@"userprofile-fetchPostsUpStream");
    [[TDPostAPI sharedInstance] fetchPostsUpstreamForUser:self.profilePost.user.userId];
}

-(BOOL)fetchPostsDownStream
{
    NSLog(@"userprofile-fetchPostsDownStream");
    return [[TDPostAPI sharedInstance] fetchPostsDownstreamForUser:self.profilePost.user.userId];
}

-(NSArray *)postsForThisScreen
{
    NSLog(@"userprofile-postsForThisScreen");
    NSMutableArray *postsWithUsers = [NSMutableArray array];
    for (TDPost *aPost in [[TDPostAPI sharedInstance] getPostsForUser]) {
        [aPost replaceUser:self.profilePost.user];
        [postsWithUsers addObject:aPost];
    }

    return postsWithUsers;
}

-(NSNumber *)lowestIdOfPosts
{
    return [[TDPostAPI sharedInstance] lowestIdOfPostsForUser];
}

#pragma mark - Refresh Control
- (void)refreshControlUsed {
    debug NSLog(@"Profile-refreshControlUsed");
    [[TDPostAPI sharedInstance] fetchPostsForUserUpstreamWithErrorHandlerStart:nil userId:self.profilePost.user.userId error:^{
        [self endRefreshControl];
    }];
}

@end
