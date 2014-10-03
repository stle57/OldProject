//
//  TDInviteCell.m
//  Throwdown
//
//  Created by Stephanie Le on 9/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDInviteCell.h"
#import "TDConstants.h"
#import "NBPhoneNumberUtil.h"

@implementation TDInviteCell

@synthesize delegate;
@synthesize addedButton;

- (void)awakeFromNib
{
    // Initialization code
    self.layer.borderColor = [[TDConstants cellBorderColor] CGColor];
    self.layer.borderWidth = TD_CELL_BORDER_WIDTH;
    self.contactTextField.font = [TDConstants fontRegularSized:16];
    self.contactTextField.textColor = [TDConstants headerTextColor];
    
    [self.contactTextField addTarget:self action:@selector(textFieldEdited) forControlEvents:UIControlEventEditingChanged];
    self.addedButton = NO;
}

- (void)dealloc {
    self.delegate = nil;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)textFieldEdited{
    debug NSLog(@"edited");
    if (!self.addedButton && self.contactTextField.text.length > 0) {
            [self setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            CGRect frame = CGRectMake(self.accessoryView.frame.origin.x, self.accessoryView.frame.size.height, 44, 44);
            button.frame = frame;
            [button.titleLabel setFont:[TDConstants fontRegularSized:16]];
            [button setTitle:@"Add" forState:UIControlStateNormal];
            [button setTitleColor:[TDConstants brandingRedColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(addInviteData:event:)  forControlEvents:UIControlEventTouchUpInside];
            button.backgroundColor = [UIColor clearColor];
            self.accessoryView = button;
        self.addedButton = YES;
    } else if (self.addedButton && self.contactTextField.text.length == 0) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.accessoryView = nil;
        self.addedButton = NO;
    }
}

- (void)addInviteData:(id)sender event:(id)event {
    if(delegate && [delegate respondsToSelector:@selector(checkButtonTapped:event:)]) {
        [delegate checkButtonTapped:sender event:event];
        self.accessoryView = nil;
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}
@end
