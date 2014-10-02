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

#define USERNAME_PROFILE_FONT [TDConstants fontSemiBoldSized:18.0];

@protocol TDUserProfileCellDelegate <NSObject>
@optional
-(void)inviteButtonPressedFromRow:(NSInteger)tag;
-(void)postsStatButtonPressed;
-(void)prStatButtonPressed;
-(void)followerStatButtonPressed;
-(void)followingStatButtonPressed;
@end

@interface TDUserProfileCell : UITableViewCell
{
    id <TDUserProfileCellDelegate> __unsafe_unretained delegate;
}

@property (nonatomic, assign) id <TDUserProfileCellDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *bioLabel;
@property (weak, nonatomic) IBOutlet UIView *whiteUnderView;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UIButton *prButton;
@property (weak, nonatomic) IBOutlet UIButton *followerButton;
@property (weak, nonatomic) IBOutlet UIButton *followingButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (nonatomic, assign) CGRect origBioLabelRect;


//@property (nonatomic, readonly) TDUser *user;

- (void)modifyStatButtonAttributes:(TDUser*)user;
- (IBAction)inviteButtonPressed:(UIButton*)sender;
- (IBAction)postsButtonPressed:(UIButton*)sender;
- (IBAction)prButtonPressed:(UIButton*)sender;
- (IBAction)followerButtonPressed:(UIButton*)sender;
- (IBAction)followingButtonPressed:(UIButton*)sender;

@end
