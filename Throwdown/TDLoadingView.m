//
//  TDLoadingView.m
//  Throwdown
//
//  Created by Stephanie Le on 12/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDLoadingView.h"
#import "TDTextViewControllerHelper.h"
#import "TDViewControllerHelper.h"
#import "TDRefreshImageView.h"

@interface TDLoadingView ()
//@property (nonatomic) TDRefreshImageView *loadingAnimation;
@property (nonatomic) UILabel *personalizeLabel;
@property (nonatomic) UILabel *loadingLabel;
@property (nonatomic) UILabel *infoLabel;
@property (nonatomic) UILabel *infoLabel2;
@property (nonatomic) UILabel *infoLabel3;
@property (nonatomic) CGRect loadingAnimationFrame;
@property (nonatomic) UIView *subViewType3;
@end
@implementation TDLoadingView : UIView
//@synthesize loadingAnimation;
@synthesize personalizeLabel;
@synthesize loadingLabel;
@synthesize infoLabel;
@synthesize infoLabel2;
@synthesize infoLabel3;

static NSString *personalizeText = @"Please wait while we\npersonalize Throwdown";
static NSString *infoText = @"Thanks for telling us about your\nfitness goals and interests!";
static NSString *loadingText = @"Loading...";

+ (id)loadingView:(kLoadingViewType)type {
    TDLoadingView *loadingView = [[TDLoadingView alloc] init];
    if ([loadingView isKindOfClass:[TDLoadingView class]]) {
        [loadingView setup:type];
        return loadingView;
    } else {
        return nil;
    }
    return loadingView;
}

- (void)dealloc {
    //self.loadingAnimation = nil;
    self.personalizeLabel = nil;
    self.loadingLabel = nil;
    self.infoLabel = nil;
    self.infoLabel2 = nil;
    self.infoLabel3 = nil;
    self.subViewType3 = nil;
}
- (void)setup:(kLoadingViewType)type {
    self.kLoadingViewType = type;
    self.frame = CGRectMake(0, 0, 270, 318);
    if (self.kLoadingViewType != kView3_Loading) {
        TDRefreshImageView  *loadingAnimation = [[TDRefreshImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/2 - [UIImage imageNamed:@"ptr-0000"].size.width/2, 0, [UIImage imageNamed:@"ptr-0000"].size.width, [UIImage imageNamed:@"ptr-0000"].size.height)];
        loadingAnimation.animationDuration = 2;
        loadingAnimation.userInteractionEnabled = YES;
        self.loadingAnimationFrame = loadingAnimation.frame;
        [self addSubview:loadingAnimation];

        [loadingAnimation startAnimating];
    }
    self.personalizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, 100)];
    [self.personalizeLabel setNumberOfLines:0];
    [self addSubview:self.personalizeLabel];
    
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100)];
    [self.infoLabel setNumberOfLines:0];
    [self addSubview:self.infoLabel];
    
    
    self.infoLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100)];
    [self.infoLabel2 setNumberOfLines:0];
    [self addSubview:self.infoLabel2];
    self.infoLabel2.hidden = YES;
    
    self.infoLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 100)];
    [self.infoLabel3 setNumberOfLines:0];
    [self addSubview:self.infoLabel3];
    self.infoLabel3.hidden = YES;
    
    self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, 100)];
    [self.loadingLabel setNumberOfLines:0];
    [self addSubview:self.loadingLabel];
}

- (void)setViewType:(kLoadingViewType)type {
    self.kLoadingViewType = type;
    
    switch (type) {
        case kView1_Loading:
            [self setupView1Labels];
            break;
            
        case kView2_Loading:
            [self setupView2Labels];
            break;
        case kView3_Loading:
            [self setupView3Labels];
            break;
            
            default:
            break;
    }
}

