//
//  TDTwoButtonView.h
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDTwoButtonViewDelegate <NSObject>
@optional
-(void)likeButtonPressedFromRow:(NSInteger)row;
-(void)unLikeButtonPressedFromRow:(NSInteger)row;
-(void)commentButtonPressedFromRow:(NSInteger)row;
-(void)miniLikeButtonPressedForLiker:(NSDictionary *)liker;
@end

@interface TDTwoButtonView : UITableViewCell
{
    id <TDTwoButtonViewDelegate> __unsafe_unretained delegate;
    NSInteger row;
    BOOL like;
}

@property (nonatomic, assign) id <TDTwoButtonViewDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIView *bottomPaddingLine;
@property (weak, nonatomic) IBOutlet UIView *buttonBorder;

- (IBAction)likeButtonPressed:(UIButton *)sender;
- (IBAction)commentButtonPressed:(UIButton *)sender;
-(void)setLike:(BOOL)liked;
-(void)setComment:(BOOL)commented;

@end
