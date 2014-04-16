//
//  TDDetailsLikesCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDDetailsLikesCell.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"

@implementation TDDetailsLikesCell

@synthesize delegate;
@synthesize row;
@synthesize likers;
@synthesize comments;

- (void)dealloc {
    delegate = nil;
    self.likers = nil;
    self.comments = nil;
}

- (IBAction)likeButtonPressed:(UIButton *)sender {
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

-(void)setLike:(BOOL)liked {
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

-(void)setLikesArray:(NSArray *)array {
    self.likers = array;

    if (!array) {
        return;
    }

    self.likeImageView.hidden = YES;
    if ([self.likers count] > 0) {
        self.likeImageView.hidden = NO;
    }

    // Remove any old buttons for cell reuse
//    UIView *buttonView = nil;
//    for (int i=800; i < 810; i++) {
//        buttonView = [self viewWithTag:i];
//        if (buttonView) {
//            [buttonView removeFromSuperview];
//        }
//        buttonView = nil;
//    }



    // Add likers label
    NSString *text = [[self.likers valueForKeyPath:@"username"] componentsJoinedByString:@", "];
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(,)" options:kNilOptions error:nil];
    NSRange range = NSMakeRange(0, text.length);
    [regex enumerateMatchesInString:text options:kNilOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange subStringRange = [result rangeAtIndex:1];
        [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:subStringRange];
    }];

    self.likersNamesLabel.font = [TDConstants fontSemiBoldSized:16.0];
    self.likersNamesLabel.attributedText = mutableAttributedString;

    [TDAppDelegate fixHeightOfThisLabel:self.likersNamesLabel];
}

+ (NSInteger)heightOfLikersLabel:(NSArray *)likers {
    NSString *text = [[likers valueForKeyPath:@"username"] componentsJoinedByString:@", "];
    return [TDAppDelegate heightOfTextForString:text
                                 andFont:[TDConstants fontSemiBoldSized:16.0]
                                 maxSize:CGSizeMake(217.0, MAXFLOAT)];
}

+(NSInteger)numberOfRowsForLikers:(NSInteger)count {
    // 9 per row
    return ceil((float)count / 9.0);
}

+(NSInteger)rowNumberForLiker:(NSInteger)index {
    // 9 per row
    return floor((float)index / 9.0);
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

-(void)buttonPressed:(id)selector {
    UIButton *button = (UIButton *)selector;
    NSInteger index = button.tag - 800;

    if (delegate) {
        if ([delegate respondsToSelector:@selector(miniAvatarButtonPressedForLiker:)]) {
            [delegate miniAvatarButtonPressedForLiker:[self.likers objectAtIndex:index]];
        }
    }
}

@end
