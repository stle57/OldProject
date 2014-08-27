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

static NSString *const kUserIdAttribute = @"user_id";

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
    debug NSLog(@"TDDetailsLikesCell-setLike:%d", like);
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

    // Add likers label
    NSString *text = [[self.likers valueForKeyPath:@"username"] componentsJoinedByString:@", "];
    [self.likersNamesLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    [TDViewControllerHelper linkUsernamesInLabel:self.likersNamesLabel users:self.likers pattern:@"(\\b\\w+\\b)"];
    self.likersNamesLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:self.likersNamesLabel.attributedText];

    // manually fix the height b/c we force the width down to 210 (AppDelegate method doesn't support it)
    NSInteger height = [TDDetailsLikesCell heightOfLikersLabel:likers];
    self.likersNamesLabel.frame = CGRectMake(self.likersNamesLabel.frame.origin.x,
                                             self.likersNamesLabel.frame.origin.y,
                                             self.likersNamesLabel.frame.size.width,
                                             height);
}

+ (NSInteger)heightOfLikersLabel:(NSArray *)likers {
    NSString *text = [[likers valueForKeyPath:@"username"] componentsJoinedByString:@", "];
    NSInteger height = [TDAppDelegate heightOfTextForString:text
                                                    andFont:USERNAME_FONT
                                                    maxSize:CGSizeMake(210.0, MAXFLOAT)];
    return height;
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([TDViewControllerHelper isThrowdownURL:url] && self.delegate && [self.delegate respondsToSelector:@selector(usernamePressedForLiker:)]) {
        [self.delegate usernamePressedForLiker:[NSNumber numberWithInteger:[[[url path] lastPathComponent] integerValue]]];
    }
}

@end
