//
//  TDPostView.h
//  Throwdown
//
//  Created by Andrew C on 2/3/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPost.h"
#import "TDLikeView.h"
#import "TDTwoButtonView.h"
#import "TDUpdatingDateLabel.h"

@protocol TDPostViewDelegate <NSObject>
@optional
- (void)postTouchedFromRow:(NSInteger)row;
- (void)userButtonPressedFromRow:(NSInteger)row;
- (void)userProfilePressedWithId:(NSNumber *)userId;
@end

@interface TDPostView : UITableViewCell

@property (nonatomic, assign) id <TDPostViewDelegate> __unsafe_unretained delegate;
@property (nonatomic) UILabel *usernameLabel;
@property (nonatomic) UIImageView *previewImage;
@property (nonatomic) UIImageView *userProfileImage;
@property (nonatomic) TDUpdatingDateLabel *createdLabel;
@property (nonatomic, assign) NSInteger row;
@property (strong, nonatomic) NSString *filename;
@property (strong, nonatomic) NSString *userPicture;

- (void)setPost:(TDPost *)post;

+ (CGFloat)heightForPost:(TDPost *)post;

@end
