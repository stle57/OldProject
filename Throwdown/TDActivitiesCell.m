//
//  TDActivitiesCell.m
//  Throwdown
//
//  Created by Andrew C on 4/14/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDActivitiesCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "NSDate+TimeAgo.h"
#import "TDAPIClient.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const kCommentWidthWithPreview = 248.;
static CGFloat const kCommentWidthNoPreview = 306.;

@interface TDActivitiesCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;

@end

@implementation TDActivitiesCell

- (void)awakeFromNib {
    self.activityLabel.font = COMMENT_MESSAGE_FONT;
    self.activityLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.activityLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.activityLabel.delegate = self;
    self.activityLabel.numberOfLines = 2;

    self.timeLabel.font = TIME_FONT;
}

- (void)setActivity:(NSDictionary *)activity {
    _activity = activity;

    self.timeLabel.text = [[TDViewControllerHelper dateForRFC3339DateTimeString:[activity objectForKey:@"created_at"]] timeAgo];

    NSDictionary *post = (NSDictionary *)[activity objectForKey:@"post"];
    NSDictionary *user = (NSDictionary *)[activity objectForKey:@"user"];
    NSString *username = [user objectForKey:@"username"];

    [self.previewImage setImage:nil];
    if ([[post objectForKey:@"filename"] isEqual:[NSNull null]]) {
        self.previewImage.hidden = YES;
    } else {
        self.previewImage.hidden = NO;
        [[TDAPIClient sharedInstance] setImage:@{@"imageView":self.previewImage,
                                                 @"filename":[[post objectForKey:@"filename"] stringByAppendingString:FTImage],
                                                 @"width":@54,
                                                 @"height":@54}];
    }

    NSString *text;
    NSArray *users;
    if ([@"comment" isEqualToString:[activity objectForKey:@"action"]]) {
        NSString *body = [[activity objectForKey:@"comment"] objectForKey:@"body"];
        users = [[activity objectForKey:@"comment"] objectForKey:@"mentions"];
        text = [NSString stringWithFormat:@"%@ said: \"%@\"", username, body];
    } else if ([@"like" isEqualToString:[activity objectForKey:@"action"]]) {
        text = [NSString stringWithFormat:@"%@ liked your post", username];
    } else if ([@"activity" isEqualToString:[activity objectForKey:@"action"]]) {
        users = [activity objectForKey:@"mentions"];
        text = [activity objectForKey:@"text"];
    }

    if (text) {
        [self.activityLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
        if (users) {
            [TDViewControllerHelper linkUsernamesInLabel:self.activityLabel users:users];
        }

        // Link and bold the initial username
        NSMutableAttributedString *mutableAttributedString = [self.activityLabel.attributedText mutableCopy];
        [TDViewControllerHelper linkUsernamesInLabel:self.activityLabel users:@[user] pattern:@"(^\\w+\\b)"];
        NSDictionary *userAttributes = @{ NSForegroundColorAttributeName:[TDConstants brandingRedColor], NSFontAttributeName: [TDConstants fontBoldSized:COMMENT_MESSAGE_FONT_SIZE] };
        [mutableAttributedString addAttributes:userAttributes range:NSMakeRange(0, [username length])];
        self.activityLabel.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:mutableAttributedString withMultiple:1.f];
    }

    CGSize labelSize = [self.activityLabel sizeThatFits:CGSizeMake(self.previewImage.hidden ? kCommentWidthNoPreview : kCommentWidthWithPreview, MAXFLOAT)];
    CGSize timeSize  = self.timeLabel.frame.size;
    labelSize.height = labelSize.height + 7;

    int y = (self.contentView.frame.size.height - (labelSize.height + timeSize.height)) / 2;
    CGRect labelFrame = CGRectMake(7, y, labelSize.width, labelSize.height);
    self.activityLabel.frame = labelFrame;

    y = y + labelSize.height;
    if (labelSize.height <= 43) {
        y -= 4;
    }
    CGRect timeFrame = CGRectMake(7, y, timeSize.width, timeSize.height);
    self.timeLabel.frame = timeFrame;


    // Background
    if ([activity objectForKey:@"unseen"]) {
        if ([[activity objectForKey:@"unseen"] boolValue]) {
            self.contentView.backgroundColor = [TDConstants activityUnseenColor];
        } else {
            self.contentView.backgroundColor = [UIColor whiteColor];
        }
    }
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if (self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedWithId:)]) {
        [self.delegate userProfilePressedWithId:[NSNumber numberWithInteger:[[url path] integerValue]]];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(activityPressedFromRow:)]) {
        [self.delegate activityPressedFromRow:[NSNumber numberWithInteger:self.row]];
    }
}


@end
