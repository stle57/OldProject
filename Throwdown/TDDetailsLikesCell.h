//
//  TDDetailsLikesCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDDetailsLikesCellDelegate <NSObject>
@optional
-(void)likeButtonPressedFromLikes;
-(void)unLikeButtonPressedFromLikes;
-(void)miniAvatarButtonPressedForLiker:(NSDictionary *)liker;
@end

@interface TDDetailsLikesCell : UITableViewCell
{
    id <TDDetailsLikesCellDelegate> __unsafe_unretained delegate;
    NSInteger row;
    BOOL like;
    NSArray *likers;
    NSArray *comments;
}

@property (nonatomic, assign) id <TDDetailsLikesCellDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, retain) NSArray *likers;
@property (nonatomic, retain) NSArray *comments;
@property (weak, nonatomic) IBOutlet UIImageView *likeImageView;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;

- (IBAction)likeButtonPressed:(UIButton *)sender;
-(void)setLike:(BOOL)liked;
-(void)setComment:(BOOL)commented;
-(void)setLikesArray:(NSArray *)array;
+(NSInteger)numberOfRowsForLikers:(NSInteger)count;
+(NSInteger)rowNumberForLiker:(NSInteger)index;

@end
