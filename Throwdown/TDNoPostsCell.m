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

@end

@implementation TDNoPostsCell

- (void)awakeFromNib {
    self.noPostsLabel.font = [TDConstants fontSemiBoldSized:17.0];
    self.noPostsLabel.textColor = [TDConstants helpTextColor];
}

- (void)dealloc {

}

@end
