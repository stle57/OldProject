//
//  TDGoalsCell.m
//  Throwdown
//
//  Created by Stephanie Le on 12/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDGoalsCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"

@implementation TDGoalsCell
@synthesize addedButton;

- (void)awakeFromNib {
    // Initialization code
    CGRect cellFrame = self.frame;
    cellFrame.size.width = SCREEN_WIDTH;
    self.frame = cellFrame;
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.width = SCREEN_WIDTH;
    self.contentView.frame = contentViewFrame;
    
    self.goalLabel.frame = CGRectMake(20, self.frame.size.height/2 - self.goalLabel.frame.size.height/2, SCREEN_WIDTH - 40, self.frame.size.height);
    
    self.editableTextField.frame = self.goalLabel.frame;
    self.editableTextField.textColor = [TDConstants headerTextColor];
    self.editableTextField.font = [TDConstants fontRegularSized:16.];
    
    CGRect bottomLineRect = self.bottomLine.frame;
    bottomLineRect.size.width = SCREEN_WIDTH - 40;
    bottomLineRect.size.height = 1;
    bottomLineRect.origin.x = 20;
    bottomLineRect.origin.y = 43.5;
    self.bottomLine.frame = bottomLineRect;
    self.bottomLine.backgroundColor = [TDConstants disabledTextColor];
    
    CGRect selectionFrame = self.selectionButton.frame;
    selectionFrame.origin.x = SCREEN_WIDTH - self.selectionButton.frame.size.width - 20;
    selectionFrame.origin.y = self.frame.size.height/2 - self.selectionButton.frame.size.height/2;
    self.selectionButton.frame = selectionFrame;
    
    self.selectionButton.imageView.image = [UIImage imageNamed:@"checkbox_empty"];
    self.selectionButton.tag = 0;
    
    CGRect addButtonFrame = self.addButton.frame;
    NSString *text = @"Add your own";
    NSAttributedString *addStr = [self makeTextWithString:text font:[TDConstants fontRegularSized:16] color:[TDConstants brandingRedColor] lineHeight:16 lineHeightMultipler:16/16];
    [self.addButton setAttributedTitle:addStr forState:UIControlStateNormal];
    
    [self.addButton sizeToFit];
    addButtonFrame.origin.x = self.frame.size.width/2 - self.addButton.frame.size.width/2;
    addButtonFrame.origin.y = self.frame.size.height/2 - self.addButton.frame.size.height/2;
    self.addButton.frame = addButtonFrame;
    self.addButton.hidden = YES;
    
    [self.editableTextField addTarget:self action:@selector(textFieldEdited) forControlEvents:UIControlEventEditingDidBegin];
    
    self.backgroundColor = [UIColor clearColor];
    //self.addedButton = NO;
    
    self.addGoalButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frame = CGRectMake(self.frame.size.width - 20 - 44, 0, 44, 44);
    self.addGoalButton.frame = frame;
    
    [self.addGoalButton.titleLabel setFont:[TDConstants fontRegularSized:16]];
    [self.addGoalButton setTitle:@"Add" forState:UIControlStateNormal];
    [self.addGoalButton setTitleColor:[TDConstants brandingRedColor] forState:UIControlStateNormal];
    [self.addGoalButton addTarget:self action:@selector(addGoalsData:)  forControlEvents:UIControlEventTouchUpInside];
    self.addGoalButton.backgroundColor = [UIColor clearColor];
    [self.addGoalButton sizeToFit];
    
    CGRect addFrame = self.addGoalButton.frame;
    addFrame.origin.x = SCREEN_WIDTH - 20 - self.addGoalButton.frame.size.width;
    addFrame.origin.y = self.frame.size.height/2 - self.addGoalButton.frame.size.height/2;
    self.addGoalButton.frame = addFrame;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (NSAttributedString *)makeTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight lineHeightMultipler:(CGFloat)lineHeightMultiplier{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:lineHeightMultiplier];
    [paragraphStyle setMinimumLineHeight:lineHeight];
    [paragraphStyle setMaximumLineHeight:lineHeight];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, text.length)];
    return attributedString;
}

- (IBAction)selectionButtonPressed:(id)sender {
    debug NSLog(@"selection button pressed");
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectionButtonPressedFromRow:)]) {
        [self.delegate selectionButtonPressedFromRow:self.row];
    }
}

- (IBAction)addNewGoalPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(addNewGoalPressed:)]) {
        [self.delegate addNewGoalPressed:self.row];
    }
}

- (void)textFieldEdited{
    debug NSLog(@"textFieldEdited");
    if (!self.addedButton) {
        [self setAccessoryType:UITableViewCellAccessoryNone];
        CGRect bottomLine = self.bottomLine.frame;
        bottomLine.origin.y = 44;
        self.bottomLine.frame = bottomLine;
        
        [self addSubview:self.addGoalButton];
        
        debug NSLog(@"button frame = %@", NSStringFromCGRect(self.addGoalButton.frame));
        debug NSLog(@"bottom line frame=%@", NSStringFromCGRect(self.bottomLine.frame));
        debug NSLog(@"cell frame = %@", NSStringFromCGRect(self.frame));
        debug NSLog(@"accessory view frame = %@", NSStringFromCGRect(self.accessoryView.frame));

        
        self.addedButton = YES;
    } else {
        debug NSLog(@"....");
//        self.accessoryView = nil;
//        self.accessoryType = UITableViewCellAccessoryNone;
//        self.addedButton = NO;
    }
}

