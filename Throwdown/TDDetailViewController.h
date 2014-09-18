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
#import "TDUserListView.h"

@interface TDDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, TDDetailsLikesCellDelegate, TDDetailsCommentsCellDelegate, UIAlertViewDelegate, UIActionSheetDelegate, TDPostViewDelegate, TDUserListViewDelegate>

@property (nonatomic, retain) TDPost *post;
@property (nonatomic) NSNumber *postId;
@property (nonatomic) NSString *slug;
- (void)unwindToRoot;

@end
