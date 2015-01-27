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

@interface TDCampaignView () <TTTAttributedLabelDelegate>
@property (nonatomic) UILabel *title;
@property (nonatomic) TTTAttributedLabel *blurbTitle;
@property (nonatomic) UIImageView *icon;
@property (nonatomic) UIButton *learnMoreButton;
@property (nonatomic) UIView *bottomLine;
@property (nonatomic) UIView *bottomMarginPadding;
@property (nonatomic) UIImageView *rightArrow;
@property (nonatomic) UIButton *button;
@property (nonatomic) UIButton *iconButton; // Created another button which holds the image only, but the imageView inside self.button would not scale.  Workaround
@end

@implementation TDCampaignView
static const int bottomMarginPaddingHeight = 15;
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

    self.icon = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - kBigImageWidth/2,
                                 15,
                                 kBigImageWidth,
                                 kBigImageHeight )];
    self.icon.contentMode = UIViewContentModeScaleAspectFit;

    self.button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];

    self.iconButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 65/2 - kSmallImageHeight/2, kSmallImageWidth, kSmallImageHeight)];
    self.iconButton.imageView.contentMode = UIViewContentModeScaleAspectFit;

    [self addSubview:self.icon];

    [self downloadPreview:[campaignData objectForKey:@"image"]];
    
    NSString *titleStr = [campaignData objectForKey:@"blurb_title"];
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSAttributedString *titleAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23./19.)];
    self.title.attributedText = titleAttrStr;
    [self.title setNumberOfLines:0];
    [self.title sizeToFit];

    CGRect label1Frame = self.title.frame;
    label1Frame.origin.x =  self.frame.size.width/2 - self.title.frame.size.width/2;
    label1Frame.origin.y = self.icon.frame.origin.y + self.icon.frame.size.height + 15;
    self.title.frame = label1Frame;
    [self addSubview:self.title];

    self.blurbTitle = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    self.blurbTitle.delegate = self;
    self.blurbTitle.linkAttributes = nil;
    self.blurbTitle.activeLinkAttributes = nil;
    self.blurbTitle.inactiveLinkAttributes = nil;
    self.blurbTitle.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.blurbTitle.font = [TDConstants fontRegularSized:15];
    self.blurbTitle.textColor = [TDConstants headerTextColor];
    [self.blurbTitle setNumberOfLines:0];

    NSString *detailStr = [campaignData objectForKey:@"blurb"];
    [self.blurbTitle setText:detailStr];

    NSMutableAttributedString *detailAttrStr = [self.blurbTitle.attributedText mutableCopy];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:18/15.];
    [paragraphStyle setMinimumLineHeight:18];
    [paragraphStyle setMaximumLineHeight:18];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [detailAttrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, detailStr.length)];
    detailAttrStr = [TDViewControllerHelper boldHashtagsInText:detailAttrStr fontSize:15];
    self.blurbTitle.attributedText = detailAttrStr;
    [TDViewControllerHelper colorLinksInLabel:self.blurbTitle];

    CGSize size = [self.blurbTitle sizeThatFits:CGSizeMake(SCREEN_WIDTH - 60, MAXFLOAT)];
    [self addSubview:self.blurbTitle];

    CGRect label2Frame = self.blurbTitle.frame;
    label2Frame.size.height = size.height;
    label2Frame.size.width = SCREEN_WIDTH - 60;
    label2Frame.origin.x = 30;
    label2Frame.origin.y = self.title.frame.origin.y + self.title.frame.size.height + 15;
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

- (void)createChallengersRow {
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.bottomMarginPadding.frame.origin.y + self.bottomMarginPadding.frame.size.height, SCREEN_WIDTH, .5)];
    topLine.backgroundColor = [TDConstants commentTimeTextColor];
    [self addSubview:topLine];

    CGRect buttonFrame = self.button.frame;
    buttonFrame.origin.y = topLine.frame.origin.y + topLine.frame.size.height;
    self.button.frame = buttonFrame;

    [self.button setUserInteractionEnabled:YES];
    NSString *text = @"See All Participants";
    [self.button setTitle:text forState:UIControlStateNormal];
    [self.button setTitleColor:[TDConstants headerTextColor] forState:UIControlStateNormal];
    [self.button.titleLabel setFont:[TDConstants fontSemiBoldSized:16]];
    self.button.titleEdgeInsets = UIEdgeInsetsMake(0, self.iconButton.frame.size.width + 20, 0, 0);
    self.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;


    [self.button addTarget:self action:@selector(challengersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.iconButton addTarget:self action:@selector(challengersButtonPressed) forControlEvents:UIControlEventTouchUpInside ];

    [self addSubview:self.button];
    [self.button addSubview:self.iconButton];

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

    TTTAttributedLabel *label2 = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    label2.linkAttributes = nil;
    label2.activeLinkAttributes = nil;
    label2.inactiveLinkAttributes = nil;
    label2.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    label2.font = [TDConstants fontRegularSized:15];
    label2.textColor = [TDConstants headerTextColor];
    [label2 setNumberOfLines:0];

    NSString *detailStr = [campaignData objectForKey:@"blurb"];
    [label2 setText:detailStr];

    NSMutableAttributedString *detailAttrStr = [label2.attributedText mutableCopy];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:18/15.];
    [paragraphStyle setMinimumLineHeight:18];
    [paragraphStyle setMaximumLineHeight:18];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [detailAttrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, detailStr.length)];
    detailAttrStr = [TDViewControllerHelper boldHashtagsInText:detailAttrStr fontSize:15];
    label2.attributedText = detailAttrStr;
    [TDViewControllerHelper colorLinksInLabel:label2];

    CGSize label2size = [label2 sizeThatFits:CGSizeMake(SCREEN_WIDTH - 60, MAXFLOAT)];

    UIButton *learnButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    if ([campaignData objectForKey:@"more_cta"]) {
        NSAttributedString *learnAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:@"Learn More" font:[TDConstants fontSemiBoldSized:17] color:[TDConstants brandingRedColor] lineHeight:17 lineHeightMultipler:17];
        [learnButton setAttributedTitle:learnAttrStr forState:UIControlStateNormal];
        [learnButton sizeToFit];
    }
    return 15 + kBigImageHeight + 15 + label1.frame.size.height + 15 + label2size.height + 15 + learnButton.frame.size.height + 15 + .5 +bottomMarginPaddingHeight + .5 + 65 + bottomMarginPaddingHeight + .5;
}

- (void)challengersButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadChallengersView)]) {
        [self.delegate loadChallengersView];
    }
}

-(void)learnMoreButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadDetailView)]) {
        [self.delegate loadDetailView];
    }
}

- (void)downloadPreview:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress bar here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        if (![finalURL isEqual:url]) {
            return;
        }
        if (!error && image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.icon) {
                    self.icon.image = image;
                }
                if (self.iconButton) {
                     [self.iconButton setImage:image forState:UIControlStateNormal];
                    [self.iconButton setImage:image forState:UIControlStateHighlighted];
                }
            });
        }
    }];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if (![TDViewControllerHelper isThrowdownURL:url]) {
        [TDViewControllerHelper askUserToOpenInSafari:url];
    }
}
@end
