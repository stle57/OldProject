//
//  TDPostView.h
//  Throwdown
//
//  Created by Andrew C on 2/3/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPost.h"
#import "TDLikeCommentView.h"

@interface TDPostView : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UILabel *createdLabel;
@property (weak, nonatomic) IBOutlet TDLikeCommentView *likeCommentView;
@property (weak, nonatomic) IBOutlet UIView *bottomPaddingLine;
@property (strong, nonatomic) NSString *filename;

- (void)setPost:(TDPost *)post;

@end
