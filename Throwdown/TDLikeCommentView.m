//
//  TDLikeCommentView.m
//  Throwdown
//
//  Created by Andrew Bennett on 2/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLikeCommentView.h"
#import "TDAppDelegate.h"

@implementation TDLikeCommentView

@synthesize delegate;
@synthesize row;
@synthesize likers;
@synthesize comments;

- (void)dealloc
{
    delegate = nil;
    self.likers = nil;
    self.comments = nil;
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

-(void)setLikesArray:(NSArray *)array
{
    self.likers = array;

    // Hide more for now
    self.moreImageView.hidden = YES;
    if ([self.likers count] > 9) {
        self.moreImageView.hidden = NO;
    }

    self.likeIconImageView.hidden = YES;
    if ([self.likers count] > 0) {
        self.likeIconImageView.hidden = NO;
    }

    // Add image buttons
    for (NSDictionary *likerDict in self.likers) {
        if ([likerDict objectForKey:@"picture"]) {
            [self addButtonWithPicture:[likerDict objectForKey:@"picture"]
                                 index:[self.likers indexOfObject:likerDict]];
        }
    }
}

-(void)setCommentsArray:(NSArray *)array
{
    self.comments = array;
}

-(void)addButtonWithPicture:(NSString *)picture index:(NSInteger)index
{
    CGFloat gap = 3.0;
    CGFloat widthOfOne = ((self.moreImageView.frame.origin.x-CGRectGetMaxX(self.likeIconImageView.frame)-gap*12.0)/9.0);
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(((widthOfOne+gap)*index)+CGRectGetMaxX(self.likeIconImageView.frame)+gap*2.0,
                              0.0,
                              widthOfOne,
                              widthOfOne);
    button.center = CGPointMake(button.center.x,
                                self.likeIconImageView.center.y);
    button.backgroundColor = [TDAppDelegate randomColor];
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

-(void)buttonPressed:(id)selector
{
    UIButton *button = (UIButton *)selector;
    NSInteger index = button.tag-800;
    NSLog(@"Tapped like buton index:%ld", (long)index);

    if (delegate) {
        if ([delegate respondsToSelector:@selector(miniLikeButtonPressedForLiker:)]) {
            [delegate miniLikeButtonPressedForLiker:[self.likers objectAtIndex:index]];
        }
    }
}

@end
