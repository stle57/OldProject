//
//  TDLikeView.h
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDFeedLikeCommentDelegate <NSObject>
@optional
-(void)likeButtonPressedFromRow:(NSInteger)row;
-(void)unLikeButtonPressedFromRow:(NSInteger)row;
-(void)commentButtonPressedFromRow:(NSInteger)row;
-(void)miniLikeButtonPressedForLiker:(NSDictionary *)liker;
@end

@interface TDFeedLikeCommentCell : UITableViewCell

@property (nonatomic, assign) id <TDFeedLikeCommentDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIImageView *likeIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *moreLabel;

- (IBAction)likeButtonPressed:(UIButton *)sender;
- (IBAction)commentButtonPressed:(UIButton *)sender;
- (void)setUserLiked:(BOOL)liked totalLikes:(NSInteger)likeCount;

@end
