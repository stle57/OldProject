//
//  TDDetailsLikesCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

@protocol TDDetailsLikesCellDelegate <NSObject>
@optional
-(void)likeButtonPressedFromLikes;
-(void)unLikeButtonPressedFromLikes;
-(void)usernamePressedForLiker:(NSNumber *)likerId;
@end

@interface TDDetailsLikesCell : UITableViewCell
{
    id <TDDetailsLikesCellDelegate> __weak delegate;
    NSInteger row;
    BOOL like;
    NSArray *likers;
    NSArray *comments;
}

@property (nonatomic, weak) id <TDDetailsLikesCellDelegate> delegate;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, retain) NSArray *likers;
@property (nonatomic, retain) NSArray *comments;
@property (weak, nonatomic) IBOutlet UIImageView *likeImageView;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *likersNamesLabel;
@property (nonatomic) CGFloat namesLabelHeight;

- (IBAction)likeButtonPressed:(UIButton *)sender;
- (void)setLike:(BOOL)liked;
- (void)setLikesArray:(NSArray *)array;

+ (CGFloat)heightOfLikersLabel:(NSArray *)likers;

@end
