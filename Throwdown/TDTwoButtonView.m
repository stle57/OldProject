//
//  TDTwoButtonView.m
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDTwoButtonView.h"
#import "TDAppDelegate.h"

@implementation TDTwoButtonView

@synthesize delegate;
@synthesize row;

- (void)dealloc {
    delegate = nil;
}

- (void)awakeFromNib {
    CGRect bottomLineRect = self.bottomPaddingLine.frame;
    bottomLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    bottomLineRect.origin.y += 1 / [[UIScreen mainScreen] scale];
    self.bottomPaddingLine.frame = bottomLineRect;

    CGRect buttonBorderRect = self.buttonBorder.frame;
    buttonBorderRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.buttonBorder.frame = buttonBorderRect;
}

- (IBAction)likeButtonPressed:(UIButton *)sender {
    debug NSLog(@"likeButtonPressed");
    if (!delegate) {
        return;
    }

    if (like && [delegate respondsToSelector:@selector(unLikeButtonPressedFromRow:)]) {
        [delegate unLikeButtonPressedFromRow:row];
    } else if (!like && [delegate respondsToSelector:@selector(likeButtonPressedFromRow:)]) {
        [delegate likeButtonPressedFromRow:row];
    }
    [self setLike:!like];
}

- (IBAction)commentButtonPressed:(UIButton *)sender {
    if (delegate && [delegate respondsToSelector:@selector(commentButtonPressedFromRow:)]) {
        [delegate commentButtonPressedFromRow:row];
    }
}

- (void)setLike:(BOOL)liked {
    like = liked;

    if (liked) {
        [self.likeButton setImage:[UIImage imageNamed:@"but_liked_big"] forState:UIControlStateNormal];
        [self.likeButton setImage:[UIImage imageNamed:@"but_liked_big_hit"] forState:UIControlStateHighlighted];
    } else {
        [self.likeButton setImage:[UIImage imageNamed:@"but_like_big"] forState:UIControlStateNormal];
        [self.likeButton setImage:[UIImage imageNamed:@"but_like_big_hit"] forState:UIControlStateHighlighted];
    }
}

- (void)setComment:(BOOL)commented {
    [self.commentButton setImage:[UIImage imageNamed:@"but_comment_big"] forState:UIControlStateNormal];
}

@end
