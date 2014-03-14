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
    }
    return self;
}

- (IBAction)likeButtonPressed:(UIButton *)sender
{
    debug NSLog(@"likeButtonPressed");
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

/*- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"HIT:%@", NSStringFromCGPoint(point) );

    return self;
} */

/*- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"point inside");

    return YES;
} */

/*-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touches");
} */

/*- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    NSLog(@"selected");
    [super setSelected:selected animated:animated];
} */

@end
