//
//  TDLikeView.m
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLikeView.h"
#import "TDAppDelegate.h"

@implementation TDLikeView

@synthesize delegate;
@synthesize row;
@synthesize likers;
@synthesize comments;
@synthesize like;

- (void)dealloc {
    delegate = nil;
    self.likers = nil;
    self.comments = nil;
}

- (void)awakeFromNib {
    self.moreLabel.font = [TDConstants fontSemiBoldSized:14.0];
}

- (IBAction)likeButtonPressed:(UIButton *)sender {
    debug NSLog(@"TDLikeView-likeButtonPressed:%d", like);

    if (like) {
        if (delegate && [delegate respondsToSelector:@selector(unLikeButtonPressedFromRow:)]) {
            [delegate unLikeButtonPressedFromRow:row];
        }
    } else if (delegate && [delegate respondsToSelector:@selector(likeButtonPressedFromRow:)]) {
        [delegate likeButtonPressedFromRow:row];
    }
}

- (IBAction)commentButtonPressed:(UIButton *)sender {
    if (delegate && [delegate respondsToSelector:@selector(commentButtonPressedFromRow:)]) {
        [delegate commentButtonPressedFromRow:row];
    }
}

- (void)setLike:(BOOL)liked {
    like = liked;
    if (liked) {
        UIImage *buttonImage = [UIImage imageNamed:@"but_liked_big.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateNormal];
        buttonImage = nil;
        buttonImage = [UIImage imageNamed:@"but_liked_big_hit.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateHighlighted];
        buttonImage = nil;
    } else {
        UIImage *buttonImage = [UIImage imageNamed:@"but_like_big.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateNormal];
        buttonImage = nil;
        buttonImage = [UIImage imageNamed:@"but_like_big_hit.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateHighlighted];
        buttonImage = nil;
    }
}

- (void)setComment:(BOOL)commented {
    UIImage *buttonImage = [UIImage imageNamed:@"but_comment_big.png"];
    [self.commentButton setImage:buttonImage forState:UIControlStateNormal];
    buttonImage = nil;
}

- (void)setLikesArray:(NSArray *)array totalLikersCount:(NSInteger)totalLikersCount {
    // Likers
    self.likers = array;

    if (totalLikersCount > 1) {
        self.moreLabel.text = [NSString stringWithFormat:@"%lu likes", (long)totalLikersCount];
    } else {
        self.moreLabel.text = @"1 like";
    }

    self.moreLabel.hidden = totalLikersCount == 0;
    self.likeIconImageView.hidden = totalLikersCount == 0;
}

- (void)setCommentsArray:(NSArray *)array {
    self.comments = array;
}

- (void)buttonPressed:(id)selector {
    UIButton *button = (UIButton *)selector;
    NSInteger index = button.tag - 800;

    if (delegate && [delegate respondsToSelector:@selector(miniLikeButtonPressedForLiker:)]) {
        [delegate miniLikeButtonPressedForLiker:[self.likers objectAtIndex:index]];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
}

@end
