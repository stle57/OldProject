//
//  TDGoalsCell.m
//  Throwdown
//
//  Created by Stephanie Le on 12/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDGoalsCell.h"
#import "TDConstants.h"

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
    bottomLineRect.origin.y = 43;
    self.bottomLine.frame = bottomLineRect;
    self.bottomLine.backgroundColor = [TDConstants commentTimeTextColor];
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
        [self setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = CGRectMake(self.accessoryView.frame.origin.x, self.accessoryView.frame.origin.y, self.accessoryView.frame.size.width, self.accessoryView.frame.size.height);
        button.frame = frame;
        [button.titleLabel setFont:[TDConstants fontRegularSized:16]];
        [button setTitle:@"Add" forState:UIControlStateNormal];
        [button setTitleColor:[TDConstants brandingRedColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(addInviteData:event:)  forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor clearColor];
        [button sizeToFit];
        debug NSLog(@"button frame = %@", NSStringFromCGRect(button.frame));
        self.accessoryView = button;
        debug NSLog(@"accessory vie wframe = %@", NSStringFromCGRect(self.accessoryView.frame));
        self.accessoryView.layer.borderColor = [[UIColor magentaColor] CGColor];
        self.accessoryView.layer.borderWidth = 2.;
//        self.layer.borderColor = [[UIColor blueColor] CGColor];
//        self.layer.borderWidth = 2.;
        self.addedButton = YES;
        self.bottomLine.layer.borderColor = [[UIColor greenColor] CGColor];
        self.bottomLine.layer.borderWidth = 1.;
    } else {
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.addedButton = NO;
    }
}

- (void)addInviteData:(id)sender event:(id)event {
    if(self.delegate && [self.delegate respondsToSelector:@selector(addGoals:row:)]) {
        [self.delegate addGoals:self.editableTextField.text row:self.row];
    }
}
@end
