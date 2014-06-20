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
static NSInteger const kMinLabelHeight = 25;
static NSInteger const kMaxLabelWidth = 306;
static NSInteger const kCTALabelHeight = 20;
static NSInteger const kLabelTopMargin = 5;

@interface TDNoticeViewCell ()
@property (weak, nonatomic) IBOutlet UIView *topLine;

@end

@implementation TDNoticeViewCell

- (void)awakeFromNib {
    self.messageLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    self.messageLabel.font = [TDConstants fontRegularSized:15];
    self.ctaLabel.font = [TDConstants fontSemiBoldSized:15];

    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.topLine.frame = topLineRect;
}

- (void)setNotice:(TDNotice *)notice {
    if (!notice) {
        return;
    }
    if (notice.darkTextColor) {
        self.messageLabel.textColor = [TDConstants darkTextColor];
    } else {
        self.messageLabel.textColor = [UIColor whiteColor];
    }
    self.contentView.backgroundColor = [notice color];
    self.messageLabel.text = notice.message;

    CGSize size = [self.messageLabel sizeThatFits:CGSizeMake(kMaxLabelWidth, kMinViewHeight)];
    CGPoint origin = self.messageLabel.frame.origin;
    CGFloat height = size.height > kMinLabelHeight ? size.height : kMinLabelHeight;
    if (!notice.cta) {
        // This will center the text vertically
        height += kCTALabelHeight - (kLabelTopMargin /2);
    }
    self.messageLabel.frame = CGRectMake(origin.x, origin.y + kLabelTopMargin, kMaxLabelWidth, height);

    if (notice.cta) {
        if (notice.darkCTAColor) {
            self.ctaLabel.textColor = [TDConstants darkTextColor];
        } else {
            self.ctaLabel.textColor = [UIColor whiteColor];
        }
        self.ctaLabel.text = notice.cta;
        CGSize ctaSize = [self.ctaLabel sizeThatFits:CGSizeMake(kMaxLabelWidth, 20)];
        self.ctaLabel.frame = CGRectMake(origin.x, origin.y + height + kLabelTopMargin, kMaxLabelWidth, ctaSize.height);
    }
}

+ (NSInteger)heightForNotice:(TDNotice *)notice {
    if (!notice) {
        return 0;
    }

    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(7, kLabelTopMargin, kMaxLabelWidth, kMinViewHeight)];
    label.font = [TDConstants fontRegularSized:15];
    label.numberOfLines = 0;
    label.text = notice.message;
    CGSize size = [label sizeThatFits:CGSizeMake(kMaxLabelWidth, MAXFLOAT)];

    CGFloat height = kLabelTopMargin + kCTALabelHeight + (size.height > kMinLabelHeight ? size.height : kMinLabelHeight);
    return height < kMinViewHeight ? kMinViewHeight : height;
}

@end
