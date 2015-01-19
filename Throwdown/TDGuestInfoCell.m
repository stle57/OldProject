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
    self.topLine.frame = CGRectMake(0, 0, SCREEN_WIDTH, .5);
    self.bottomLine.frame = CGRectMake(0, 174, SCREEN_WIDTH, .5);
    self.topLine.backgroundColor = [TDConstants darkBorderColor];
    self.bottomLine.backgroundColor = [TDConstants darkBorderColor];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)setHashTagInfoCell {
    self.frame = CGRectMake(0, 0 , SCREEN_WIDTH, 130);

    self.icon.hidden = NO;
    self.label1.hidden = NO;
    self.label2.hidden = NO;

    self.icon.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.width/2,
                                 15,
                                 [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.width,
                                 [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height );
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
    self.bottomLine.backgroundColor = [UIColor redColor];

    self.bottomMarginPadding.frame = CGRectMake(0, self.bottomLine.frame.origin.y + self.bottomLine.frame.size.height, [UIScreen mainScreen].bounds.size.width, bottomMarginPaddingHeight);
    self.bottomMarginPadding.backgroundColor = [TDConstants darkBackgroundColor];
    [self addSubview:self.bottomMarginPadding];

}

- (IBAction)signupButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(signupButtonPressed)]) {
        [self.delegate signupButtonPressed];
    }
}

- (IBAction)dismissButtonPressed:(id)sender {
//    [TDCurrentUser sharedInstance].newUser = NO;
//    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissButtonPressed)]) {
//        [self.delegate dismissButtonPressed];
//    }
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

    debug NSLog(@"height = %f", 15 + [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height + 10 + label1.frame.size.height + 15 + label2.frame.size.height + 15 + learnButton.frame.size.height + 15 + bottomMarginPaddingHeight);

    return 15 + [UIImage imageNamed:@"Strengthlete_Logo_BIG"].size.height + 10 + label1.frame.size.height + 15 + label2.frame.size.height + 15 + learnButton.frame.size.height + 15 + bottomMarginPaddingHeight;
}
@end
