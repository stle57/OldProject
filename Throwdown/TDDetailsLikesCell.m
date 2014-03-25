//
//  TDDetailsLikesCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDDetailsLikesCell.h"
#import "TDAppDelegate.h"

@implementation TDDetailsLikesCell

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
    }
    return self;
}

- (IBAction)likeButtonPressed:(UIButton *)sender
{
    NSLog(@"TDDetailsLikesCell-likeButtonPressed:%@", delegate);
    if (like) {
        like = !like;
        if (delegate) {
            if ([delegate respondsToSelector:@selector(unLikeButtonPressedFromLikes)]) {
                [delegate unLikeButtonPressedFromLikes];
            }
        }
    } else {
        like = !like;
        if (delegate) {
            if ([delegate respondsToSelector:@selector(likeButtonPressedFromLikes)]) {
                [delegate likeButtonPressedFromLikes];
            }
        }
    }

    // Do it quick for speedy UI
    [self setLike:like];
}

-(void)setLike:(BOOL)liked
{
    NSLog(@"TDDetailsLikesCell-setLike:%d", like);
    like = liked;
    if (liked) {
        UIImage *buttonImage = [UIImage imageNamed:@"like_button_on.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateNormal];
        buttonImage = nil;
        buttonImage = [UIImage imageNamed:@"like_button_on.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateHighlighted];
        buttonImage = nil;
    } else {
        UIImage *buttonImage = [UIImage imageNamed:@"like_button.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateNormal];
        buttonImage = nil;
        buttonImage = [UIImage imageNamed:@"like_button.png"];
        [self.likeButton setImage:buttonImage forState:UIControlStateHighlighted];
        buttonImage = nil;
    }
}

-(void)setComment:(BOOL)commented
{
/*    UIImage *buttonImage = [UIImage imageNamed:@"but_comment_big.png"];
    [self.commentButton setImage:buttonImage forState:UIControlStateNormal];
    buttonImage = nil;
 */
}

-(void)setLikesArray:(NSArray *)array
{
    self.likers = array;

    self.likeImageView.hidden = YES;
    if ([self.likers count] > 0) {
        self.likeImageView.hidden = NO;
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
                                 index:index];
            index++;
        }
    }
}

+(NSInteger)numberOfRowsForLikers:(NSInteger)count
{
    // 9 per row
    return ceil((float)count/9.0);
}

+(NSInteger)rowNumberForLiker:(NSInteger)index
{
    // 9 per row
    return floor((float)index/9.0);
}

-(void)addButtonWithPicture:(NSString *)picture index:(NSInteger)index
{
    NSInteger likeRow = [TDDetailsLikesCell rowNumberForLiker:index];
    NSInteger position = (index-likeRow*9);

    CGFloat gap = 3.0;
    CGFloat widthOfOne = ((self.likeButton.frame.origin.x-CGRectGetMaxX(self.likeImageView.frame)-gap*12.0)/9.0);
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(((widthOfOne+gap)*position)+CGRectGetMaxX(self.likeImageView.frame)+gap*2.0,
                              0.0,
                              widthOfOne,
                              widthOfOne);
    button.center = CGPointMake(button.center.x,
                                self.likeImageView.center.y+(likeRow*(widthOfOne+1.0)));
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

-(void)buttonPressed:(id)selector
{
    UIButton *button = (UIButton *)selector;
    NSInteger index = button.tag-800;

    if (delegate) {
        if ([delegate respondsToSelector:@selector(miniAvatarButtonPressedForLiker:)]) {
            [delegate miniAvatarButtonPressedForLiker:[self.likers objectAtIndex:index]];
        }
    }
}

@end
