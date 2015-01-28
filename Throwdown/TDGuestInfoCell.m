//
//  TDGuestInfoCellTableViewCell.m
//  Throwdown
//
//  Created by Stephanie Le on 12/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDGuestInfoCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDCurrentUser.h"

@implementation TDGuestInfoCell
static NSString *signupButtonStr = @"btn_join_throwdown";
static NSString *signupButtonHitStr = @"btn_join_throwdown_hit";
static NSString *setGoalsStr = @"btn_set_goals_interests";
static NSString *setGoalsHitStr = @"btn_set_goals_interests_hit";

static NSString *createPostStr = @"btn_create_first_post";
static NSString *createPostHitStr = @"btn_create_first_post_hit";
static NSString *text1 = @"Share with us:\n-Your latest workouts,\n-A proud momement, or\n-A recent healthy meal";
static NSString *text2 = @"Please remember:\n-No inappropriate posts,\n-No direct advertisements at this time.";
static NSString *guestWelcomeStr = @"Based on your goals and interests, here's a sample of posts from the community we thought you'd enjoy.\n\nTo like, comment, or make your own post, please join us by creating an account.  We'd love to have you!";
static NSString *existingUser1 = @"We'd like to personalize your Throwdown experience.";
static NSString *existingUser2 = @"Please take a moment to tell us about your fitness goals and interests.";
static NSString *existingUser3 = @"(You can always change them in settings.)";
static const int topMarginPaddingHeight = 15;
static const int bottomMarginPaddingHeight = 15;

- (void)awakeFromNib {
    self.label1.hidden = YES;
    self.label2.hidden = YES;
    self.label3.hidden = YES;
    self.label4.hidden = YES;
    self.button.hidden = YES;
    self.topLine.frame = CGRectMake(0, .5, SCREEN_WIDTH, .5);
    self.topLine.backgroundColor = [TDConstants darkBorderColor];
    self.bottomLine.frame = CGRectMake(0, 174, SCREEN_WIDTH, .5);
    self.bottomLine.backgroundColor = [TDConstants darkBorderColor];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)setHashTagInfoCell {
    self.frame = CGRectMake(0, 0 , SCREEN_WIDTH, [TDGuestInfoCell heightForHashTagInfoCell]);

    self.icon.hidden = NO;
    self.label1.hidden = NO;
    self.label2.hidden = NO;

    self.icon.frame = CGRectMake(SCREEN_WIDTH/2 - kBigImageWidth/2,
                                 15,
                                 kBigImageWidth,
                                 kBigImageHeight );
    [self addSubview:self.icon];

    NSString *titleStr = @"Announcing the Strengthlete\n28-Day Challenge!";
    NSAttributedString *titleAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23./19.)];
    self.label1.attributedText = titleAttrStr;
    [self.label1 setNumberOfLines:0];
    [self.label1 sizeToFit];

    CGRect label1Frame = self.label1.frame;
    label1Frame.origin.x =  self.frame.size.width/2 - self.label1.frame.size.width/2;
    label1Frame.origin.y = self.icon.frame.origin.y + self.icon.frame.size.height + 10;
    self.label1.frame = label1Frame;
    [self addSubview:self.label1];

    NSString *detailStr = @"Strengthlete challenges you to eat clean and exercise for all of February!\n\nPrizes to those who fully participate during this month, and for biggest accomplishments!\n\nSee posts from fellow Challenger";
    NSMutableAttributedString *detailAttrStr = [[NSMutableAttributedString alloc] initWithString:detailStr];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:18/15.];
    [paragraphStyle setMinimumLineHeight:18];
    [paragraphStyle setMaximumLineHeight:18];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [detailAttrStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:15] range:NSMakeRange(0, detailStr.length)];
    [detailAttrStr addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, detailStr.length)];
    self.label2.attributedText = detailAttrStr;
    [self.label2 setNumberOfLines:0];
    [self.label2 sizeToFit];
    [self addSubview:self.label2];
}

