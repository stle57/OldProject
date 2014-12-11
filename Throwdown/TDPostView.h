//
//  TDPostView.h
//  Throwdown
//
//  Created by Andrew C on 2/3/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPost.h"
#import "TDFeedLikeCommentCell.h"
#import "TDUpdatingDateLabel.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>

@protocol TDPostViewDelegate <NSObject>
@optional
- (void)postTouchedFromRow:(NSInteger)row;
- (void)locationButtonPressedFromRow:(NSInteger)row;
- (void)userButtonPressedFromRow:(NSInteger)row;
- (void)userProfilePressedWithId:(NSNumber *)userId;
- (void)horizontalScrollingStarted;
- (void)horizontalScrollingEnded;
@end

@interface TDPostView : UITableViewCell

@property (nonatomic, weak) id <TDPostViewDelegate> delegate;
@property (nonatomic) TTTAttributedLabel *usernameLabel;
@property (nonatomic) UIImageView *previewImage;
@property (nonatomic) UIImageView *userProfileImage;
@property (nonatomic) TDUpdatingDateLabel *createdLabel;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *userPicture;

- (void)setPost:(TDPost *)post;

+ (CGFloat)heightForPost:(TDPost *)post;

@end
