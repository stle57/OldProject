//
//  TDCampaignView.m
//  Throwdown
//
//  Created by Stephanie Le on 1/19/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDCampaignView.h"
#import "TDViewControllerHelper.h"
#import <SDWebImageManager.h>
#import <UIImage+Resizing.h>

@interface TDCampaignView ()
@property (nonatomic) UILabel *title;
@property (nonatomic) UILabel *blurbTitle;
@property (nonatomic) UIImageView *icon;
@property (nonatomic) UIButton *learnMoreButton;
@property (nonatomic) UIView *bottomLine;
@property (nonatomic) UIView *bottomMarginPadding;
@property (nonatomic) UIImageView *rightArrow;
@property (nonatomic) UIButton *button;
@end

@implementation TDCampaignView
static const int bottomMarginPaddingHeight = 15;
static const int imageWidth = 75;
static const int imageHeight = 50;
- (id)initWithFrame:(CGRect)frame campaignData:(NSDictionary*)campaignData {
    self = [super initWithFrame:(CGRect)frame];
    if (self) {
        [self setup:campaignData];
    }
    return self;
}

- (void)setup:(NSDictionary*)campaignData {
    self.backgroundColor = [UIColor whiteColor];
    [self setUserInteractionEnabled:YES];
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, [TDCampaignView heightForCampaignHeader:campaignData]);

    self.icon = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - imageWidth/2,
                                 15,
                                 imageWidth,
                                 imageHeight )];
    self.button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    [self addSubview:self.icon];

    [self downloadUserImage:[campaignData objectForKey:@"image"]];
    
    NSString *titleStr = [campaignData objectForKey:@"blurb_title"];
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    debug NSLog(@"titleSTr = %@", titleStr);
    NSAttributedString *titleAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23./19.)];
    self.title.attributedText = titleAttrStr;
    [self.title setNumberOfLines:0];
    [self.title sizeToFit];

    CGRect label1Frame = self.title.frame;
    label1Frame.origin.x =  self.frame.size.width/2 - self.title.frame.size.width/2;
    label1Frame.origin.y = self.icon.frame.origin.y + self.icon.frame.size.height + 10;
    self.title.frame = label1Frame;
    [self addSubview:self.title];

    self.blurbTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];

    NSString *detailStr = [campaignData objectForKey:@"blurb"];
    NSMutableAttributedString *detailAttrStr = [[NSMutableAttributedString alloc] initWithString:detailStr];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:18/15.];
    [paragraphStyle setMinimumLineHeight:18];
    [paragraphStyle setMaximumLineHeight:18];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [detailAttrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:15] range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, detailStr.length)];
    self.blurbTitle.attributedText = detailAttrStr;
    [self.blurbTitle setNumberOfLines:0];
    [self.blurbTitle sizeToFit];
    [self addSubview:self.blurbTitle];

    CGRect label2Frame = self.blurbTitle.frame;
    label2Frame.size.width = SCREEN_WIDTH - 60;
    label2Frame.origin.x = 30;
    label2Frame.origin.y = self.blurbTitle.frame.origin.y + self.blurbTitle.frame.size.height + 15;
    self.blurbTitle.frame = label2Frame;

    self.learnMoreButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];

    if ([campaignData objectForKey:@"more_cta"]) {
        NSAttributedString *learnAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:[campaignData objectForKey:@"more_cta"] font:[TDConstants fontSemiBoldSized:17] color:[TDConstants brandingRedColor] lineHeight:17 lineHeightMultipler:17];
        [self.learnMoreButton setAttributedTitle:learnAttrStr forState:UIControlStateNormal];
        [self.learnMoreButton addTarget:self action:@selector(learnMoreButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.learnMoreButton sizeToFit];

        CGRect learnFrame = self.learnMoreButton.frame;
        learnFrame.origin.x = SCREEN_WIDTH/2 - self.learnMoreButton.frame.size.width/2;
        learnFrame.origin.y = self.blurbTitle.frame.origin.y + self.blurbTitle.frame.size.height + 15;
        self.learnMoreButton.frame = learnFrame;
        [self addSubview:self.learnMoreButton];
    }

    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.learnMoreButton.frame.origin.y + self.learnMoreButton.frame.size.height + 15, SCREEN_WIDTH, .5)];
    [self addSubview:self.bottomLine];
    self.bottomLine.backgroundColor = [TDConstants commentTimeTextColor];

    self.bottomMarginPadding = [[UIView alloc] initWithFrame: CGRectMake(0, self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight)];
    self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomMarginPadding];

    if ([campaignData objectForKey:@"show_challengers"]) {
        [self createChallengersRow];

        UIView *bottomMargin = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, bottomMarginPaddingHeight)];
        bottomMargin.backgroundColor = [TDConstants darkBackgroundColor];

        CGRect bottomFrame = bottomMargin.frame;
        bottomFrame.origin.y = self.button.frame.origin.y + self.button.frame.size.height + .5;
        bottomMargin.frame = bottomFrame;

        [self addSubview:bottomMargin];
    }

}