- (void)setInfoCell {
    // Initialization code
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, [TDGuestInfoCell heightForInfoCell]);
    [self addSubview:self.topLine];
    
    self.label1.text = TDCommunityValuesStr;
    self.label1.textColor = [TDConstants brandingRedColor];
    self.label1.font = [TDConstants fontSemiBoldSized:22];
    [self.label1 sizeToFit];
    
    CGRect label1Frame = self.label1.frame;
    label1Frame.origin.x =  self.frame.size.width/2 - self.label1.frame.size.width/2;
    label1Frame.origin.y = 15;
    self.label1.frame = label1Frame;
    [self addSubview:self.label1];
    
    NSAttributedString *infoStr = [TDViewControllerHelper makeLeftAlignedTextWithString:TDValueStr1 font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:20 lineHeightMultipler:(20/16.)];
    self.label2.attributedText = infoStr;
    [self.label2 setNumberOfLines:0];
    [self.label2 sizeToFit];
    
    CGRect label2Frame = self.label2.frame;
    label2Frame.origin.x = 20;
    label2Frame.origin.y = self.label1.frame.origin.y + self.label1.frame.size.height + 12;
    self.label2.frame = label2Frame;
    [self addSubview:self.label2];

    NSAttributedString *infoStr2 = [TDViewControllerHelper makeLeftAlignedTextWithString:TDValueStr2 font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:20 lineHeightMultipler:(20./16.)];
    self.label3.attributedText = infoStr2;
    [self.label3 setNumberOfLines:0];
    [self.label3 sizeToFit];
    
    CGRect label3Frame = self.label3.frame;
    label3Frame.origin.x = 20;
    label3Frame.origin.y = self.label2.frame.origin.y + self.label2.frame.size.height;
    self.label3.frame = label3Frame;
    [self addSubview:self.label3];

    NSString *infoText3 = TDValueStr3;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:infoText3];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:20/16];
    [paragraphStyle setMinimumLineHeight:20];
    [paragraphStyle setMaximumLineHeight:20];
    [paragraphStyle setAlignment:NSTextAlignmentLeft];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, infoText3.length)];
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:16] range:NSMakeRange(0, infoText3.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, infoText3.length)];
    
    UIFont *boldFont = [TDConstants fontSemiBoldSized:16];
    UIColor *foregroundColor = [TDConstants headerTextColor];
    // Create the attributes
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           boldFont, NSFontAttributeName,
                           foregroundColor, NSForegroundColorAttributeName, nil];
    const NSRange range = NSMakeRange(0,15); // range of " 2012/10/14 ". Ideally this should not be hardcoded
    
    [attributedString setAttributes:attrs range:range];
    
    self.label4.attributedText = attributedString;
    [self.label4 setNumberOfLines:1];
    [self.label4 sizeToFit];
    
    CGRect label4Frame = self.label4.frame;
    label4Frame.origin.x = 20;
    label4Frame.origin.y = self.label3.frame.origin.y + self.label3.frame.size.height+4 ; // Add 4 because line height gets reset to 16 after bolding.
    self.label4.frame = label4Frame;
    [self addSubview:self.label4];

    self.bottomLine.frame = CGRectMake(0, self.label4.frame.origin.y + self.label4.frame.size.height + 20, SCREEN_WIDTH, .5);
    [self addSubview:self.bottomLine];
    
    self.bottomMarginPadding.frame = CGRectMake(0, self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight);
    self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomMarginPadding];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setLastCell {
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, [TDGuestInfoCell heightForLastCell]);
    [self addSubview:self.topLine];
    
    self.label2.hidden = NO;
    
    NSAttributedString *infoStr = [TDViewControllerHelper makeParagraphedTextWithString:@"To see more posts, please join us\nby creating an account.\n\nWe'd love to have you!" font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:20 lineHeightMultipler:20/16];
    self.label2.attributedText = infoStr;
    [self.label2 setNumberOfLines:0];
    [self.label2 sizeToFit];
    CGRect label2Frame = self.label2.frame;
    label2Frame.origin.x = self.frame.size.width/2 - self.label2.frame.size.width/2;
    label2Frame.origin.y = 15;
    self.label2.frame = label2Frame;
    [self addSubview:self.label2];
    
    [self.button setImage:[UIImage imageNamed:signupButtonStr] forState:UIControlStateNormal];
    [self.button setImage:[UIImage imageNamed:signupButtonHitStr] forState:UIControlStateHighlighted];
    [self.button setImage:[UIImage imageNamed:signupButtonHitStr] forState:UIControlStateSelected];
    
    self.button.frame = CGRectMake(
                                        self.frame.size.width/2 - [UIImage imageNamed:signupButtonStr].size.width/2,
                                        self.label2.frame.origin.y + self.label2.frame.size.height + 15,
                                        [UIImage imageNamed:signupButtonStr].size.width,
                                        [UIImage imageNamed:signupButtonStr].size.height);
    [self addSubview:self.button];
    
    self.bottomLine.frame = CGRectMake(0, [TDGuestInfoCell heightForLastCell], SCREEN_WIDTH, .5);
    [self addSubview:self.bottomLine];
    
}

