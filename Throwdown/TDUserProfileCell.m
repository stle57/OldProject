//
//  TDUserProfileCell.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserProfileCell.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "TDViewControllerHelper.h"
#import "TDAPIClient.h"

static CGFloat const kBottomMargin = 15;
static CGFloat const kMinHeight = 230 + kBottomMargin;

@implementation TDUserProfileCell

- (void)dealloc {
    self.delegate = nil;
}

- (void)awakeFromNib {
    self.userNameLabel.font = USERNAME_PROFILE_FONT;
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    self.bioLabel.font = BIO_FONT;
    self.locationLabel.font = BIO_FONT;
    self.userImageView.layer.cornerRadius = 35;
    self.userImageView.layer.masksToBounds = YES;
    self.origBioLabelRect = self.bioLabel.frame;

    CGRect borderFrame = self.buttonsTopBorder.frame;
    borderFrame.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    self.buttonsTopBorder.frame = borderFrame;

    UIView *leftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TD_CELL_BORDER_WIDTH, self.postButton.frame.size.height) ];
    leftBorder.backgroundColor = [TDConstants darkBorderColor];
    [self.postButton addSubview:leftBorder];

    CALayer * postLayer = [self.postButton layer];
    [postLayer setMasksToBounds:YES];
    [postLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle

    UIView *prLeftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TD_CELL_BORDER_WIDTH, self.prButton.frame.size.height) ];
    prLeftBorder.backgroundColor = [TDConstants darkBorderColor];
    [self.prButton addSubview:prLeftBorder];

    CALayer * prLayer = [self.prButton layer];
    [prLayer setMasksToBounds:YES];
    [prLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle

    UIView *followerTopBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
            self.followerButton.frame.size.width, TD_CELL_BORDER_WIDTH) ];
    followerTopBorder.backgroundColor = [TDConstants commentTimeTextColor];
    [self.followerButton addSubview:followerTopBorder];
    self.followerButton.layer.borderWidth = 0.f;

    UIView *followerLeftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                         TD_CELL_BORDER_WIDTH, self.followerButton.frame.size.height) ];
    followerLeftBorder.backgroundColor = [TDConstants darkBorderColor];
    [self.followerButton addSubview:followerLeftBorder];

    CALayer * followerLayer = [self.followerButton layer];
    [followerLayer setMasksToBounds:YES];
    [followerLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle

    UIView *followingLeftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                          TD_CELL_BORDER_WIDTH, self.followingButton.frame.size.height) ];
    followingLeftBorder.backgroundColor = [TDConstants darkBorderColor];
    [self.followingButton addSubview:followingLeftBorder];

    CALayer * followingLayer = [self.followingButton layer];
    [followingLayer setMasksToBounds:YES];
    [followingLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle
}

