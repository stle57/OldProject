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

static NSString *const kUsernameAttribute = @"username";
static NSUInteger const kMaxCommentLength = 50;

@interface TDActivitiesCell () <TTTAttributedLabelDelegate>

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;

@end

@implementation TDActivitiesCell

- (void)awakeFromNib {
    self.activityLabel.font = COMMENT_MESSAGE_FONT;
    self.activityLabel.linkAttributes = nil;
    self.activityLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.activityLabel.numberOfLines = 3;
    self.activityLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    self.activityLabel.delegate = self;
    self.activityLabel.lineHeightMultiple = 1 - TDTextLineHeight;

    self.timeLabel.font    = TIME_FONT;
}

- (void)setActivity:(NSDictionary *)activity {
    _activity = activity;

    NSDictionary *post = (NSDictionary *)[activity objectForKey:@"post"];
    NSDictionary *user = (NSDictionary *)[activity objectForKey:@"user"];
    NSString *username = [user objectForKey:@"username"];
    NSString *createdAtText  = [[TDViewControllerHelper dateForRFC3339DateTimeString:[activity objectForKey:@"created_at"]] timeAgo];

    [self.previewImage setImage:nil];
    [[TDAPIClient sharedInstance] setImage:@{@"imageView":self.previewImage,
                                             @"filename":[[post objectForKey:@"filename"] stringByAppendingString:FTImage],
                                             @"width":@54,
                                             @"height":@54}];

    NSString *text;
    if ([@"comment" isEqualToString:[activity objectForKey:@"action"]]) {
        NSString *body = [[activity objectForKey:@"comment"] objectForKey:@"body"];
        if ([body length] + [username length] > kMaxCommentLength) {
            body = [[body substringToIndex:(kMaxCommentLength - [username length])] stringByAppendingString:@"…"];
        }
        text = [NSString stringWithFormat:@"%@ said: \"%@\"",
                                          username,
                                          body];
    } else if ([@"like" isEqualToString:[activity objectForKey:@"action"]]) {
        text = [NSString stringWithFormat:@"%@ liked your post", username];
    }
    // adding timestamp to label to center properly
    text = [NSString stringWithFormat:@"%@\n%@", text, createdAtText];

    [TDViewControllerHelper linkUsernamesInLabel:self.activityLabel text:text users:@[[user copy]] pattern:@"(^\\w+\\b)" fontSize:16];

    NSDictionary *timeAttributes = @{NSForegroundColorAttributeName:[TDConstants commentTimeTextColor],
                                                NSFontAttributeName: TIME_FONT };

    // Give timestamp right attributes
    NSMutableAttributedString *mutableAttributedString = [self.activityLabel.attributedText mutableCopy];
    NSString *pattern = [NSString stringWithFormat:@"(%@)$", createdAtText];
    NSRegularExpression *timeRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:nil];
    NSRange range = [timeRegex rangeOfFirstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    [mutableAttributedString addAttributes:timeAttributes range:range];
    self.activityLabel.attributedText = mutableAttributedString;

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
    if (self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedFromRow:)]) {
        [self.delegate userProfilePressedFromRow:self.row];
    }
}


@end