- (void)setNewUserCell:(BOOL)addTopMargin {
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, [TDGuestInfoCell heightForNewUserCell:addTopMargin]);
    if (addTopMargin) {
        self.topMarginPadding.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, topMarginPaddingHeight);

        self.topMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
        [self addSubview:self.topMarginPadding];

        CGRect topLineFrame = self.topLine.frame;
        topLineFrame.origin.y = topMarginPaddingHeight;
        self.topLine.frame = topLineFrame;
        [self addSubview:self.topLine];
    } else {
        self.topLine.frame = CGRectMake(0, .5, SCREEN_WIDTH, .5);
        [self addSubview:self.topLine];
        [self.topLine setBackgroundColor:[TDConstants darkBorderColor]];
    }

    self.icon.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"td_icon"].size.width/2,
                                 (addTopMargin ? (self.topMarginPadding.frame.origin.y + self.topMarginPadding.frame.size.height) : .5) + 15,
                                 [UIImage imageNamed:@"td_icon"].size.width,
                                 [UIImage imageNamed:@"td_icon"].size.height );
    [self addSubview:self.icon];

    NSString *firstName = [self getFirstName:[TDCurrentUser sharedInstance].name];

    NSString *welcomeStr = [NSString stringWithFormat:@"%@%@%@", @"Welcome ", firstName, @"!\nLet's create your first post." ];
    NSAttributedString *str = [TDViewControllerHelper makeParagraphedTextWithString:welcomeStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:23/19];
    self.label1.attributedText = str;
    [self.label1 setNumberOfLines:0];
    [self.label1 sizeToFit];
    
    CGRect label1Frame = self.label1.frame;
    label1Frame.origin.x =  self.frame.size.width/2 - self.label1.frame.size.width/2;
    label1Frame.origin.y = self.icon.frame.origin.y + self.icon.frame.size.height + 15;
    self.label1.frame = label1Frame;
    [self addSubview:self.label1];

    NSAttributedString *infoStr = [TDViewControllerHelper makeLeftAlignedTextWithString:text1 font:[TDConstants fontRegularSized:15] color:[TDConstants commentTimeTextColor] lineHeight:18 lineHeightMultipler:18/15];
    self.label2.attributedText = infoStr;
    [self.label2 setNumberOfLines:0];
    [self.label2 sizeToFit];
    CGRect label2Frame = self.label2.frame;
    label2Frame.origin.x = 30;
    label2Frame.origin.y = self.label1.frame.origin.y + self.label1.frame.size.height + 15;
    self.label2.frame = label2Frame;
    [self addSubview:self.label2];

    NSAttributedString *infoStr2 = [TDViewControllerHelper makeLeftAlignedTextWithString:text2 font:[TDConstants fontRegularSized:15] color:[TDConstants commentTimeTextColor] lineHeight:18 lineHeightMultipler:18/15];
    self.label3.attributedText = infoStr2;
    [self.label3 setNumberOfLines:0];
    [self.label3 sizeToFit];
    CGRect label3Frame = self.label3.frame;
    label3Frame.origin.x = 30;
    label3Frame.origin.y = self.label2.frame.origin.y + self.label2.frame.size.height + 12;
    self.label3.frame = label3Frame;
    [self addSubview:self.label3];

    [self.button setImage:[UIImage imageNamed:createPostStr] forState:UIControlStateNormal];
    [self.button setImage:[UIImage imageNamed:createPostHitStr] forState:UIControlStateSelected];
    [self.button setImage:[UIImage imageNamed:createPostHitStr] forState:UIControlStateHighlighted];
    self.button.frame = CGRectMake(
                                        self.frame.size.width/2 - [UIImage imageNamed:createPostStr].size.width/2,
                                        self.label3.frame.origin.y + self.label3.frame.size.height + 25,
                                        [UIImage imageNamed:createPostStr].size.width,
                                        [UIImage imageNamed:createPostStr].size.height);
    [self.button addTarget:self action:@selector(createPostButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.button];

    NSString *dismiss = @"Dismiss, I'll do it later.";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:dismiss];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:17/14];
    [paragraphStyle setMinimumLineHeight:17];
    [paragraphStyle setMaximumLineHeight:17];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:14] range:NSMakeRange(0, dismiss.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, dismiss.length)];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, dismiss.length)];
    [self.dismissButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    [self.dismissButton sizeToFit];
    [self.dismissButton removeTarget:self action:@selector(dismissForExistingUser) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    CGRect dismissFrame = self.dismissButton.frame;
    dismissFrame.origin.x = self.frame.size.width/2 - self.dismissButton.frame.size.width/2;
    dismissFrame.origin.y = self.button.frame.origin.y + self.button.frame.size.height + 10;
    self.dismissButton.frame = dismissFrame;
    [self addSubview:self.dismissButton];

    self.bottomLine.frame = CGRectMake(0, self.dismissButton.frame.origin.y + self.dismissButton.frame.size.height +15, SCREEN_WIDTH, .5);
    [self addSubview:self.bottomLine];

    self.bottomMarginPadding.frame = CGRectMake(0, self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight);
    self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomMarginPadding];
}