-(void)learnMoreButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadDetailView)]) {
        [self.delegate loadDetailView];
    }
}

- (void)createChallengersRow {
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.bottomMarginPadding.frame.origin.y + self.bottomMarginPadding.frame.size.height, SCREEN_WIDTH, .5)];
    topLine.backgroundColor = [TDConstants commentTimeTextColor];
    [self addSubview:topLine];

//    self.button = [[UIButton alloc] initWithFrame:CGRectMake(0, topLine.frame.origin.y + topLine.frame.size.height, SCREEN_WIDTH, 65)];
    CGRect buttonFrame = self.button.frame;
    buttonFrame.origin.y = topLine.frame.origin.y + topLine.frame.size.height;
    self.button.frame = buttonFrame;

    [self.button setUserInteractionEnabled:YES];
    NSString *text = @"See All Challengers";
    [self.button setTitle:text forState:UIControlStateNormal];
    [self.button setTitleColor:[TDConstants headerTextColor] forState:UIControlStateNormal];
    [self.button.titleLabel setFont:[TDConstants fontSemiBoldSized:16]];
    //[self.button setImage:[UIImage imageNamed:@"Strengthlete_Logo_Small"] forState:UIControlStateNormal];
    [self.button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self.button setContentEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
    [self.button setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
    [self.button addTarget:self action:@selector(challengersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.button];

    self.rightArrow = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIImage imageNamed:@"right-arrow-gray"].size.width, [UIImage imageNamed:@"right-arrow-gray"].size.height)];
    [self.rightArrow setImage:[UIImage imageNamed:@"right-arrow-gray"]];
    CGRect rightArrowFrame = self.rightArrow.frame;
    rightArrowFrame.origin.x = SCREEN_WIDTH - 10 -[UIImage imageNamed:@"right-arrow-gray"].size.width;
    rightArrowFrame.origin.y = 65/2 -[UIImage imageNamed:@"right-arrow-gray"].size.height/2;
    self.rightArrow.frame = rightArrowFrame;

   [self.button addSubview:self.rightArrow];
    UIView *bottomLine =[[UIView alloc] initWithFrame:CGRectMake(0, self.button.frame.origin.y + self.button.frame.size.height, SCREEN_WIDTH, .5)];
    bottomLine.backgroundColor = [TDConstants commentTimeTextColor];
    [self addSubview:bottomLine];
}

+ (NSInteger)heightForCampaignHeader:(NSDictionary*)campaignData {

    NSString *titleStr = [campaignData objectForKey:@"blurb_title"];
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSAttributedString *titleAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23./19.)];
    label1.attributedText = titleAttrStr;
    [label1 setNumberOfLines:0];
    [label1 sizeToFit];

    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSString *detailStr =[campaignData objectForKey:@"blurb"];
    NSMutableAttributedString *detailAttrStr = [[NSMutableAttributedString alloc] initWithString:detailStr];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:18/15.];
    [paragraphStyle setMinimumLineHeight:18];
    [paragraphStyle setMaximumLineHeight:18];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [detailAttrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:15] range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, detailStr.length)];
    label2.attributedText = detailAttrStr;
    [label2 setNumberOfLines:0];
    [label2 sizeToFit];

    UIButton *learnButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    if ([campaignData objectForKey:@"more_cta"]) {
        NSAttributedString *learnAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:@"Learn More" font:[TDConstants fontSemiBoldSized:17] color:[TDConstants brandingRedColor] lineHeight:17 lineHeightMultipler:17];
        [learnButton setAttributedTitle:learnAttrStr forState:UIControlStateNormal];
        [learnButton sizeToFit];
    }
    debug NSLog(@"height = %f", 15 + [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height + 10 + label1.frame.size.height + 15 + label2.frame.size.height + 15 + learnButton.frame.size.height + 15 + bottomMarginPaddingHeight);

    return 15 + [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height + 10 + label1.frame.size.height + 15 + label2.frame.size.height + 15 + learnButton.frame.size.height + 15 + bottomMarginPaddingHeight + 65 + bottomMarginPaddingHeight;
}

- (void)challengersButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadChallengersView)]) {
        [self.delegate loadChallengersView];
    }
}

- (void)downloadUserImage:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress bar here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        //CGFloat width = self.icon.frame.size.width * [UIScreen mainScreen].scale;
        image = [image scaleToSize:CGSizeMake(imageWidth, imageHeight)];
        if (![finalURL isEqual:url]) {
            return;
        }
        if (!error && image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.icon) {
                    self.icon.image = image;
                }
                if (self.button) {
                    [self.button setImage:image forState:UIControlStateNormal];
                }
            });
        }
    }];
}
@end
