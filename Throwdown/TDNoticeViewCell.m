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
static NSInteger const kBottomMarginPadding = 15;

@interface TDNoticeViewCell ()
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIImageView *rightArrow;
@property (nonatomic) UIView *bottomMarginPadding;
@property (nonatomic) UIView *bottomLine;
@end

@implementation TDNoticeViewCell
@synthesize imageView;

- (void)awakeFromNib {
    self.messageLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    self.messageLabel.font = [TDConstants fontRegularSized:15];
    self.ctaLabel.font = [TDConstants fontSemiBoldSized:15];

    CGRect topLineRect = self.topLine.frame;
    topLineRect.size.height = 1 / [[UIScreen mainScreen] scale];
    self.topLine.frame = topLineRect;

    imageView = [[UIImageView alloc] init];
    self.bottomMarginPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, kBottomMarginPadding)];

    self.rightArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"right-arrow-gray"]];
    self.rightArrow.frame = CGRectMake(0, 0, [UIImage imageNamed:@"right-arrow-gray"].size.width, [UIImage imageNamed:@"right-arrow-gray"].size.height) ;
    debug NSLog(@"self.rightArrow frame = %@", NSStringFromCGRect(self.rightArrow.frame));
    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, .5)];
    self.bottomLine.backgroundColor = [TDConstants darkBorderColor];
}

- (void)setNotice:(TDNotice *)notice {
    if (!notice) {
        return;
    }
    if ([notice.message isEqualToString:@"Strengthlete 28-Day Challenge!"]) {
        self.ctaLabel.hidden = YES;

        self.messageLabel.textColor = [TDConstants headerTextColor];
        self.messageLabel.font = [TDConstants fontSemiBoldSized:16];
        self.messageLabel.text = notice.message;
        [self.messageLabel sizeToFit];

        CGRect messageLabelFrame = self.messageLabel.frame;
        messageLabelFrame.origin.x = 10+[UIImage imageNamed:@"Strengthlete_Logo_Small"].size.width + 10;
        messageLabelFrame.origin.y = 65/2 - self.messageLabel.frame.size.height/2;
        self.messageLabel.frame = messageLabelFrame;

        [self.imageView setImage:[UIImage imageNamed:@"Strengthlete_Logo_Small"]];
        self.imageView.frame = CGRectMake(10,
                                          65/2 - [UIImage imageNamed:@"Strengthlete_Logo_Small"].size.height/2,
                                          [UIImage imageNamed:@"Strengthlete_Logo_Small"].size.width,
                                          [UIImage imageNamed:@"Strengthlete_Logo_Small"].size.height);
        [self addSubview:self.imageView];

        [self setAccessoryType:UITableViewCellAccessoryNone];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        //self.accessoryView = self.rightArrow;

        CGRect rightArrowFrame = self.rightArrow.frame;
        rightArrowFrame.origin.x = SCREEN_WIDTH - 10 -[UIImage imageNamed:@"right-arrow-gray"].size.width;
        rightArrowFrame.origin.y = 65/2 -[UIImage imageNamed:@"right-arrow-gray"].size.height/2;
        self.rightArrow.frame = rightArrowFrame;
        [self addSubview:self.rightArrow];

        [self addSubview:self.bottomLine];
        debug NSLog(@"frame of bottomLine = %@", NSStringFromCGRect(self.bottomLine.frame));
        self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
        CGRect bottomMarginFrame = self.bottomMarginPadding.frame;
        bottomMarginFrame.origin.x = 0;
        bottomMarginFrame.origin.y = self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height;
        self.bottomMarginPadding.frame = bottomMarginFrame;

        [self addSubview:self.bottomMarginPadding];

    } else {
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
}

+ (NSInteger)heightForNotice:(TDNotice *)notice {
    if (!notice) {
        return 0;
    }

    if ([notice.message isEqualToString:@"Strengthlete 28-Day Challenge!"]) {
        return 65+kBottomMarginPadding;
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
