//
//  TDFollowProfileCell.h
//  Throwdown
//
//  Created by Stephanie Le on 9/12/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDUser.h"

@protocol TDFollowProfileCellDelegate <NSObject>
@required
- (void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag;
@optional
- (void)userProfilePressedWithId:(NSNumber *)userId;
@end

@interface TDFollowProfileCell : UITableViewCell
{
    id <TDFollowProfileCellDelegate> __unsafe_unretained delegate;
    CGFloat bottomLineOrigY;
}

@property (nonatomic, assign) id <TDFollowProfileCellDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
//@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@property (nonatomic, assign) NSNumber *userId;
@property (nonatomic, assign) NSInteger row;

//@property (nonatomic, assign) CGRect textViewdOrigRect;
//@property (nonatomic, assign) CGFloat bottomLineOrigY;
//
- (IBAction)actionButtonPressed:(UIButton*)sender;
- (IBAction)followActionButtonPressed:(UIButton*)sender;
- (IBAction)unFollowActionButtonPressed:(UIButton*)sender;
@end
