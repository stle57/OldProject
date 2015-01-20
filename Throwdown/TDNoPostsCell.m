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
#import <SDWebImageManager.h>
#import <UIImage+Resizing.h>

@interface TDNoPostsCell ()

@end

@implementation TDNoPostsCell

- (void)awakeFromNib {
    self.noPostsLabel.font = [TDConstants fontSemiBoldSized:17.0];
    self.noPostsLabel.textColor = [TDConstants helpTextColor];
}

- (void)dealloc {

}

- (void)createInfoCell:(NSString*)iconURL {
    self.backgroundColor = [UIColor whiteColor];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - 75/2, 15, 75, 15)];
    [self addSubview:imageView];

    NSString *title = @"Be the first Challenger!";
    NSAttributedString *titleAttr = [TDViewControllerHelper makeParagraphedTextWithString:title font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23/19)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    label.attributedText = titleAttr;
    [label setNumberOfLines:0];
    [label sizeToFit];
    CGRect labelFrame = label.frame;
    labelFrame.origin.x = SCREEN_WIDTH/2 - label.frame.size.width/2;
    labelFrame.origin.y = self.imageView.frame.origin.y + 10;
    label.frame = labelFrame;
    [self addSubview:label];

    self.noPostsLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64);
    NSString *descriptionTxt = @"Be the first challenger to kick things off!\nSimply tag #strengthlete in your post to\nautomatically enter.";

    NSAttributedString *descriptionString = [TDViewControllerHelper makeLeftAlignmentTextWithString:descriptionTxt font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:(18/15.)];

    self.noPostsLabel.attributedText = descriptionString;
    [self.noPostsLabel setNumberOfLines:0];
    [self.noPostsLabel sizeToFit];

    CGRect noPostFrame = self.noPostsLabel.frame;
    noPostFrame.size.width = SCREEN_WIDTH - 60;
    noPostFrame.origin.x = 30;
    noPostFrame.origin.y = label.frame.origin.y + label.frame.size.height + 15;
    self.noPostsLabel.frame = noPostFrame;

    debug NSLog(@"cell.frame = %@", NSStringFromCGRect(self.frame));
    debug NSLog(@"no posts lbael str = %@", NSStringFromCGRect(self.noPostsLabel.frame));
    self.layer.borderColor = [[UIColor blueColor] CGColor];
    self.layer.borderWidth = 1.;
}
@end
