//
//  TDNoticeViewCell.m
//  Throwdown
//
//  Created by Andrew C on 6/3/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDNoticeViewCell.h"
#import "TDConstants.h"
#import "TDAppDelegate.h"

static NSInteger const kMinViewHeight = 50;
static NSInteger const kMaxLabelWidth = 306;
static NSInteger const kCTALabelHeight = 20;
static NSInteger const kLabelTopMargin = 5;

@interface TDNoticeViewCell ()
@property (weak, nonatomic) IBOutlet UIView *topLine;

@end

@implementation TDNoticeViewCell

- (void)awakeFromNib {
    self.messageLabel.font = [TDConstants fontRegularSized:15];
    self.ctaLabel.font = [TDConstants fontSemiBoldSized:15];

    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.topLine.frame = topLineRect;
}

- (void)setNotice:(TDNotice *)notice {
    self.contentView.backgroundColor = [notice color];
    self.messageLabel.text = notice.message;
    self.ctaLabel.text = notice.cta;

    CGSize size = [self.messageLabel sizeThatFits:CGSizeMake(kMaxLabelWidth, kMinViewHeight)];
    CGPoint origin = self.messageLabel.frame.origin;
    CGSize ctaSize = [self.ctaLabel sizeThatFits:CGSizeMake(kMaxLabelWidth, 20)];

    self.messageLabel.frame = CGRectMake(origin.x, origin.y + kLabelTopMargin, kMaxLabelWidth, size.height);
    self.ctaLabel.frame = CGRectMake(origin.x, origin.y + size.height + kLabelTopMargin, kMaxLabelWidth, ctaSize.height);
}

+ (NSInteger)heightForNotice:(TDNotice *)notice {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(7, kLabelTopMargin, kMaxLabelWidth, kMinViewHeight)];
    label.font = [TDConstants fontRegularSized:15];
    label.numberOfLines = 2;
    label.text = notice.message;
    CGSize size = [label sizeThatFits:CGSizeMake(kMaxLabelWidth, kMinViewHeight)];
    NSInteger height = size.height + kCTALabelHeight + kLabelTopMargin;
    return height < kMinViewHeight ? kMinViewHeight : height;
}

@end
