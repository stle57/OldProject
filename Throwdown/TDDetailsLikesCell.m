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
    self.likersNamesLabel.font = [TDConstants fontBoldSized:16.0];
    self.likersNamesLabel.delegate = self;
}

- (void)dealloc {
    delegate = nil;
    self.likers = nil;
    self.comments = nil;
    self.likersNamesLabel = nil;
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

    // Add likers label
    NSString *text = [[self.likers valueForKeyPath:@"username"] componentsJoinedByString:@", "];

    NSDictionary *userAttributes = @{ NSForegroundColorAttributeName:[TDConstants brandingRedColor] };
    [self.likersNamesLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {

        NSRange range = NSMakeRange(0, [mutableAttributedString string].length);
        NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\b\\w+\\b)" options:kNilOptions error:nil];
        [usernameRegex enumerateMatchesInString:[mutableAttributedString string] options:kNilOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            [mutableAttributedString addAttributes:userAttributes range:[result rangeAtIndex:1]];
        }];

        return mutableAttributedString;
    }];

    for (NSDictionary *user in self.likers) {
        NSString *pattern = [NSString stringWithFormat:@"(\\b%@\\b)", [user objectForKey:@"username"]];
        NSRegularExpression *usernameRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:nil];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [user objectForKey:@"id"]]];
        NSRange linkRange = [usernameRegex rangeOfFirstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
        [self.likersNamesLabel addLinkToURL:url withRange:linkRange];
    }
    [TDAppDelegate fixHeightOfThisLabel:self.likersNamesLabel];
}

+ (NSInteger)heightOfLikersLabel:(NSArray *)likers {
    NSString *text = [[likers valueForKeyPath:@"username"] componentsJoinedByString:@", "];
    return [TDAppDelegate heightOfTextForString:text
                                 andFont:[TDConstants fontSemiBoldSized:16.0]
                                 maxSize:CGSizeMake(217.0, MAXFLOAT)];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if (self.delegate && [self.delegate respondsToSelector:@selector(usernamePressedForLiker:)]) {
        [self.delegate usernamePressedForLiker:[NSNumber numberWithInteger:[[url absoluteString] integerValue]]];
    }
}

@end
