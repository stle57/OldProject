//
//  TDDetailViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPost.h"
#import "TDDetailsLikesCell.h"
#import "TDDetailsCommentsCell.h"
#import "TDPostView.h"
#import "TDUserListViewController.h"

@protocol TDDetailViewControllerDelegate <NSObject>

@optional
-(void)postDeleted:(TDPost *)deletedPost;
-(void)replacePostId:(NSNumber *)postId withPost:(TDPost *)post;
@end

@interface TDDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, TDDetailsLikesCellDelegate, TDDetailsCommentsCellDelegate, UIAlertViewDelegate, UIActionSheetDelegate, TDPostViewDelegate, TDUserListViewDelegate>

@property (nonatomic, assign) id <TDDetailViewControllerDelegate> __unsafe_unretained delegate;
@property (nonatomic, retain) TDPost *post;
@property (nonatomic) NSNumber *postId;
- (void)unwindToRoot;

@end
