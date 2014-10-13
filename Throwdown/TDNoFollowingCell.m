//
//  TDNoFollowingCell.m
//  Throwdown
//
//  Created by Stephanie Le on 10/12/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDNoFollowingCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"

@implementation TDNoFollowingCell

- (void)awakeFromNib {
    CGRect cellFrame = self.frame;
    cellFrame.size.width = SCREEN_WIDTH;
    cellFrame.size.height = SCREEN_HEIGHT;
    self.frame = cellFrame;
    
    CGRect searchLabelFrame = self.searchTDUsersButton.frame;
    searchLabelFrame.origin.y = 50;
    searchLabelFrame.origin.x = SCREEN_WIDTH/2 - searchLabelFrame.size.width/2;
    self.searchTDUsersButton.frame = searchLabelFrame;
    [self addSubview:self.searchTDUsersButton];
    
    self.addFollowersLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH, 50);
    NSString *addText = @"Add Followers";
    NSAttributedString *addAttrString = [TDViewControllerHelper makeParagraphedTextWithString:addText font:[TDConstants fontSemiBoldSized:16] color:[TDConstants headerTextColor] lineHeight:16.0 lineHeightMultipler:(16/16.0)];
    self.addFollowersLabel.attributedText = addAttrString;
    [self.addFollowersLabel sizeToFit];
    CGRect labelFrame = self.addFollowersLabel.frame;
    labelFrame.origin.x = SCREEN_WIDTH/2 - labelFrame.size.width/2;
    labelFrame.origin.y = searchLabelFrame.origin.y + searchLabelFrame.size.height + 18;
    self.addFollowersLabel.frame = labelFrame;
    [self addSubview:self.addFollowersLabel];
    
    self.descriptionLabel.frame = CGRectMake(0, 0, SCREEN_WIDTH, 100);
    NSString *text = @"You're currently not following anyone\non Throwdown.  Find people to follow\nby tapping above.";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:(20./14.)];
    [paragraphStyle setMinimumLineHeight:20.0];
    [paragraphStyle setMaximumLineHeight:20.0];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:14] range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, text.length)];
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    textAttachment.image = [UIImage imageNamed:@"icon-add follower in text.png"];
    
    NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
    
    [attributedString replaceCharactersInRange:NSMakeRange(text.length-8, 1) withAttributedString:attrStringWithImage];
    
    self.descriptionLabel.attributedText = attributedString;
    [self.descriptionLabel setNumberOfLines:0];
    [self.descriptionLabel sizeToFit];
    CGRect descriptionFrame = self.descriptionLabel.frame;
    descriptionFrame.origin.x = SCREEN_WIDTH/2 - self.descriptionLabel.frame.size.width/2;
    descriptionFrame.origin.y = self.addFollowersLabel.frame.origin.y + self.addFollowersLabel.frame.size.height + 7;
    self.descriptionLabel.frame = descriptionFrame;
    
    [self addSubview:self.descriptionLabel];
    
}

- (void) dealloc {
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
