//
//  TDLikeView.m
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDFeedLikeCommentCell.h"
#import "TDAppDelegate.h"

@interface TDFeedLikeCommentCell ()
@property (nonatomic, assign) BOOL liked;
@end

@implementation TDFeedLikeCommentCell

- (void)dealloc {
    self.delegate = nil;
}

- (void)awakeFromNib {
    self.moreLabel.font = [TDConstants fontSemiBoldSized:15.0];
}

- (IBAction)likeButtonPressed:(UIButton *)sender {
    debug NSLog(@"TDLikeView-likeButtonPressed:%d", self.liked);

    if (self.liked) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(unLikeButtonPressedFromRow:)]) {
            [self.delegate unLikeButtonPressedFromRow:self.row];
        }
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(likeButtonPressedFromRow:)]) {
        [self.delegate likeButtonPressedFromRow:self.row];
    }
}

- (IBAction)commentButtonPressed:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(commentButtonPressedFromRow:)]) {
        [self.delegate commentButtonPressedFromRow:self.row];
    }
}

- (void)setUserLiked:(BOOL)liked totalLikes:(NSInteger)likeCount {

    if (likeCount > 1) {
        self.moreLabel.text = [NSString stringWithFormat:@"%lu likes", (long)likeCount];
    } else {
        self.moreLabel.text = @"1 like";
    }

    self.moreLabel.hidden = likeCount == 0;
    self.likeIconImageView.hidden = likeCount == 0;

    self.liked = liked;
    if (liked) {
        [self.likeButton setImage:[UIImage imageNamed:@"btn-liked.png"] forState:UIControlStateNormal];
        [self.likeButton setImage:[UIImage imageNamed:@"btn-liked-hit.png"] forState:UIControlStateHighlighted];
        [self.likeButton setImage:[UIImage imageNamed:@"btn-liked-hit.png"] forState:UIControlStateSelected];
    } else {
        [self.likeButton setImage:[UIImage imageNamed:@"btn-like.png"] forState:UIControlStateNormal];
        [self.likeButton setImage:[UIImage imageNamed:@"btn-like-hit.png"] forState:UIControlStateHighlighted];
        [self.likeButton setImage:[UIImage imageNamed:@"btn-like-hit.png"] forState:UIControlStateSelected];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
}

@end
