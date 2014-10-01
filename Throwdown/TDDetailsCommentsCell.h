//
//  TDDetailsCommentsCellCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDComment.h"
#import "TDUpdatingDateLabel.h"
#import <TTTAttributedLabel.h>

@protocol TDDetailsCommentsCellDelegate <NSObject>
@optional
- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber;
- (void)userProfilePressedWithId:(NSNumber *)userId;
@end

@interface TDDetailsCommentsCell : UITableViewCell <TTTAttributedLabelDelegate>

@property (nonatomic, assign) id <TDDetailsCommentsCellDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) NSInteger commentNumber;
@property (weak, nonatomic) IBOutlet UIImageView *commentIcon;
@property (weak, nonatomic) IBOutlet TDUpdatingDateLabel *timeLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

- (void)updateWithComment:(TDComment *)comment showIcon:(BOOL)showIcon;
- (IBAction)userButtonPressed:(id)sender;
@end
