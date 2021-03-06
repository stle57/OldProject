//
//  TDGuestInfoCellTableViewCell.h
//  Throwdown
//
//  Created by Stephanie Le on 12/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTTAttributedLabel.h>
@protocol TDGuestUserInfoCellDelegate <NSObject>
@optional
-(void)signupButtonPressed;
-(void)createPostButtonPressed;
-(void)dismissButtonPressed;
-(void)goalsButtonPressed;
-(void)dismissForExistingUser;
-(void)reloadTableView;
-(void)loadDetailView;
-(void)loginButtonPressed;
@end

@interface TDGuestInfoCell : UITableViewCell

@property (nonatomic, weak) id <TDGuestUserInfoCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UILabel *label4;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIView *bottomMarginPadding;
@property (weak, nonatomic) IBOutlet UIView *topMarginPadding;
@property (weak, nonatomic) IBOutlet UIButton *learnButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
- (void)setHashTagInfoCell;
+ (NSInteger)heightForHashTagInfoCell;

@property (weak, nonatomic) IBOutlet UIButton *closeButton;

- (void)setInfoCell;
- (void)setLastCell;
- (void)setNewUserCell:(BOOL)addTopMargin;
- (void)setGuestUserCell;
- (void)setExistingUserCell:(BOOL)addTopMargin;
- (void)setEditGoalsCell:(BOOL)showCloseButton;
+ (NSInteger)heightForLastCell;
+ (NSInteger)heightForInfoCell;
+ (NSInteger) heightForNewUserCell:(BOOL)addTopMargin;
+ (NSInteger) heightForGuestUserCell;
+ (NSInteger)heightForExistingUserCell:(BOOL)addTopMargin;
+ (NSInteger)heightForEditGoalsCell;
- (IBAction)signupButtonPressed:(id)sender;
- (IBAction)dismissButtonPressed:(id)sender;
- (IBAction)closeButtonPressed:(id)sender;
- (IBAction)loginButtonPressed:(id)sender;
@end
