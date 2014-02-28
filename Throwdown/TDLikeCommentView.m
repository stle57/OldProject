//
//  TDLikeCommentView.m
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLikeCommentView.h"


@implementation TDLikeCommentView

@synthesize delegate;
@synthesize row;

- (void)dealloc
{
    delegate = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self addSubview:[[[UINib nibWithNibName:@"TDLikeCommentView" bundle:nil] instantiateWithOwner:self options:nil] objectAtIndex:0]];

    }
    return self;
}

- (IBAction)likeButtonPressed:(UIButton *)sender
{
    if (like) {
        if (delegate) {
            if ([delegate respondsToSelector:@selector(unLikeButtonPressedFromRow:)]) {
                [delegate unLikeButtonPressedFromRow:row];
            }
        }
    } else {
        if (delegate) {
            if ([delegate respondsToSelector:@selector(likeButtonPressedFromRow:)]) {
                [delegate likeButtonPressedFromRow:row];
            }
        }
    }
}

- (IBAction)commentButtonPressed:(UIButton *)sender
{
    if (delegate) {
        if ([delegate respondsToSelector:@selector(commentButtonPressedFromRow:)]) {
            [delegate commentButtonPressedFromRow:row];
        }
    }
}

-(void)setLike:(BOOL)liked
{
    like = liked;
    if (liked) {
        UIImage *buttonImage = [UIImage imageNamed:@"but_liked_big.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateNormal];
        buttonImage = nil;
    } else {
        UIImage *buttonImage = [UIImage imageNamed:@"but_like_big.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateNormal];
        buttonImage = nil;
    }
}

-(void)setComment:(BOOL)commented
{
    UIImage *buttonImage = [UIImage imageNamed:@"but_comment_big.png"];
    [self.commentButton setImage:buttonImage forState:UIControlStateNormal];
    buttonImage = nil;
}

@end