- (void)setGuestUserCell {
    // Initialization code
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, [TDGuestInfoCell heightForGuestUserCell]);
    self.topMarginPadding.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, topMarginPaddingHeight);
    self.topMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.topMarginPadding];
    
    CGRect topLineFrame = self.topLine.frame;
    topLineFrame.origin.y = 15;
    self.topLine.frame = topLineFrame;
    [self addSubview:self.topLine];
    
    self.icon.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"td_icon"].size.width/2,
                                 self.topMarginPadding.frame.origin.y + self.topMarginPadding.frame.size.height + 15,
                                 [UIImage imageNamed:@"td_icon"].size.width,
                                 [UIImage imageNamed:@"td_icon"].size.height );
    [self addSubview:self.icon];
    
    NSString *welcomeStr = @"Welcome to Throwdown!";
    NSAttributedString *str = [TDViewControllerHelper makeParagraphedTextWithString:welcomeStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:23/19];
    self.label1.attributedText = str;
    [self.label1 setNumberOfLines:0];
    [self.label1 sizeToFit];
    
    CGRect label1Frame = self.label1.frame;
    label1Frame.origin.x =  self.frame.size.width/2 - self.label1.frame.size.width/2;
    label1Frame.origin.y = self.icon.frame.origin.y + self.icon.frame.size.height + 15;
    self.label1.frame = label1Frame;
    [self addSubview:self.label1];
    
    
    NSAttributedString *infoStr = [TDViewControllerHelper makeLeftAlignedTextWithString:guestWelcomeStr font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:18/16];
    self.label2.attributedText = infoStr;
    [self.label2 setNumberOfLines:0];
    [self.label2 sizeToFit];
    
    CGRect label2Frame = self.label2.frame;
    label2Frame.size.width = SCREEN_WIDTH - 60; // Margin both sides;
    label2Frame.origin.x = 30;
    label2Frame.origin.y = self.label1.frame.origin.y + self.label1.frame.size.height + 15;
    self.label2.frame = label2Frame;
    [self addSubview:self.label2];
    [self.label2 sizeToFit];
    
    [self.button setImage:[UIImage imageNamed:signupButtonStr] forState:UIControlStateNormal];
    [self.button setImage:[UIImage imageNamed:signupButtonHitStr] forState:UIControlStateSelected];
    [self.button setImage:[UIImage imageNamed:signupButtonHitStr] forState:UIControlStateHighlighted];
    self.button.frame = CGRectMake(
                                   self.frame.size.width/2 - [UIImage imageNamed:signupButtonStr].size.width/2,
                                   self.label2.frame.origin.y + self.label2.frame.size.height + 25,
                                   [UIImage imageNamed:signupButtonStr].size.width,
                                   [UIImage imageNamed:signupButtonStr].size.height);
    [self.button addTarget:self action:@selector(signupButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.button sizeToFit];
    [self addSubview:self.button];
    
    self.bottomLine.frame = CGRectMake(0, self.button.frame.origin.y + self.button.frame.size.height +15, SCREEN_WIDTH, .5);
    [self addSubview:self.bottomLine];
    
    self.bottomMarginPadding.frame = CGRectMake(0, self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight);
    self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomMarginPadding];
}

