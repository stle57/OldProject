//
//  TDPostsViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDFeedLikeCommentCell.h"
#import "TDPostView.h"
#import "TDDetailsCommentsCell.h"
#import "TDMoreComments.h"
#import "TDDetailViewController.h"
#import "TDAppDelegate.h"
#import "TDPostAPI.h"
#import "TDPostUpload.h"
#import "TDConstants.h"
#import "TDUserAPI.h"
#import "VideoButtonSegue.h"
#import "TDFeedLikeCommentCell.h"
#import "TDActivityCell.h"
#import "TDUserProfileCell.h"
#import "TDNoPostsCell.h"
#import "TDNoMorePostsCell.h"
#import "TDNoticeViewCell.h"

@interface TDPostsViewController : UIViewController <TDFeedLikeCommentDelegate, TDPostViewDelegate, TDDetailsCommentsCellDelegate, UIActionSheetDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, TDUserProfileCellDelegate>
{
    BOOL goneDownstream;
    CGFloat likeHeight;
    CGFloat commentRowHeight;
    CGFloat moreCommentRowHeight;
    CGFloat activityRowHeight;
    CGFloat profileHeaderHeight;
    CGFloat inviteButtonHeight;
    CGFloat statButtonHeight;
    CGFloat noPostsHeight;
    CGFloat uploadMoreHeight;
    CGFloat noFollowingHeight;
    BOOL updatingAtBottom;
    BOOL showBottomSpinner;
    CGRect statusBarFrame;
    CGFloat topOfBioLabelInProfileHeader;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (strong, nonatomic) UIActivityIndicatorView *playerSpinner;
@property (nonatomic, retain) NSNumber *userId;
@property (nonatomic, retain) NSString *username;
@property (nonatomic) BOOL loaded;
@property (nonatomic) BOOL errorLoading;
@property (nonatomic) kFeedProfileType profileType;

- (NSArray *)postsForThisScreen;
- (BOOL)onAllFeed;
- (TDUser *)getUser;
- (void)fetchPosts;  // Actually goes out and fetches from server
- (void)reloadPosts; // Only refreshes the table with currently cached posts
- (void)refreshPostsList; // Same as above but slight variation TODO: just have one?
- (void)refreshControlUsed;
- (void)endRefreshControl;
- (void)showWelcomeController;
- (void)startSpinner:(NSNotification *)notification;
- (void)stopSpinner:(NSNotification *)notification;
- (void)stopBottomLoadingSpinner;
- (void)startLoadingSpinner;
- (void)openDetailView:(NSNumber *)postId;
- (void)openProfile:(NSNumber *)userId;

- (NSUInteger)noticeCount;
- (TDNotice *)getNoticeAt:(NSUInteger)index;
- (BOOL)removeNoticeAt:(NSUInteger)index;

@end