- (void)addGoalsData:(id)sender{
    if(self.delegate && [self.delegate respondsToSelector:@selector(addGoals:row:)]) {
        [self.delegate addGoals:self.editableTextField.text row:self.row];
    }
}

- (void)createCell:(BOOL)createAddButton text:(NSString*)text {
    self.bottomLine.hidden = NO;
    self.goalLabel.hidden = NO;
    self.addButton.hidden = YES;
    self.selectionButton.hidden = NO;
    self.editableTextField.hidden = YES;
    
    if (createAddButton) {
        CGRect frame = self.frame;
        frame.size.height = 59;
        self.frame = frame;
        self.goalLabel.hidden = YES;
        self.addButton.hidden = NO;
        self.selectionButton.hidden = YES;
        CGRect buttonFrame = self.addButton.frame;
        buttonFrame.origin.x = self.frame.size.width/2 - self.addButton.frame.size.width/2;
        buttonFrame.origin.y = self.frame.size.height/2 - self.addButton.frame.size.height/2;
        self.addButton.frame = buttonFrame;
        self.bottomLine.hidden = YES;
        

    } else {
        NSAttributedString *attString = [TDViewControllerHelper makeLeftAlignedTextWithString:text font:[TDConstants fontRegularSized:16.] color:[TDConstants headerTextColor] lineHeight:16. lineHeightMultipler:16./16.];
        self.goalLabel.attributedText = attString;
        [self.goalLabel sizeToFit];
    }
    
    CGRect goalFrame = self.goalLabel.frame;
    goalFrame.origin.y = self.frame.size.height/2 - self.goalLabel.frame.size.height/2;
    self.goalLabel.frame = goalFrame;

    self.editableTextField.frame = goalFrame;

}

- (void)changeCellToAddGoals {
    [self.addGoalButton removeFromSuperview];
    CGRect frame = self.frame;
    frame.size.height = 44;
    self.frame = frame;
    
    CGRect goalLabelFrame = self.goalLabel.frame;
    goalLabelFrame.origin.y = self.frame.size.height/2 - self.goalLabel.frame.size.height/2;
    self.goalLabel.frame = goalLabelFrame;

    self.selectionButton.hidden = NO;
    [self.selectionButton setImage:[UIImage imageNamed:@"checkbox_checked"] forState:UIControlStateNormal];
    self.selectionButton.tag = 1;
    self.selectionButton.userInteractionEnabled = YES;
    [self.editableTextField resignFirstResponder];
    self.goalLabel.attributedText = [TDViewControllerHelper makeLeftAlignedTextWithString:self.editableTextField.text font:[TDConstants fontRegularSized:16] color:[TDConstants brandingRedColor] lineHeight:16 lineHeightMultipler:16/16];
    
    self.editableTextField.hidden = YES;
    self.goalLabel.hidden = NO;
    self.bottomLine.hidden = NO;

}

- (void)makeCellFirstResponder {
    CGRect frame = self.frame;
    frame.size.height = 44;
    self.frame = frame;
    
    self.goalLabel.hidden = YES;
    self.addButton.hidden = YES;
    self.editableTextField.hidden = NO;
    CGRect editableTextFieldFrame = self.editableTextField.frame;
    editableTextFieldFrame.origin.y = self.frame.size.height/2 - self.editableTextField.frame.size.height/2;
    self.editableTextField.frame = editableTextFieldFrame;
    
    [self.editableTextField becomeFirstResponder];
    debug NSLog(@"cell.editableTextField.frame = %@",NSStringFromCGRect( self.editableTextField.frame));
    [self.editableTextField setEnablesReturnKeyAutomatically:YES];
    self.bottomLine.hidden = NO;
    debug NSLog(@"cell.bottomLine.frame = %@", NSStringFromCGRect(self.bottomLine.frame));
}

- (void)setSelectionButton {
    if (self.selectionButton.tag == 0) {
        [self.selectionButton setImage:[UIImage imageNamed:@"checkbox_checked"] forState:UIControlStateNormal] ;
        NSAttributedString *str =
        [TDViewControllerHelper makeLeftAlignedTextWithString:self.goalLabel.attributedText.string font:[TDConstants fontRegularSized:16] color:[TDConstants brandingRedColor] lineHeight:16. lineHeightMultipler:16/16];
        self.goalLabel.attributedText = str;
        self.selectionButton.tag = 1;
    } else {
        [self.selectionButton setImage:[UIImage imageNamed:@"checkbox_empty"] forState:UIControlStateNormal];
        self.selectionButton.tag = 0;
        NSAttributedString *attString = [TDViewControllerHelper makeLeftAlignedTextWithString:self.goalLabel.attributedText.string font:[TDConstants fontRegularSized:16.] color:[TDConstants headerTextColor] lineHeight:16. lineHeightMultipler:16./16.];
        self.goalLabel.attributedText = attString;
    }

}
@end