- (void)setExistingUserCell:(BOOL)addTopMargin{
    // Initialization code
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, [TDGuestInfoCell heightForExistingUserCell:addTopMargin]);
    if (addTopMargin) {
        self.topMarginPadding.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, topMarginPaddingHeight);

        self.topMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
        [self addSubview:self.topMarginPadding];
        self.topMarginPadding.layer.borderColor = [[UIColor redColor] CGColor];
        self.topMarginPadding.layer.borderWidth = 2.;

        CGRect topLineFrame = self.topLine.frame;
        topLineFrame.origin.y = topMarginPaddingHeight;
        self.topLine.frame = topLineFrame;
        [self addSubview:self.topLine];
    } else {
        self.topLine.frame = CGRectMake(0, .5, SCREEN_WIDTH, .5);
        [self addSubview:self.topLine];
    }

    self.icon.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"td_icon"].size.width/2,
                                 (addTopMargin ? (self.topMarginPadding.frame.origin.y + self.topMarginPadding.frame.size.height) : .5) + 15,
                                 [UIImage imageNamed:@"td_icon"].size.width,
                                 [UIImage imageNamed:@"td_icon"].size.height );
    [self addSubview:self.icon];
    
    NSString *welcomeStr = [NSString stringWithFormat:@"%@%@%@", @"Welcome ", [TDCurrentUser sharedInstance].name, @"!\nTell us about yourself." ];
    NSAttributedString *str = [TDViewControllerHelper makeParagraphedTextWithString:welcomeStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:23/19];
    self.label1.attributedText = str;
    [self.label1 setNumberOfLines:0];
    [self.label1 sizeToFit];
    
    CGRect label1Frame = self.label1.frame;
    label1Frame.origin.x =  self.frame.size.width/2 - self.label1.frame.size.width/2;
    label1Frame.origin.y = self.icon.frame.origin.y + self.icon.frame.size.height + 15;
    self.label1.frame = label1Frame;
    [self addSubview:self.label1];
    
    
    NSAttributedString *infoStr = [TDViewControllerHelper makeLeftAlignedTextWithString:existingUser1 font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:18/15];
    self.label2.attributedText = infoStr;
    [self.label2 setNumberOfLines:0];
    [self.label2 sizeToFit];
    CGRect label2Frame = self.label2.frame;
    label2Frame.size.width = SCREEN_WIDTH - 60;
    label2Frame.origin.x = 30;
    label2Frame.origin.y = self.label1.frame.origin.y + self.label1.frame.size.height + 15;
    self.label2.frame = label2Frame;

    NSAttributedString *learnAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:@"Learn More" font:[TDConstants fontSemiBoldSized:17] color:[TDConstants brandingRedColor] lineHeight:17 lineHeightMultipler:17];
    [self.learnButton setAttributedTitle:learnAttrStr forState:UIControlStateNormal];
    [self.learnButton addTarget:self action:@selector(learnButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.learnButton sizeToFit];

    CGRect learnFrame = self.learnButton.frame;
    learnFrame.origin.x = SCREEN_WIDTH/2 - self.learnButton.frame.size.width/2;
    learnFrame.origin.y = self.label2.frame.origin.y + self.label2.frame.size.height + 15;
    self.learnButton.frame = learnFrame;
    [self addSubview:self.learnButton];

    self.bottomLine.frame = CGRectMake(0, self.learnButton.frame.origin.y + self.learnButton.frame.size.height + 15, SCREEN_WIDTH, .5);
    [self addSubview:self.bottomLine];

    self.bottomMarginPadding.frame = CGRectMake(0, self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight);
    [self.label2 sizeToFit];
    [self addSubview:self.label2];
    
    NSAttributedString *infoStr2 = [TDViewControllerHelper makeLeftAlignedTextWithString:existingUser2 font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:18/15];
    self.label3.attributedText = infoStr2;
    [self.label3 setNumberOfLines:0];
    [self.label3 sizeToFit];
    CGRect label3Frame = self.label3.frame;
    label3Frame.size.width = SCREEN_WIDTH - 60;
    label3Frame.origin.x = 30;
    label3Frame.origin.y = self.label2.frame.origin.y + self.label2.frame.size.height + 12;
    self.label3.frame = label3Frame;
    [self.label3 sizeToFit];
    [self addSubview:self.label3];
    
    NSAttributedString *info3 = [TDViewControllerHelper makeLeftAlignedTextWithString:existingUser3 font:[TDConstants fontRegularSized:14] color:[TDConstants commentTimeTextColor] lineHeight:17 lineHeightMultipler:17/14];
    self.label4.attributedText = info3;
    [self.label4 setNumberOfLines:0];
    [self.label4 sizeToFit];
    CGRect label4Frame = self.label4.frame;
    label4Frame.size.width = SCREEN_WIDTH - 60;
    label4Frame.origin.x = 30;
    label4Frame.origin.y = self.label3.frame.origin.y + self.label3.frame.size.height;
    self.label4.frame = label4Frame;
    [self.label4 sizeToFit];
    [self addSubview:self.label4];
    
    [self.button setImage:[UIImage imageNamed:setGoalsStr] forState:UIControlStateNormal];
    [self.button setImage:[UIImage imageNamed:setGoalsHitStr] forState:UIControlStateSelected];
    [self.button setImage:[UIImage imageNamed:setGoalsHitStr] forState:UIControlStateHighlighted];
    self.button.frame = CGRectMake(
                                   self.frame.size.width/2 - [UIImage imageNamed:setGoalsStr].size.width/2,
                                   self.label4.frame.origin.y + self.label4.frame.size.height + 25,
                                   [UIImage imageNamed:setGoalsStr].size.width,
                                   [UIImage imageNamed:setGoalsStr].size.height);
    [self.button addTarget:self action:@selector(goalsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.button sizeToFit];
    [self addSubview:self.button];
    
    NSString *dismiss = @"Dismiss, I'll do it later.";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:dismiss];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:17/14];
    [paragraphStyle setMinimumLineHeight:17];
    [paragraphStyle setMaximumLineHeight:17];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:14] range:NSMakeRange(0, dismiss.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, dismiss.length)];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, dismiss.length)];
    [self.dismissButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    [self.dismissButton sizeToFit];
    [self.dismissButton removeTarget:self action:@selector(dismissButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton addTarget:self action:@selector(dismissForExistingUser) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect dismissFrame = self.dismissButton.frame;
    dismissFrame.origin.x = self.frame.size.width/2 - self.dismissButton.frame.size.width/2;
    dismissFrame.origin.y = self.button.frame.origin.y + self.button.frame.size.height + 10;
    self.dismissButton.frame = dismissFrame;
    [self addSubview:self.dismissButton];
    
    self.bottomLine.frame = CGRectMake(0, self.dismissButton.frame.origin.y + self.dismissButton.frame.size.height +15, SCREEN_WIDTH, .5);
    [self addSubview:self.bottomLine];
    self.bottomMarginPadding.frame = CGRectMake(0, self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight);
    self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomMarginPadding];

}

- (void)setEditGoalsCell:(BOOL)showCloseButton {
    self.frame = CGRectMake(0, 0, SCREEN_WIDTH, [TDGuestInfoCell heightForEditGoalsCell]);

    self.topMarginPadding.frame = CGRectMake(0, 0, SCREEN_WIDTH, 44);
    self.topMarginPadding.backgroundColor = [TDConstants lightBackgroundColor];
    [self addSubview:self.topMarginPadding];
    
    NSString *text = @"Tap here to edit your goals and interests";
    self.label1.text = text;
    self.label1.textAlignment = NSTextAlignmentCenter;
    self.label1.font = [TDConstants fontRegularSized:15];
    self.label1.textColor = [TDConstants headerTextColor];
    self.label1.frame = CGRectMake(0, 0, SCREEN_WIDTH, 44);
    self.label1.backgroundColor = [TDConstants lightBackgroundColor];
    [self.label1 sizeToFit];

    CGRect label1Frame = self.label1.frame;
    label1Frame.origin.x = self.topMarginPadding.frame.size.width/2 - self.label1.frame.size.width/2;
    label1Frame.origin.y = (self.topMarginPadding.frame.size.height/2 - self.label1.frame.size.height/2);
    self.label1.frame = label1Frame;
    [self.topMarginPadding addSubview:self.label1];

    if (showCloseButton) {
        self.label1.textAlignment = NSTextAlignmentLeft;
        [self.label1 sizeToFit];

        CGRect label1Frame = self.label1.frame;
        label1Frame.origin.x = 10;
        label1Frame.origin.y = (self.topMarginPadding.frame.size.height/2 - self.label1.frame.size.height/2);
        self.label1.frame = label1Frame;
        [self.topMarginPadding addSubview:self.label1];

        CGRect closeButtonFrame = self.closeButton.frame;
        closeButtonFrame.origin.x = SCREEN_WIDTH - 10 - [UIImage imageNamed:@"btn_x_small"].size.width;
        closeButtonFrame.origin.y = self.topMarginPadding.frame.size.height/2 - [UIImage imageNamed:@"btn_x_small"].size.height/2;
        self.closeButton.frame = closeButtonFrame;
        [self addSubview:self.closeButton];

        //- Adjust the size of the button to have a larger tap area
        self.closeButton.frame = CGRectMake(self.closeButton.frame.origin.x -10,
                                            0,
                                            self.closeButton.frame.size.width + 20,
                                            44 );
    }
    self.bottomMarginPadding.frame = CGRectMake(0, self.topMarginPadding.frame.origin.y + self.topMarginPadding.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight);
    self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomMarginPadding];
}

