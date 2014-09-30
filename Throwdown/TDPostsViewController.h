//
//  TDPostsViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDLikeView.h"
#import "TDPostView.h"
#import "TDTwoButtonView.h"
#import "TDDetailsCommentsCell.h"
#import "TDMoreComments.h"
#import "TDDetailViewController.h"
#import "TDAppDelegate.h"
#import "TDPostAPI.h"
#import "TDPostUpload.h"
#import "TDConstants.h"
#import "TDUserAPI.h"
#import "VideoButtonSegue.h"
#import "TDLikeView.h"
#import "TDHomeHeaderView.h"
#import "TDActivityCell.h"
#import "TDUserProfileCell.h"
#import "TDNoPostsCell.h"
#import "TDNoMorePostsCell.h"
#import "TDNoticeViewCell.h"

@interface TDPostsViewController : UIViewController <TDLikeViewDelegate, TDPostViewDelegate, TDTwoButtonViewDelegate, TDDetailsCommentsCellDelegate, TDMoreCommentsDelegate, UIActionSheetDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, TDUserProfileCellDelegate>
{
    BOOL goneDownstream;
    CGPoint origRecordButtonCenter;
    UIDynamicAnimator *animator;
    CGFloat likeHeight;
    CGFloat commentButtonsHeight;
    CGFloat commentRowHeight;
    CGFloat moreCommentRowHeight;
    CGFloat activityRowHeight;
    CGFloat profileHeaderHeight;
    CGFloat inviteButtonHeight;
    CGFloat statButtonHeight;
    CGFloat noPostsHeight;
    CGFloat uploadMoreHeight;
    BOOL updatingAtBottom;
    BOOL showBottomSpinner;
    CGRect statusBarFrame;
    //BOOL needsProfileHeader;
    CGFloat topOfBioLabelInProfileHeader;
}

@property (nonatomic) NSMutableDictionary *removingPosts;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (nonatomic, retain) UIDynamicAnimator *animator;
@property (strong, nonatomic) TDHomeHeaderView *headerView;
@property (strong, nonatomic) UIActivityIndicatorView *playerSpinner;
@property (nonatomic, retain) NSNumber *userId;
@property (nonatomic) BOOL needsProfileHeader;
@property (nonatomic, retain) NSString *username;
@property (nonatomic) BOOL loaded;
@property (nonatomic) BOOL errorLoading;

- (NSArray *)postsForThisScreen;
- (TDUser *)getUser;
- (void)reloadPosts;
- (void)refreshPostsList;
- (void)refreshControlUsed;
- (void)endRefreshControl;
- (void)showWelcomeController;
- (void)startSpinner:(NSNotification *)notification;
- (void)stopSpinner:(NSNotification *)notification;
- (void)stopBottomLoadingSpinner;
- (void)startLoadingSpinner;
- (void)openDetailView:(NSNumber *)postId;

- (NSUInteger)noticeCount;
- (TDNotice *)getNoticeAt:(NSUInteger)index;
- (BOOL)removeNoticeAt:(NSUInteger)index;

@end
