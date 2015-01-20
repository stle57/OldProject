//
//  TDCampaignView.m
//  Throwdown
//
//  Created by Stephanie Le on 1/19/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDCampaignView.h"
#import "TDViewControllerHelper.h"
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
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithFrame:(CGRect)frame campaignData:(NSDictionary*)campaignData {
    self = [super initWithFrame:(CGRect)frame];
    if (self) {
        [self setup:campaignData];
    }
    return self;
}

- (void)setup:(NSDictionary*)campaignData {
    self.backgroundColor = [UIColor whiteColor];
    self.layer.borderColor = [[UIColor magentaColor] CGColor];
    self.layer.borderWidth = 2.;
    [self setUserInteractionEnabled:YES];
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, [TDCampaignView heightForCampaignHeader:campaignData]);

    self.icon = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2 - [UIImage   imageNamed:@"Strengthlete_Logo_BIG"].size.width/2,
                                 15,
                                 [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.width,
                                 [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height )];
    self.icon.image = [UIImage imageNamed:@"Strengthlete_Logo_BIG"];
    [self addSubview:self.icon];
    self.icon.layer.borderWidth = 2.;
    self.icon.layer.borderColor = [[UIColor blackColor] CGColor];
    
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

//    NSString *detailStr = @"Strengthlete challenges you to eat clean and exercise for all of February!\n\nPrizes to those who fully participate during this month, and for biggest accomplishments!\n\nSee posts from fellow Challenger";
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

        self.learnMoreButton.layer.borderWidth = 2.;
        self.learnMoreButton.layer.borderColor =[[UIColor magentaColor] CGColor];
    }

    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.learnMoreButton.frame.origin.y + self.learnMoreButton.frame.size.height + 15, SCREEN_WIDTH, .5)];
    [self addSubview:self.bottomLine];
    self.bottomLine.backgroundColor = [UIColor redColor];

    self.bottomMarginPadding = [[UIView alloc] initWithFrame: CGRectMake(0, self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight)];
    self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomMarginPadding];
    self.bottomMarginPadding.layer.borderWidth = 1.;
    self.bottomMarginPadding.layer.borderColor = [[UIColor blueColor] CGColor];

    if ([campaignData objectForKey:@"show_challengers"]) {
        [self createChallengersRow];
//            self.button = [[UIButton alloc] initWithFrame:CGRectMake(0, self.bottomMarginPadding.frame.origin.y + self.bottomMarginPadding.frame.size.height, SCREEN_WIDTH, 65)];
//            [self.button setUserInteractionEnabled:YES];
//            NSString *text = @"See All Challengers";
//            [self.button setTitle:text forState:UIControlStateNormal];
//            [self.button setTitleColor:[TDConstants headerTextColor] forState:UIControlStateNormal];
//            [self.button.titleLabel setFont:[TDConstants fontSemiBoldSized:16]];
//            [self.button setImage:[UIImage imageNamed:@"Strengthlete_Logo_Small"] forState:UIControlStateNormal];
//            [self.button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
//            [self.button setContentEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
//            [self.button setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
//            [self.button addTarget:self action:@selector(challengersButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//            [self addSubview:self.button];
//
//            self.rightArrow = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIImage imageNamed:@"right-arrow-gray"].size.width, [UIImage imageNamed:@"right-arrow-gray"].size.height)];
//            [self.rightArrow setImage:[UIImage imageNamed:@"right-arrow-gray"]];
//            CGRect rightArrowFrame = self.rightArrow.frame;
//            rightArrowFrame.origin.x = SCREEN_WIDTH - 10 -[UIImage imageNamed:@"right-arrow-gray"].size.width;
//            rightArrowFrame.origin.y = 65/2 -[UIImage imageNamed:@"right-arrow-gray"].size.height/2;
//            self.rightArrow.frame = rightArrowFrame;
//            
//            [self.button addSubview:self.rightArrow];

        UIView *bottomMargin = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, bottomMarginPaddingHeight)];
        bottomMargin.backgroundColor = [TDConstants darkBackgroundColor];

        CGRect bottomFrame = bottomMargin.frame;
        bottomFrame.origin.y = self.button.frame.origin.y + self.button.frame.size.height;
        bottomMargin.frame = bottomFrame;

        [self addSubview:bottomMargin];
    }

}

-(void)learnMoreButtonPressed {
debug NSLog(@"learnButtonPressed");
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadDetailView)]) {
        [self.delegate loadDetailView];
    }
}

- (void)createChallengersRow {
    self.button = [[UIButton alloc] initWithFrame:CGRectMake(0, self.bottomMarginPadding.frame.origin.y + self.bottomMarginPadding.frame.size.height, SCREEN_WIDTH, 65)];
    [self.button setUserInteractionEnabled:YES];
    NSString *text = @"See All Challengers";
    [self.button setTitle:text forState:UIControlStateNormal];
    [self.button setTitleColor:[TDConstants headerTextColor] forState:UIControlStateNormal];
    [self.button.titleLabel setFont:[TDConstants fontSemiBoldSized:16]];
    [self.button setImage:[UIImage imageNamed:@"Strengthlete_Logo_Small"] forState:UIControlStateNormal];
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
    debug NSLog(@"challengersButtonPressed");
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadChallengersView)]) {
        [self.delegate loadChallengersView];
    }
}
@end