- (void)setupView1Labels {
    NSAttributedString *attStr = [TDViewControllerHelper makeParagraphedTextWithString:personalizeText font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:18/15];
    self.personalizeLabel.attributedText = attStr;
    [self.personalizeLabel sizeToFit];
    
    CGRect frame = self.personalizeLabel.frame;
    frame.origin.x = self.frame.size.width/2 - self.personalizeLabel.frame.size.width/2;
    frame.origin.y = self.loadingAnimationFrame.origin.y + self.loadingAnimationFrame.size.height + 10;
    self.personalizeLabel.frame = frame;
    NSAttributedString *loadingStr = [TDViewControllerHelper makeParagraphedTextWithString:loadingText font:[TDConstants fontSemiBoldSized:22] color:[TDConstants brandingRedColor] lineHeight:22 lineHeightMultipler:22/22];
    self.loadingLabel.attributedText = loadingStr;
    [self.loadingLabel sizeToFit];
    
    CGRect loadingFrame = self.loadingLabel.frame;
    loadingFrame.origin.x = self.frame.size.width/2 - self.loadingLabel.frame.size.width/2;
    loadingFrame.origin.y = self.personalizeLabel.frame.origin.y + self.personalizeLabel.frame.size.height + 35;
    self.loadingLabel.frame = loadingFrame;

    NSAttributedString *infoStr = [TDViewControllerHelper makeParagraphedTextWithString:infoText font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:19 lineHeightMultipler:19/15];
    self.infoLabel.attributedText = infoStr;
    [self.infoLabel sizeToFit];
    
    CGRect infoFrame = self.infoLabel.frame;
    infoFrame.origin.x = self.frame.size.width/2 - self.infoLabel.frame.size.width/2;
    infoFrame.origin.y = self.loadingLabel.frame.origin.y + self.loadingLabel.frame.size.height + 4;
    self.infoLabel.frame = infoFrame;
    
}

- (void)setupView2Labels {
    NSAttributedString *attString = [TDViewControllerHelper makeParagraphedTextWithString:personalizeText font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:18/15];
    self.personalizeLabel.attributedText = attString;
    [self.personalizeLabel sizeToFit];
    
    CGRect frame = self.personalizeLabel.frame;
    frame.origin.x = self.frame.size.width/2 - self.personalizeLabel.frame.size.width/2;
    frame.origin.y = self.loadingAnimationFrame.origin.y + self.loadingAnimationFrame.size.height + 10;
    self.personalizeLabel.frame = frame;
    
    NSAttributedString *attStr = [TDViewControllerHelper makeParagraphedTextWithString:TDCommunityValuesStr font:[TDConstants fontSemiBoldSized:22.] color:[TDConstants brandingRedColor] lineHeight:22. lineHeightMultipler:22/22];
    self.loadingLabel.attributedText = attStr;
    [self.loadingLabel setNumberOfLines:0];
    [self.loadingLabel sizeToFit];
    
    CGRect loadingFrame = self.loadingLabel.frame;
    loadingFrame.origin.x = self.frame.size.width/2 - self.loadingLabel.frame.size.width/2;
    loadingFrame.origin.y = self.personalizeLabel.frame.origin.y + self.personalizeLabel.frame.size.height + 35;
    self.loadingLabel.frame = loadingFrame;
    
    NSString *infoText= TDValueStr1;
    NSAttributedString *infoStr = [TDViewControllerHelper makeParagraphedTextWithString:infoText font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:19];
    self.infoLabel.attributedText = infoStr;
    [self.infoLabel setNumberOfLines:0];
    [self.infoLabel sizeToFit];
    
    NSString *infoText2 = TDValueStr2;
    NSAttributedString *infoStr2 = [TDViewControllerHelper makeParagraphedTextWithString:infoText2 font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:19];
    self.infoLabel2.attributedText = infoStr2;
    [self.infoLabel2 setNumberOfLines:0];
    [self.infoLabel2 sizeToFit];
    
    NSString *infoText3 = TDValueStr3;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:infoText3];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:19];
    [paragraphStyle setMinimumLineHeight:19];
    [paragraphStyle setMaximumLineHeight:19];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, infoText3.length)];
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:15] range:NSMakeRange(0, infoText3.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, infoText3.length)];

    UIFont *boldFont = [TDConstants fontSemiBoldSized:15];
    UIColor *foregroundColor = [TDConstants headerTextColor];
    // Create the attributes
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           boldFont, NSFontAttributeName,
                           foregroundColor, NSForegroundColorAttributeName, nil];
    const NSRange range = NSMakeRange(0,16); // range of " 2012/10/14 ". Ideally this should not be hardcoded
    
    [attributedString setAttributes:attrs range:range];
    self.infoLabel3.attributedText = attributedString;
    
    [self.infoLabel3 setNumberOfLines:0];
    [self.infoLabel3 sizeToFit];
    
    CGRect infoFrame = self.infoLabel.frame;
    infoFrame.origin.x = 5;
    infoFrame.origin.y = self.loadingLabel.frame.origin.y + self.loadingLabel.frame.size.height + 12;
    self.infoLabel.frame = infoFrame;
    
    CGRect infoFrame2 = self.infoLabel2.frame;
    infoFrame2.origin.x = 5;
    infoFrame2.origin.y = self.infoLabel.frame.origin.y + self.infoLabel.frame.size.height +5;
    self.infoLabel2.frame = infoFrame2;
    
    CGRect infoFrame3 = self.infoLabel3.frame;
    infoFrame3.origin.x = 5;
    infoFrame3.origin.y = self.infoLabel2.frame.origin.y + self.infoLabel2.frame.size.height+5;
    self.infoLabel3.frame = infoFrame3;

    
    self.infoLabel3.hidden = NO;
    self.infoLabel2.hidden = NO;
    
}

