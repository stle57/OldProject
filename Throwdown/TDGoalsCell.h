//
//  TDGoalsCell.h
//  Throwdown
//
//  Created by Stephanie Le on 12/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TDGoalsCellDelegate <NSObject>
@required
- (void)selectionButtonPressedFromRow:(NSInteger)row;
@optional
- (void)addGoals:(NSString*)text row:(NSInteger)row;
- (void)addNewGoalPressed:(NSInteger)row;
@end

@interface TDGoalsCell : UITableViewCell
@property (nonatomic, weak) id <TDGoalsCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *goalLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectionButton;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UITextField *editableTextField;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic) BOOL addedButton;

- (NSAttributedString *)makeTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight lineHeightMultipler:(CGFloat)lineHeightMultiplier;

- (IBAction)selectionButtonPressed:(id)sender;
- (IBAction)addNewGoalPressed;
- (void)textFieldEdited;
@end
