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
#import "VideoCloseSegue.h"
#import "TDLikeView.h"
#import "TDHomeHeaderView.h"
#import "TDActivityCell.h"
#import "TDUserProfileCell.h"
#import "TDNoPostsCell.h"
#import "TDUploadMoreCell.h"

@interface TDPostsViewController : UIViewController <TDLikeViewDelegate, TDPostViewDelegate, TDTwoButtonViewDelegate, TDDetailsCommentsCellDelegate, TDMoreCommentsDelegate, UIActionSheetDelegate, TDDetailViewControllerDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, TDUserProfileCellDelegate>
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
    CGFloat profileHeaderHeight;
    CGFloat noPostsHeight;
    CGFloat uploadMoreHeight;
    BOOL updatingAtBottom;
    BOOL showBottomSpinner;
    BOOL noMorePostsAtBottom;
    CGPoint tableOffset;
    CGRect statusBarFrame;
    BOOL needsProfileHeader;
    CGFloat topOfBioLabelInProfileHeader;
}

@property (nonatomic, retain) NSArray *posts;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (weak, nonatomic) IBOutlet UIView *bottomButtonHolderView;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (nonatomic, retain) UIDynamicAnimator *animator;
@property (strong, nonatomic) TDHomeHeaderView *headerView;
@property (strong, nonatomic) UIActivityIndicatorView *playerSpinner;
@property (nonatomic, retain) NSNumber *userId;
@property (nonatomic) BOOL loaded;

- (NSArray *)postsForThisScreen;
- (void)reloadPosts;
- (void)refreshPostsList;
- (void)refreshControlUsed;
- (void)endRefreshControl;
- (void)showWelcomeController;
- (void)startSpinner:(NSNotification *)notification;
- (void)stopSpinner:(NSNotification *)notification;
- (void)stopSpinner;
- (void)startLoadingSpinner;
- (TDUser *)getUser;
- (void)openDetailView:(NSNumber *)postId;
@end
