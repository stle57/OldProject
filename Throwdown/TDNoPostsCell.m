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
@property (nonatomic) UIImageView *imageView;
@end

@implementation TDNoPostsCell
@synthesize imageView;

- (void)awakeFromNib {
    self.noPostsLabel.font = [TDConstants fontSemiBoldSized:17.0];
    self.noPostsLabel.textColor = [TDConstants helpTextColor];
}

- (void)dealloc {
    self.imageView = nil;
}

- (void)createInfoCell:(NSString*)iconURL tagName:(NSString*)tagName{
    self.backgroundColor = [UIColor whiteColor];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - kBigImageWidth/2, 15, kBigImageWidth, kBigImageHeight)];
    [self addSubview:self.imageView];
    [self downloadPreview:iconURL];

    NSString *title = @"Be the first Challenger!";
    NSAttributedString *titleAttr = [TDViewControllerHelper makeParagraphedTextWithString:title font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23/19)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    label.attributedText = titleAttr;
    [label setNumberOfLines:0];
    [label sizeToFit];
    CGRect labelFrame = label.frame;
    labelFrame.origin.x = SCREEN_WIDTH/2 - label.frame.size.width/2;
    labelFrame.origin.y = self.imageView.frame.origin.y + kBigImageHeight + 15;
    label.frame = labelFrame;
    [self addSubview:label];

    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(30, label.frame.origin.y + label.frame.size.height + 15, SCREEN_WIDTH - 60, 200)];
    [label2 setNumberOfLines:0];
    label2.font = [TDConstants fontRegularSized:15];
    label2.textColor = [TDConstants headerTextColor];
    NSString *descriptionTxt = [NSString stringWithFormat:@"%@%@%@", @"Be the first challenger to kick things off!\nSimply tag #", tagName, @" in your post to automatically enter." ];

    NSMutableAttributedString *detailAttrStr = [[NSMutableAttributedString alloc] initWithString:descriptionTxt];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:18/15.];
    [paragraphStyle setMinimumLineHeight:18];
    [paragraphStyle setMaximumLineHeight:18];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [detailAttrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, descriptionTxt.length)];
    detailAttrStr = [TDViewControllerHelper boldHashtagsInText:detailAttrStr fontSize:15];
    label2.attributedText = detailAttrStr;
    CGSize size = [label2 sizeThatFits:CGSizeMake(SCREEN_WIDTH - 60, MAXFLOAT)];
    CGRect frame = label2.frame;
    frame.size.height = size.height;
    label2.frame = frame;
    [self addSubview:label2];

    self.noPostsLabel.hidden = YES;
}

- (void)downloadPreview:(NSString*)stringURL {
    NSURL *downloadURL = [NSURL URLWithString:stringURL];

    downloadURL = [NSURL URLWithString:stringURL];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:downloadURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress bar here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        if (![finalURL isEqual:downloadURL]) {
            return;
        }
        if (!error && image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.imageView) {
                    self.imageView.image = image;
                }
            });
        }
    }];
}
@end
