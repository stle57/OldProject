//
//  TDInviteCell.h
//  Throwdown
//
//  Created by Stephanie Le on 9/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDInviteCellDelegate <NSObject>
@optional
- (void)checkButtonTapped:(id)sender event:(id)event;
@end

@interface TDInviteCell : UITableViewCell

@property (nonatomic, assign) id <TDInviteCellDelegate> __unsafe_unretained delegate;

@property (weak, nonatomic) IBOutlet UITextField *contactTextField;
@property (nonatomic) BOOL addedButton;
@end
