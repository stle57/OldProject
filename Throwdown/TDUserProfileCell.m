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

@implementation TDUserProfileCell

@synthesize delegate;

- (void)dealloc {
    delegate = nil;
}

- (void)awakeFromNib {
    self.userNameLabel.font = USERNAME_PROFILE_FONT;
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    self.bioLabel.font = BIO_FONT;
    self.userImageView.layer.cornerRadius = 35;
    self.userImageView.layer.masksToBounds = YES;
    
    // Create post button
    // For post button, need top border and left border
    UIView *topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                self.postButton.frame.size.width, TD_CELL_BORDER_WIDTH) ];
    topBorder.backgroundColor = [TDConstants commentTimeTextColor];
    [self.postButton addSubview:topBorder];
    
    UIView *leftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TD_CELL_BORDER_WIDTH, self.postButton.frame.size.height) ];
    leftBorder.backgroundColor = [TDConstants commentTimeTextColor];
    [self.postButton addSubview:leftBorder];
    CALayer * postLayer = [self.postButton layer];
    [postLayer setMasksToBounds:YES];
    [postLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle

    // Create PR button
    // For pr button, need top and left border
    // For post button, need top border and left border
    UIView *prTopBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.prButton.frame.size.width, TD_CELL_BORDER_WIDTH) ];
    prTopBorder.backgroundColor = [TDConstants commentTimeTextColor];
    [self.prButton addSubview:prTopBorder];
    
    UIView *prLeftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TD_CELL_BORDER_WIDTH, self.prButton.frame.size.height) ];
    prLeftBorder.backgroundColor = [TDConstants commentTimeTextColor];
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
    followerLeftBorder.backgroundColor = [TDConstants commentTimeTextColor];
    [self.followerButton addSubview:followerLeftBorder];
    
    CALayer * followerLayer = [self.followerButton layer];
    [followerLayer setMasksToBounds:YES];
    [followerLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle
    // Following Button
    //For following button, need top and right border
    UIView *followingTopBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                         self.followingButton.frame.size.width, TD_CELL_BORDER_WIDTH) ];
    followingTopBorder.backgroundColor = [TDConstants commentTimeTextColor];
    [self.followingButton addSubview:followingTopBorder];
    
    UIView *followingLeftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                          TD_CELL_BORDER_WIDTH, self.followingButton.frame.size.height) ];
    followingLeftBorder.backgroundColor = [TDConstants commentTimeTextColor];
    [self.followingButton addSubview:followingLeftBorder];
    
    CALayer * followingLayer = [self.followingButton layer];
    [followingLayer setMasksToBounds:YES];
    [followingLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle
}


- (void)modifyStatButtonAttributes:(TDUser*)user {
    
    [self modifyStatButtonString:self.postButton statCount:user.postCount textString:@"\nPosts"];
    [self modifyStatButtonString:self.prButton statCount:user.prCount textString:@"\nPRs"];
    [self modifyStatButtonString:self.followerButton statCount:user.followerCount textString:@"\nFollowers"];
    [self modifyStatButtonString:self.followingButton statCount:user.followingCount textString:@"\nFollowing"];
}

-(void)modifyStatButtonString:(UIButton*)button statCount:(NSNumber*)statCount textString:(NSString*)textString{
    UIFont *font = [TDConstants fontSemiBoldSized:18.0];
    UIFont *font2= [TDConstants fontRegularSized:14];
    NSString *postString = [NSString stringWithFormat:@"%@%@", statCount.intValue > 500 ? @"500+" : statCount.stringValue, textString];
    
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
    
   
    if (delegate && [delegate respondsToSelector:@selector(inviteButtonPressedFromRow:)]) {
        [delegate inviteButtonPressedFromRow:sender.tag];
    }
}

- (IBAction)postsButtonPressed:(UIButton *)sender {
    if(delegate && [delegate respondsToSelector:@selector(postsStatButtonPressed)]) {
        [delegate postsStatButtonPressed];
    }
}

- (IBAction)prButtonPressed:(UIButton*)sender {
    if(delegate && [delegate respondsToSelector:@selector(prStatButtonPressed)]) {
        [delegate prStatButtonPressed];
    }
}

- (IBAction)followerButtonPressed:(UIButton*)sender {
    debug NSLog(@"HIT FOLLOWER BUTTON");
    if(delegate && [delegate respondsToSelector:@selector(followerStatButtonPressed)]) {
        [delegate followerStatButtonPressed];
    }
}

- (IBAction)followingButtonPressed:(UIButton*)sender {
    debug NSLog(@"hit FOLLOWING BUTTON");
    if(delegate && [delegate respondsToSelector:@selector(followingStatButtonPressed)]) {
        [delegate followingStatButtonPressed];
    }
}
@end
