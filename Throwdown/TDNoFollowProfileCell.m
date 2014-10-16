//
//  TDNoFollowProfileCell.m
//  Throwdown
//
//  Created by Stephanie Le on 9/14/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDNoFollowProfileCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "NSDate+TimeAgo.h"

@implementation TDNoFollowProfileCell

@synthesize delegate;

- (void)awakeFromNib {
    CGRect cellFrame = self.frame;
    cellFrame.size.width = SCREEN_WIDTH;
    self.frame = cellFrame;
    
    CGRect labelFrame = self.noFollowLabel.frame;
    labelFrame.size.width = SCREEN_WIDTH;
    self.noFollowLabel.frame = labelFrame;
    
    CGRect inviteFrame = self.invitePeopleButton.frame;
    inviteFrame.origin.x = SCREEN_WIDTH/2 + 10;// self.findPeopleButton.frame.origin.x + self.findPeopleButton.frame.size.width + 10;
    self.invitePeopleButton.frame = inviteFrame;
    
    CGRect findFrame = self.findPeopleButton.frame;
    findFrame.origin.x = SCREEN_WIDTH/2 - self.findPeopleButton.frame.size.width - 10;
    self.findPeopleButton.frame = findFrame;
    
    self.noFollowLabel.font = [TDConstants fontSemiBoldSized:17];
    self.noFollowLabel.textColor = [TDConstants headerTextColor];
    self.view.backgroundColor = [UIColor whiteColor];
    self.backgroundColor = [UIColor whiteColor];
}

- (void)dealloc {
    self.delegate = nil;
}

- (IBAction)inviteButtonPressed:(UIButton*)sender{
    debug NSLog(@"invite button pressed-show invite vc");
    if (delegate && [delegate respondsToSelector:@selector(inviteButtonPressed)]) {
        [delegate inviteButtonPressed];
    }
}
- (IBAction)findButtonPressed:(UIButton*)sender {
    debug NSLog(@"find button pressed-show find vc");
    if(delegate && [delegate respondsToSelector:@selector(findButtonPressed)]) {
        [delegate findButtonPressed];
    }
}

@end