- (IBAction)signupButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(signupButtonPressed)]) {
        [self.delegate signupButtonPressed];
    }
}

- (IBAction)dismissButtonPressed:(id)sender {
    [[TDCurrentUser sharedInstance] isNewUser:NO];

    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissButtonPressed)]) {
        [self.delegate dismissButtonPressed];
    }
}

- (void)createPostButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(createPostButtonPressed)]) {
        [self.delegate createPostButtonPressed];
    }
}

- (void)goalsButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(goalsButtonPressed)]) {
        [self.delegate goalsButtonPressed];
    }
}

- (void)dismissForExistingUser {
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissForExistingUser)]) {
        [self.delegate dismissForExistingUser];
    }
}

- (IBAction)closeButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(reloadTableView)]) {
        [self.delegate reloadTableView];
    }
}

- (void)learnButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(loadDetailView)]) {
        [self.delegate loadDetailView];
    }
}

+ (NSInteger)heightForHashTagInfoCell {

    NSString *titleStr = @"Announcing the Strengthlete\n28-Day Challenge!";
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSAttributedString *titleAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:titleStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:(23./19.)];
    label1.attributedText = titleAttrStr;
    [label1 setNumberOfLines:0];
    [label1 sizeToFit];

    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSString *detailStr = @"Strengthlete challenges you to eat clean and exercise for all of February!\n\nPrizes to those who fully participate during this month, and for biggest accomplishments!\n\nSee posts from fellow Challenger";
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
    NSAttributedString *learnAttrStr = [TDViewControllerHelper makeParagraphedTextWithString:@"Learn More" font:[TDConstants fontSemiBoldSized:17] color:[TDConstants brandingRedColor] lineHeight:17 lineHeightMultipler:17];
    [learnButton setAttributedTitle:learnAttrStr forState:UIControlStateNormal];
    [learnButton sizeToFit];

    return 15 + kBigImageHeight + 10 + label1.frame.size.height + 15 + label2.frame.size.height + 15 + learnButton.frame.size.height + 15 + bottomMarginPaddingHeight;
}

