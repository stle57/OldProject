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

@interface TDDetailViewController : UIViewController <TDTypingViewViewDelegate, UITableViewDataSource, UITableViewDelegate, TDDetailsLikesCellDelegate, TDDetailsCommentsCellDelegate>
{
    TDPost *post;
    TDTypingView *typingView;
    CGPoint origTypingViewCenter;
    UIView *frostedViewWhileTyping;
    CGFloat postViewHeight;
    CGFloat postCommentViewHeight;
    CGFloat minLikeheight;
}

@property (nonatomic, retain) TDPost *post;
@property (nonatomic, retain) TDTypingView *typingView;
@property (nonatomic, retain) UIView *frostedViewWhileTyping;
@property (weak, nonatomic) IBOutlet UIView *postViewContainer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

- (void)reloadPosts:(NSNotification*)notification;
-(void)fullPostReturn:(NSNotification*)notification;
-(void)newCommentReturn:(NSNotification*)notification;

@end
