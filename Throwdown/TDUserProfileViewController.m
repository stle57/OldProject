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

@synthesize fromFrofileType;

- (void)dealloc
{
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    needsProfileHeader = YES;

    [super viewDidLoad];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.titleLabel.text = self.profileUser.username;
    self.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:20.0];
    [self.navigationItem setTitleView:self.titleLabel];

    // Bar Button Items
    switch (fromFrofileType) {
        case kFromProfileScreenType_OwnProfileButton:
        {
            UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];     // 'X'
            self.navigationItem.leftBarButtonItem = leftBarButton;
            UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.settingsButton]; // Settings
            self.navigationItem.rightBarButtonItem = rightBarButton;
        }
        break;
        case kFromProfileScreenType_OwnProfile:
        {
            UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.settingsButton]; // Settings
            self.navigationItem.rightBarButtonItem = rightBarButton;
        }
        break;
        case kFromProfileScreenType_OtherUser:
        {
            // Just iOS back and no right button
        }
        break;

        default:
        break;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    [super viewWillAppear:animated];

    if (!self.posts && goneDownstream) {
        [self refreshPostsList];
        [self fetchPostsUpStream];
    }
    goneDownstream = NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[TDPostAPI sharedInstance] clearPostsForUser]; // Clear so that we can use this display again
    self.posts = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)settingsButtonHit:(id)sender
{
    goneDownstream = YES;

    TDUserProfileEditViewController *vc = [[TDUserProfileEditViewController alloc] initWithNibName:@"TDUserProfileEditViewController" bundle:nil ];
    vc.profileUser = self.profileUser;
    vc.fromFrofileType = self.fromFrofileType;
    [self.navigationController pushViewController:vc animated:YES];
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
    [[TDPostAPI sharedInstance] fetchPostsUpstreamForUser:self.profileUser.userId];
}

-(BOOL)fetchPostsDownStream
{
    NSLog(@"userprofile-fetchPostsDownStream");
    return [[TDPostAPI sharedInstance] fetchPostsDownstreamForUser:self.profileUser.userId];
}

-(NSArray *)postsForThisScreen
{
    NSLog(@"userprofile-postsForThisScreen");
    NSMutableArray *postsWithUsers = [NSMutableArray array];
    for (TDPost *aPost in [[TDPostAPI sharedInstance] getPostsForUser]) {
        [aPost replaceUser:self.profileUser];
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
    [[TDPostAPI sharedInstance] fetchPostsForUserUpstreamWithErrorHandlerStart:nil userId:self.profileUser.userId error:^{
        [self endRefreshControl];
    }];
}

#pragma mark - Post Delegate
-(void)userButtonPressedFromRow:(NSInteger)row
{
    NSLog(@"profile-userButtonPressedFromRow:%ld %@ %@", (long)row, self.profilePost.user.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);

    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
    if ([self.profileUser.userId isEqualToNumber:post.user.userId]) {
        // Same user - do nothing
        return;
    }

    goneDownstream = YES;

    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.profilePost = post;
    vc.profileUser = post.user;
    vc.fromFrofileType = kFromProfileScreenType_OtherUser;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber
{
    TDPost *post = (TDPost *)[self.posts objectAtIndex:row];
    TDComment *comment = [post.comments objectAtIndex:commentNumber];
    TDUser *user = comment.user;

    goneDownstream = YES;

    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.profilePost = post;
    vc.profileUser = user;
    vc.fromFrofileType = kFromProfileScreenType_OtherUser;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