+ (NSInteger) heightForLastCell {
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSAttributedString *infoStr = [TDViewControllerHelper makeParagraphedTextWithString:@"To see more posts, please join us\nby creating an account.\n\nWe'd love to have you!" font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:20 lineHeightMultipler:20/16];
    label1.attributedText = infoStr;
    [label1 setNumberOfLines:0];
    [label1 sizeToFit];

    NSInteger height = 15 + label1.frame.size.height + 15 + [UIImage imageNamed:@"btn_join_throwdown"].size.height + 20;
    return height;
    
}

+ (NSInteger)heightForInfoCell {
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UILabel *label3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UILabel *label4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];

   label1.text = TDCommunityValuesStr;
    label1.textColor = [TDConstants brandingRedColor];
    label1.font = [TDConstants fontSemiBoldSized:22];
    [label1 sizeToFit];

    
    NSAttributedString *infoStr = [TDViewControllerHelper makeLeftAlignedTextWithString:TDValueStr1 font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:20 lineHeightMultipler:(20/16.)];
   label2.attributedText = infoStr;
    [label2 setNumberOfLines:0];
    [label2 sizeToFit];

    NSAttributedString *infoStr2 = [TDViewControllerHelper makeLeftAlignedTextWithString:TDValueStr2 font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:20 lineHeightMultipler:(20./16.)];
    label3.attributedText = infoStr2;
    [label3 setNumberOfLines:0];
    [label3 sizeToFit];
    
       NSString *infoText3 = TDValueStr3;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:infoText3];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:20/16.];
    [paragraphStyle setMinimumLineHeight:20];
    [paragraphStyle setMaximumLineHeight:20];
    [paragraphStyle setAlignment:NSTextAlignmentLeft];
    
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, infoText3.length)];
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:16] range:NSMakeRange(0, infoText3.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, infoText3.length)];
    
    UIFont *boldFont = [TDConstants fontSemiBoldSized:16];
    UIColor *foregroundColor = [TDConstants headerTextColor];
    // Create the attributes
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           boldFont, NSFontAttributeName,
                           foregroundColor, NSForegroundColorAttributeName, nil];
    const NSRange range = NSMakeRange(0,16); // range of " 2012/10/14 ". Ideally this should not be hardcoded
    
    [attributedString setAttributes:attrs range:range];
    label4.attributedText = attributedString;
    [label4 sizeToFit];
    
    NSInteger height = 15 + label1.frame.size.height + 12 + label2.frame.size.height + label3.frame.size.height + label4.frame.size.height + 20 + 15;
    
    return height;
}

+ (NSInteger) heightForNewUserCell:(BOOL)addTopMargin {
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSString *welcomeStr = [NSString stringWithFormat:@"%@%@%@", @"Welcome ", [TDCurrentUser sharedInstance].name, @"!\nLet's create your first post." ];
    NSAttributedString *str = [TDViewControllerHelper makeParagraphedTextWithString:welcomeStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:23/19];
    label1.attributedText = str;
    [label1 setNumberOfLines:0];
    [label1 sizeToFit];

    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSAttributedString *infoStr = [TDViewControllerHelper makeLeftAlignedTextWithString:text1 font:[TDConstants fontRegularSized:15] color:[TDConstants commentTimeTextColor] lineHeight:18 lineHeightMultipler:18/15];
    label2.attributedText = infoStr;
    [label2 setNumberOfLines:0];
    [label2 sizeToFit];

    UILabel *label3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    NSAttributedString *infoStr2 = [TDViewControllerHelper makeLeftAlignedTextWithString:text2 font:[TDConstants fontRegularSized:15] color:[TDConstants commentTimeTextColor] lineHeight:18 lineHeightMultipler:18/15];
    label3.attributedText = infoStr2;
    [label3 setNumberOfLines:0];
    [label3 sizeToFit];

    UIButton *tmpButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];

    NSString *dismiss = @"Dismiss, I'll do it later.";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:dismiss];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:17/14];
    [paragraphStyle setMinimumLineHeight:17];
    [paragraphStyle setMaximumLineHeight:17];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:14] range:NSMakeRange(0, dismiss.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, dismiss.length)];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, dismiss.length)];
    [tmpButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    [tmpButton sizeToFit];

    NSInteger height = (addTopMargin ? 15 : .5) + 15 + [UIImage imageNamed:@"td_icon"].size.height + 15 + label1.frame.size.height + 15 + label2.frame.size.height + 12 + label3.frame.size.height + 25 + [UIImage imageNamed:createPostStr].size.height + 10 + tmpButton.frame.size.height + 15 + .5 + bottomMarginPaddingHeight;

   return height;
}

