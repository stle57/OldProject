//
//  TDNoFollowProfileCell.h
//  Throwdown
//
//  Created by Stephanie Le on 9/14/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDNoFollowProfileCellDelegate <NSObject>
@optional
-(void)inviteButtonPressed;
-(void)findButtonPressed;
@end

@interface TDNoFollowProfileCell : UITableViewCell

@property (nonatomic, weak) id <TDNoFollowProfileCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *noFollowLabel;
@property (weak, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UIButton *findPeopleButton;
@property (weak, nonatomic) IBOutlet UIButton *invitePeopleButton;

- (IBAction)inviteButtonPressed:(UIButton*)sender;
- (IBAction)findButtonPressed:(UIButton*)sender;

@end
