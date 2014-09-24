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
    self.noFollowLabel.font = [TDConstants fontSemiBoldSized:16];
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
