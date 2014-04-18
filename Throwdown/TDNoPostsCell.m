//
//  TDNoPostsCell.m
//  Throwdown
//
//  Created by Andrew B on 4/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDNoPostsCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "NSDate+TimeAgo.h"

@interface TDNoPostsCell ()

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@end

@implementation TDNoPostsCell

- (void)awakeFromNib {
    self.messageLabel.font = [TDConstants fontRegularSized:18.0];
}

- (void)dealloc {

}

@end
