//
//  TDMoreComments.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDMoreComments.h"
#import "TDConstants.h"

@implementation TDMoreComments

- (void)awakeFromNib {
    self.moreLabel.font = [TDConstants fontBoldSized:14];
}

- (void)moreCount:(NSInteger)count {
    self.moreLabel.text = [NSString stringWithFormat:@"%lu more", (long)(count-2)];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
}

@end
