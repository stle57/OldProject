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

- (IBAction)commentButtonPressed:(UIButton *)sender {
    if (delegate) {
        if ([delegate respondsToSelector:@selector(commentButtonPressedFromRow:)]) {
            [delegate commentButtonPressedFromRow:row];
        }
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

-(void)setComment:(BOOL)commented
{
    UIImage *buttonImage = [UIImage imageNamed:@"but_comment_big.png"];
    [self.commentButton setImage:buttonImage forState:UIControlStateNormal];
    buttonImage = nil;
}

-(void)setLikesArray:(NSArray *)array totalLikersCount:(NSInteger)totalLikersCount
{
    // Likers
    self.likers = array;

    if (totalLikersCount > 1) {
        self.moreLabel.text = [NSString stringWithFormat:@"%lu likes", (long)totalLikersCount];
    } else {
        self.moreLabel.text = @"1 like";
    }

    self.likeIconImageView.hidden = YES;
    if ([self.likers count] > 0) {
        self.likeIconImageView.hidden = NO;
    }

    // Remove any old buttons for cell reuse
    UIView *buttonView = nil;
    for (int i=800; i < 810; i++) {
        buttonView = [self viewWithTag:i];
        if (buttonView) {
            [buttonView removeFromSuperview];
        }
        buttonView = nil;
    }

    // Add image buttons
    NSInteger index = 0;
    for (NSDictionary *likerDict in self.likers) {
        if ([likerDict objectForKey:@"picture"]) {
            [self addButtonWithPicture:[likerDict objectForKey:@"picture"]
                                 index:[self.likers indexOfObject:likerDict]];
            index ++;   // double check no more than 8
            if (index > 7) {
                break;
            }
        }
    }
}

-(void)setCommentsArray:(NSArray *)array {
    self.comments = array;
}

-(CGRect)frameForButtonWithIndex:(NSInteger)index
{
    CGFloat gap = 3.0;
    CGFloat widthOfOne = ((CGRectGetMaxX(self.likeIconImageView.frame) - gap * 10.0) / 8.0);
    // max width 24.0
    if (widthOfOne > 24.0) {
        widthOfOne = 24.0;
    }
    return CGRectMake(((widthOfOne+gap) * index) + CGRectGetMaxX(self.likeIconImageView.frame) + gap * 2.0,
                      0.0,
                      widthOfOne,
                      widthOfOne);
}

-(void)addButtonWithPicture:(NSString *)picture index:(NSInteger)index
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = [self frameForButtonWithIndex:index];
    button.center = CGPointMake(button.center.x,
                                self.likeIconImageView.center.y);
    button.backgroundColor = [UIColor clearColor];
    button.tag = 800+index;
    [button addTarget:self
               action:@selector(buttonPressed:)
     forControlEvents:UIControlEventTouchUpInside];

    // Round it off
    button.layer.cornerRadius = button.frame.size.width/2.0;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = [UIColor lightGrayColor].CGColor;
    button.layer.borderWidth = 1.0;

    [self addSubview:button];

    // Load Picture
    if ([picture isEqualToString:@"default"]) {
        UIImage *image = [UIImage imageNamed:@"prof_pic_default"];
        [button setImage:image forState:UIControlStateNormal];
        image = nil;
    } else {
        // Is a server-side image

        // For now - use the default image
        UIImage *image = [UIImage imageNamed:@"prof_pic_default"];
        [button setImage:image forState:UIControlStateNormal];
        image = nil;
    }
}

-(void)buttonPressed:(id)selector {
    UIButton *button = (UIButton *)selector;
    NSInteger index = button.tag - 800;

    if (delegate) {
        if ([delegate respondsToSelector:@selector(miniLikeButtonPressedForLiker:)]) {
            [delegate miniLikeButtonPressedForLiker:[self.likers objectAtIndex:index]];
        }
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
}

@end
