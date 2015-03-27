//
//  TDUserProfileCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDUser.h"
#import "TDConstants.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>

#define USERNAME_PROFILE_FONT [TDConstants fontSemiBoldSized:18.0];

typedef enum {
    UserProfileButtonTypeUnknown,
    UserProfileButtonTypeFollow,
    UserProfileButtonTypeFollowing,
    UserProfileButtonTypeInvite
} UserProfileButtonType;


static CGFloat const kBioLabelInviteButtonPadding = 14; // padding between bio label and invite button
static CGFloat const kInviteButtonStatButtonPadding = 25; // padding between invite button and stats buttons

@protocol TDUserProfileCellDelegate <NSObject>
@optional
-(void)inviteButtonPressedFromRow:(NSInteger)tag;
-(void)postsStatButtonPressed;
-(void)prStatButtonPressed;
-(void)followerStatButtonPressed;
-(void)followingStatButtonPressed;
@end

@interface TDUserProfileCell : UITableViewCell

@property (nonatomic, weak) id <TDUserProfileCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *bioLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIView *whiteUnderView;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UIButton *prButton;
@property (weak, nonatomic) IBOutlet UIButton *followerButton;
@property (weak, nonatomic) IBOutlet UIButton *followingButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (weak, nonatomic) IBOutlet UIView *buttonsTopBorder;
@property (nonatomic) NSURL *userImageURL;

@property (nonatomic, assign) CGRect origBioLabelRect;

- (void)setUser:(TDUser *)user withButton:(UserProfileButtonType)buttonType;
- (IBAction)inviteButtonPressed:(UIButton*)sender;
- (IBAction)postsButtonPressed:(UIButton*)sender;
- (IBAction)prButtonPressed:(UIButton*)sender;
- (IBAction)followerButtonPressed:(UIButton*)sender;
- (IBAction)followingButtonPressed:(UIButton*)sender;

+ (CGFloat)heightForUserProfile:(TDUser *)user;

@end