- (void)setupView3Labels {
    self.personalizeLabel.hidden = YES;
    self.subViewType3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 150)];
    
    NSAttributedString *attStr = [TDViewControllerHelper makeParagraphedTextWithString:@"All Set!" font:[TDConstants fontSemiBoldSized:22.] color:[TDConstants brandingRedColor] lineHeight:22. lineHeightMultipler:22/22];
    self.loadingLabel.attributedText = attStr;
    [self.loadingLabel sizeToFit];
 
    [self.subViewType3 addSubview:self.loadingLabel];
    
    NSString *infoText= @"We hope you enjoy.\n\n- The Throwdown Team";
    NSAttributedString *infoStr = [TDViewControllerHelper makeParagraphedTextWithString:infoText font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:19 lineHeightMultipler:19/15];
    self.infoLabel.attributedText = infoStr;
    [self.infoLabel sizeToFit];
    [self.infoLabel setNumberOfLines:0];
    
    [self.subViewType3 addSubview:self.infoLabel];
    
    [self.subViewType3 sizeToFit];
    
    CGRect subViewFrame = self.subViewType3.frame;
    subViewFrame.origin.x = self.frame.size.width/2 - self.subViewType3.frame.size.width/2;
    subViewFrame.origin.y = self.frame.size.height/2 - self.subViewType3.frame.size.height/2;
    self.subViewType3.frame = subViewFrame;
    
    [self addSubview:self.subViewType3];
    
    CGRect loadingFrame = self.loadingLabel.frame;
    loadingFrame.origin.x = self.subViewType3.frame.size.width/2 - self.loadingLabel.frame.size.width/2;
    loadingFrame.origin.y = 0;
    self.loadingLabel.frame = loadingFrame;
    
    CGRect infoFrame = self.infoLabel.frame;
    infoFrame.origin.x = self.subViewType3.frame.size.width/2 - self.infoLabel.frame.size.width/2;
    infoFrame.origin.y = self.loadingLabel.frame.origin.y + self.loadingLabel.frame.size.height + 10;
    self.infoLabel.frame = infoFrame;

}
@end