+ (NSInteger)heightForGuestUserCell {
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UIButton *tempButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    
    NSString *welcomeStr = @"Welcome to Throwdown!";
    NSAttributedString *str = [TDViewControllerHelper makeParagraphedTextWithString:welcomeStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:23/19];
    label1.attributedText = str;
    [label1 setNumberOfLines:0];
    [label1 sizeToFit];
    
    
    NSAttributedString *infoStr = [TDViewControllerHelper makeLeftAlignedTextWithString:guestWelcomeStr font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:18/16];
    label2.attributedText = infoStr;
    [label2 setNumberOfLines:0];
    [label2 sizeToFit];
    
    CGRect label2Frame = label2.frame;
    label2Frame.size.width = SCREEN_WIDTH - 60; // Margin both sides;
    label2.frame = label2Frame;
    [label2 sizeToFit];
    
    [tempButton setImage:[UIImage imageNamed:signupButtonStr] forState:UIControlStateNormal];
    [tempButton sizeToFit];

    NSInteger height = topMarginPaddingHeight + .5 + 15 + [UIImage imageNamed:@"td_icon"].size.height + 15 + label1.frame.size.height + 15 + label2.frame.size.height + 25 + tempButton.frame.size.height + 15 + .5 + bottomMarginPaddingHeight;
    return height;
    
}

+ (NSInteger)heightForExistingUserCell:(BOOL)addTopMargin {
    UILabel *label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UILabel *label2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UIButton *tempButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UILabel *label3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    UILabel *label4 =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 100)];
    
    NSString *welcomeStr = [NSString stringWithFormat:@"%@%@%@", @"Welcome ", [TDCurrentUser sharedInstance].name, @"!\nTell us about yourself." ];
    NSAttributedString *str = [TDViewControllerHelper makeParagraphedTextWithString:welcomeStr font:[TDConstants fontSemiBoldSized:19] color:[TDConstants headerTextColor] lineHeight:23 lineHeightMultipler:23/19];
    label1.attributedText = str;
    [label1 setNumberOfLines:0];
    [label1 sizeToFit];
    
    NSAttributedString *infoStr = [TDViewControllerHelper makeLeftAlignedTextWithString:existingUser1 font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:18/15];
    label2.attributedText = infoStr;
    [label2 setNumberOfLines:0];
    [label2 sizeToFit];
    CGRect label2Frame =label2.frame;
    label2Frame.size.width = SCREEN_WIDTH - 60;
    label2.frame = label2Frame;
    [label2 sizeToFit];
    
    NSAttributedString *infoStr2 = [TDViewControllerHelper makeLeftAlignedTextWithString:existingUser2 font:[TDConstants fontRegularSized:15] color:[TDConstants headerTextColor] lineHeight:18 lineHeightMultipler:18/15];
    label3.attributedText = infoStr2;
    [label3 setNumberOfLines:0];
    [label3 sizeToFit];
    CGRect label3Frame = label3.frame;
    label3Frame.size.width = SCREEN_WIDTH - 60;
    label3.frame = label3Frame;
    [label3 sizeToFit];
    
    NSAttributedString *info3 = [TDViewControllerHelper makeLeftAlignedTextWithString:existingUser3 font:[TDConstants fontRegularSized:14] color:[TDConstants commentTimeTextColor] lineHeight:17 lineHeightMultipler:17/14];
    label4.attributedText = info3;
    [label4 setNumberOfLines:0];
    [label4 sizeToFit];
    CGRect label4Frame = label4.frame;
    label4Frame.size.width = SCREEN_WIDTH - 60;
    label4.frame = label4Frame;
    [label4 sizeToFit];
    
    NSString *dismiss = @"Dismiss, I'll do it later.";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:dismiss];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:17/14];
    [paragraphStyle setMinimumLineHeight:17];
    [paragraphStyle setMaximumLineHeight:17];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:14] range:NSMakeRange(0, dismiss.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, dismiss.length)];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, dismiss.length)];
    [tempButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    [tempButton sizeToFit];
    
    NSInteger height = (addTopMargin ? 15 : .5) + 15 + [UIImage imageNamed:@"td_icon"].size.height + 15 + label1.frame.size.height + 15 + label2.frame.size.height + 12 + label3.frame.size.height + label4.frame.size.height + 25 + [UIImage imageNamed:setGoalsStr].size.height + 10 + tempButton.frame.size.height + 15 + bottomMarginPaddingHeight;

    return height;
}

+ (NSInteger)heightForEditGoalsCell {
    UIView *view = [[UIView alloc ] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44)];
    view.backgroundColor = [TDConstants lightBackgroundColor];

    NSInteger height = view.frame.size.height + bottomMarginPaddingHeight;
    return height;
}

- (NSString*)getFirstName:(NSString*)name {
    NSArray *arrayName = [name componentsSeparatedByString:@" "];
    debug NSLog(@"returning name = %@", arrayName[0]);
    return arrayName[0];
}
@end
