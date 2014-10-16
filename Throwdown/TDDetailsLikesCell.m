//
//  TDDetailsLikesCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDDetailsLikesCell.h"
#import "TDViewControllerHelper.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"

#define USERNAME_FONT [TDConstants fontSemiBoldSized:15];
static NSString *const kUserIdAttribute = @"user_id";
static CGFloat const kLikersLineMultiple = 1.05;

@interface TDDetailsLikesCell () <TTTAttributedLabelDelegate>
@end

@implementation TDDetailsLikesCell

@synthesize delegate;
@synthesize row;
@synthesize likers;
@synthesize comments;

- (void)awakeFromNib {
    [super awakeFromNib];

    self.likersNamesLabel.textColor = [UIColor darkGrayColor];
    self.likersNamesLabel.font = USERNAME_FONT;
    self.likersNamesLabel.delegate = self;
    self.likersNamesLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
}

- (void)dealloc {
    delegate = nil;
    self.likers = nil;
    self.comments = nil;
    self.likersNamesLabel = nil;
}

- (IBAction)likeButtonPressed:(UIButton *)sender {
    debug NSLog(@"TDDetailsLikesCell-likeButtonPressed:%@", delegate);
    if (like) {
        if (delegate && [delegate respondsToSelector:@selector(unLikeButtonPressedFromLikes)]) {
            [delegate unLikeButtonPressedFromLikes];
        }
    } else {
        if (delegate && [delegate respondsToSelector:@selector(likeButtonPressedFromLikes)]) {
            [delegate likeButtonPressedFromLikes];
        }
    }
    like = !like;
}

-(void)setLike:(BOOL)liked {
    debug NSLog(@"TDDetailsLikesCell-setLike:%d", like);
    like = liked;
    if (liked) {
        [self.likeButton setImage:[UIImage imageNamed:@"btn-liked"] forState:UIControlStateNormal];
        [self.likeButton setImage:[UIImage imageNamed:@"btn-liked-hit"] forState:UIControlStateHighlighted];
        [self.likeButton setImage:[UIImage imageNamed:@"btn-liked-hit"] forState:UIControlStateSelected];
    } else {
        [self.likeButton setImage:[UIImage imageNamed:@"btn-like"] forState:UIControlStateNormal];
        [self.likeButton setImage:[UIImage imageNamed:@"btn-like-hit"] forState:UIControlStateHighlighted];
        [self.likeButton setImage:[UIImage imageNamed:@"btn-like-hit"] forState:UIControlStateSelected];
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

    // Add likers label
    NSString *text = [[self.likers valueForKeyPath:@"username"] componentsJoinedByString:@", "];
    [self.likersNamesLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    [TDViewControllerHelper linkUsernamesInLabel:self.likersNamesLabel users:self.likers pattern:@"(\\b\\w+\\b)"];
    self.likersNamesLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:self.likersNamesLabel.attributedText withMultiple:kLikersLineMultiple];

    // manually fix the height b/c we force the width (AppDelegate method doesn't support it)
    NSInteger height = [TDDetailsLikesCell heightOfLikersLabel:likers];
    self.likersNamesLabel.frame = CGRectMake(self.likersNamesLabel.frame.origin.x,
                                             self.likersNamesLabel.frame.origin.y,
                                             self.likersNamesLabel.frame.size.width,
                                             height);
}

+ (CGFloat)heightOfLikersLabel:(NSArray *)likers {
    NSString *text = [[likers valueForKeyPath:@"username"] componentsJoinedByString:@", "];
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH - 75, MAXFLOAT)];
    label.numberOfLines = 0;
    label.font = USERNAME_FONT;
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    label.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:label.attributedText withMultiple:kLikersLineMultiple];
    [label sizeToFit];
    return label.frame.size.height;
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([TDViewControllerHelper isThrowdownURL:url] && self.delegate && [self.delegate respondsToSelector:@selector(usernamePressedForLiker:)]) {
        [self.delegate usernamePressedForLiker:[NSNumber numberWithInteger:[[[url path] lastPathComponent] integerValue]]];
    }
}

@end
