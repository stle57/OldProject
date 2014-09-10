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
    self.userNameLabel.font = TITLE_FONT;
    self.bioLabel.font = BIO_FONT;
    self.userImageView.layer.cornerRadius = 35;
    self.userImageView.layer.masksToBounds = YES;
    
    // Create post button
    CALayer * layer = [self.postButton layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle
    [layer setBorderWidth:.5];
    [layer setBorderColor:[[TDConstants commentTimeTextColor] CGColor]];

    // Create PR button
    CALayer * prLayer = [self.prButton layer];
    [prLayer setMasksToBounds:YES];
    [prLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle
    [prLayer setBorderWidth:.5];
    [prLayer setBorderColor:[[TDConstants commentTimeTextColor] CGColor]];

    
    // Follower button
    CALayer * followerLayer = [self.followerButton layer];
    [followerLayer setMasksToBounds:YES];
    [followerLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle
    [followerLayer setBorderWidth:.5];
    [followerLayer setBorderColor:[[TDConstants commentTimeTextColor] CGColor]];

    // Following Button

    CALayer * followingLayer = [self.followingButton layer];
    [followingLayer setMasksToBounds:YES];
    [followingLayer setCornerRadius:0.0]; //when radius is 0, the border is a rectangle
    [followingLayer setBorderWidth:.5];
    [followingLayer setBorderColor:[[TDConstants commentTimeTextColor] CGColor]];
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
    if(delegate && [delegate respondsToSelector:@selector(followerStatButtonPressed)]) {
        [delegate followerStatButtonPressed];
    }
}

- (IBAction)followingButtonPressed:(UIButton*)sender {
    if(delegate && [delegate respondsToSelector:@selector(followingStatButtonPressed)]) {
        [delegate followingStatButtonPressed];
    }
}
@end