- (void)setUser:(TDUser *)user withButton:(UserProfileButtonType)buttonType {
    self.bioLabel.hidden = YES;
    self.locationLabel.hidden = YES;
    
    CGFloat offset = self.bioLabel.frame.origin.y;

    if (user) {
        self.userNameLabel.text = user.name;
        if (user.bio && ![user.bio isKindOfClass:[NSNull class]]) {
            self.bioLabel.attributedText = (NSMutableAttributedString *)[TDViewControllerHelper makeParagraphedTextWithBioString:user.bio];

            CGRect bioFrame = self.bioLabel.frame;
            bioFrame.size.height = user.bioHeight;
            self.bioLabel.frame = bioFrame;
            self.bioLabel.hidden = NO;
            offset += user.bioHeight;
        }
        
        if (user.location && ![user.location isKindOfClass:[NSNull class]]) {
            self.locationLabel.attributedText = (NSMutableAttributedString *)[TDViewControllerHelper makeParagraphedTextWithBioString:user.location];
            
            CGRect locationFrame = self.locationLabel.frame;
            locationFrame.size.height = user.locationHeight;
            
            if (user.bio && ![user.bio isKindOfClass:[NSNull class]]) {
                locationFrame.origin.y = self.bioLabel.frame.origin.y + self.bioLabel.frame.size.height;
                offset += self.locationLabel.frame.size.height;
            } else {
                offset = self.locationLabel.frame.origin.y;
            }
            self.locationLabel.frame = locationFrame;
            self.locationLabel.hidden = NO;
        }
    }

    // Now move the invite button down
    CGRect newInviteButtonFrame = self.inviteButton.frame;
    newInviteButtonFrame.origin.y = offset + kBioLabelInviteButtonPadding + 1; // 1 makes the borders go all the way to the bottom
    self.inviteButton.frame = newInviteButtonFrame;

    // Move the stat buttons down
    CGFloat yStatButtonPosition = newInviteButtonFrame.origin.y + newInviteButtonFrame.size.height + kInviteButtonStatButtonPadding;

    CGRect borderFrame = self.buttonsTopBorder.frame;
    borderFrame.origin.y = yStatButtonPosition;
    self.buttonsTopBorder.frame = borderFrame;

    CGRect newPostButtonFrame = self.postButton.frame;
    newPostButtonFrame.origin.y = yStatButtonPosition;
    self.postButton.frame = newPostButtonFrame;

    CGRect newPrButtonFrame = self.prButton.frame;
    newPrButtonFrame.origin.y = yStatButtonPosition;
    self.prButton.frame = newPrButtonFrame;

    CGRect newFollowersFrame = self.followerButton.frame;
    newFollowersFrame.origin.y = yStatButtonPosition;
    self.followerButton.frame = newFollowersFrame;

    CGRect newFollowingFrame = self.followingButton.frame;
    newFollowingFrame.origin.y = yStatButtonPosition;
    self.followingButton.frame = newFollowingFrame;

    if (user && ![user hasDefaultPicture]) {
        [[TDAPIClient sharedInstance] setImage:@{@"imageView":self.userImageView,
                                                 @"filename":user.picture,
                                                 @"width":@70,
                                                 @"height":@70}];
    }

    switch (buttonType) {
        case UserProfileButtonTypeFollow:
            self.inviteButton.enabled = YES;
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-follow.png"] forState:UIControlStateNormal];
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-follow-hit.png"] forState:UIControlStateSelected];
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-follow-hit.png"] forState:UIControlStateHighlighted];
            [self.inviteButton setTag:kFollowButtonTag];
            break;

        case UserProfileButtonTypeFollowing:
            self.inviteButton.enabled = YES;
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-following.png"] forState:UIControlStateNormal];
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-following-hit.png"] forState:UIControlStateSelected];
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-following-hit.png"] forState:UIControlStateHighlighted];
            [self.inviteButton setTag:kFollowingButtonTag];
            break;

        case UserProfileButtonTypeInvite:
            self.inviteButton.enabled = YES;
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends.png"] forState:UIControlStateNormal];
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends-hit.png"] forState:UIControlStateSelected];
            [self.inviteButton setImage:[UIImage imageNamed:@"btn-invite-friends-hit.png"] forState:UIControlStateHighlighted];
            [self.inviteButton setTag:kInviteButtonTag];
            break;
        case UserProfileButtonTypeUnknown:
            self.inviteButton.enabled = NO;
            break;
    }

    [self modifyStatButtonString:self.postButton statCount:user.postCount textString:@"\nPosts"];
    [self modifyStatButtonString:self.prButton statCount:user.prCount textString:@"\nPRs"];
    [self modifyStatButtonString:self.followerButton statCount:user.followerCount textString:@"\nFollowers"];
    [self modifyStatButtonString:self.followingButton statCount:user.followingCount textString:@"\nFollowing"];

    CGRect frame = self.whiteUnderView.frame;
    frame.size.height = [[self class] heightForUserProfile:user] - kBottomMargin;
    self.whiteUnderView.frame = frame;
    CGFloat lineWidth = (1.0 / [[UIScreen mainScreen] scale]);
    self.bottomLine.frame = CGRectMake(0, frame.size.height, SCREEN_WIDTH, lineWidth);
}

-(void)modifyStatButtonString:(UIButton*)button statCount:(NSNumber*)statCount textString:(NSString*)textString{
    UIFont *font = [TDConstants fontSemiBoldSized:18.0];
    UIFont *font2= [TDConstants fontRegularSized:14];
    NSString *number;
    if (statCount) {
        number = statCount.intValue > 500 ? @"500+" : statCount.stringValue;
    } else {
        number = @"";
    }
    NSString *postString = [NSString stringWithFormat:@"%@%@", number, textString];

    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:postString];
    [attString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, postString.length)];
    [attString addAttribute:NSForegroundColorAttributeName value:[TDConstants brandingRedColor] range:NSMakeRange(0, postString.length)];
    [attString addAttribute:NSFontAttributeName value:font2 range:NSMakeRange(postString.length - textString.length, textString.length)];
    [attString addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange(postString.length - textString.length, textString.length)];

    button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;

    [button setAttributedTitle:attString forState:UIControlStateNormal];
}

- (IBAction)inviteButtonPressed:(UIButton *)sender {
    debug NSLog(@"TDUserProfileCell-inviteButtonPressed");

    if (self.delegate && [self.delegate respondsToSelector:@selector(inviteButtonPressedFromRow:)]) {
        [self.delegate inviteButtonPressedFromRow:sender.tag];
    }
}

- (IBAction)postsButtonPressed:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(postsStatButtonPressed)]) {
        [self.delegate postsStatButtonPressed];
    }
}

- (IBAction)prButtonPressed:(UIButton*)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(prStatButtonPressed)]) {
        [self.delegate prStatButtonPressed];
    }
}

- (IBAction)followerButtonPressed:(UIButton*)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(followerStatButtonPressed)]) {
        [self.delegate followerStatButtonPressed];
    }
}

- (IBAction)followingButtonPressed:(UIButton*)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(followingStatButtonPressed)]) {
        [self.delegate followingStatButtonPressed];
    }
}

+ (CGFloat)heightForUserProfile:(TDUser *)user {
    if (user) {
        return kMinHeight + user.bioHeight + (user.bioHeight > 0 ? 0 : 0) +user.locationHeight + (user.locationHeight > 0 ? 0: 0);
    } else {
        return kMinHeight;
    }
}

@end
