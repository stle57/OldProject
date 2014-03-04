//
//  TDLikeCommentView.h
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDLikeCommentViewDelegate <NSObject>
@optional
-(void)likeButtonPressedFromRow:(NSInteger)row;
-(void)unLikeButtonPressedFromRow:(NSInteger)row;
-(void)commentButtonPressedFromRow:(NSInteger)row;
-(void)miniLikeButtonPressedForLiker:(NSDictionary *)liker;
@end

@interface TDLikeCommentView : UIView
{
    id <TDLikeCommentViewDelegate> __unsafe_unretained delegate;
    NSInteger row;
    BOOL like;
    NSArray *likers;
    NSArray *comments;
}

@property (nonatomic, assign) id <TDLikeCommentViewDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIImageView *moreImageView;
@property (weak, nonatomic) IBOutlet UIImageView *likeIconImageView;
@property (nonatomic, retain) NSArray *likers;
@property (nonatomic, retain) NSArray *comments;

- (IBAction)likeButtonPressed:(UIButton *)sender;
- (IBAction)commentButtonPressed:(UIButton *)sender;
-(void)setLike:(BOOL)liked;
-(void)setComment:(BOOL)commented;
-(void)setLikesArray:(NSArray *)array;
-(void)setCommentsArray:(NSArray *)array;

@end
