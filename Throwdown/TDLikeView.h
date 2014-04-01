//
//  TDLikeView.h
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDLikeViewDelegate <NSObject>
@optional
-(void)likeButtonPressedFromRow:(NSInteger)row;
-(void)unLikeButtonPressedFromRow:(NSInteger)row;
-(void)commentButtonPressedFromRow:(NSInteger)row;
-(void)miniLikeButtonPressedForLiker:(NSDictionary *)liker;
@end

@interface TDLikeView : UITableViewCell
{
    id <TDLikeViewDelegate> __unsafe_unretained delegate;
    NSInteger row;
    BOOL like;
    NSArray *likers;
    NSArray *comments;
}

@property (nonatomic, assign) id <TDLikeViewDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIImageView *likeIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *moreLabel;
@property (nonatomic, retain) NSArray *likers;
@property (nonatomic, retain) NSArray *comments;
@property (nonatomic, assign) BOOL like;

- (IBAction)likeButtonPressed:(UIButton *)sender;
- (IBAction)commentButtonPressed:(UIButton *)sender;
-(void)setLike:(BOOL)liked;
-(void)setComment:(BOOL)commented;
-(void)setLikesArray:(NSArray *)array totalLikersCount:(NSInteger)totalLikersCount;
-(void)setCommentsArray:(NSArray *)array;

@end
