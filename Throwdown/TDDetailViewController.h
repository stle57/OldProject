//
//  TDDetailViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPost.h"
#import "TDTypingView.h"
#import "TDDetailsLikesCell.h"
#import "TDDetailsCommentsCell.h"
#import "TDPostView.h"

@protocol TDDetailViewControllerDelegate <NSObject>

@optional
-(void)postDeleted:(TDPost *)deletedPost;
-(void)replacePostId:(NSNumber *)postId withPost:(TDPost *)post;
@end

@interface TDDetailViewController : UIViewController <TDTypingViewViewDelegate, UITableViewDataSource, UITableViewDelegate, TDDetailsLikesCellDelegate, TDDetailsCommentsCellDelegate, UIAlertViewDelegate, TDPostViewDelegate>
{
    id <TDDetailViewControllerDelegate> __unsafe_unretained delegate;
    TDPost *post;
    TDTypingView *typingView;
    CGPoint origTypingViewCenter;
    UIView *frostedViewWhileTyping;
    CGFloat postViewHeight;
    CGFloat postCommentViewHeight;
    CGFloat minLikeheight;
    BOOL liking;
}

@property (nonatomic, assign) id <TDDetailViewControllerDelegate> __unsafe_unretained delegate;
@property (nonatomic, retain) TDPost *post;
@property (nonatomic) NSNumber *postId;
@property (nonatomic, retain) TDTypingView *typingView;
@property (nonatomic, retain) UIView *frostedViewWhileTyping;
@property (weak, nonatomic) IBOutlet UIView *postViewContainer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

- (void)reloadPosts:(NSNotification*)notification;
- (void)fullPostReturn:(NSNotification*)notification;
- (void)newCommentReturn:(NSNotification*)notification;
- (void)unwindToRoot;

@end
