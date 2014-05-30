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
    NSArray *users;
    if ([@"comment" isEqualToString:[activity objectForKey:@"action"]]) {
        NSString *body = [[activity objectForKey:@"comment"] objectForKey:@"body"];
        if ([body length] + [username length] > kMaxCommentLength) {
            body = [[body substringToIndex:(kMaxCommentLength - [username length])] stringByAppendingString:@"…"];
        }
        users = [[activity objectForKey:@"comment"] objectForKey:@"mentions"];
        text = [NSString stringWithFormat:@"%@ said: \"%@\"",
                                          username,
                                          body];
    } else if ([@"like" isEqualToString:[activity objectForKey:@"action"]]) {
        text = [NSString stringWithFormat:@"%@ liked your post", username];
    }
    // adding timestamp to label to center properly
    text = [NSString stringWithFormat:@"%@\n%@", text, createdAtText];

    [self.activityLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    if (users) {
        [TDViewControllerHelper linkUsernamesInLabel:self.activityLabel users:users];
    }

    NSMutableAttributedString *mutableAttributedString = [self.activityLabel.attributedText mutableCopy];

    // Link and bold the initial username
    [TDViewControllerHelper linkUsernamesInLabel:self.activityLabel users:@[user] pattern:@"(^\\w+\\b)"];
    NSDictionary *userAttributes = @{ NSForegroundColorAttributeName:[TDConstants brandingRedColor], NSFontAttributeName: [TDConstants fontBoldSized:COMMENT_MESSAGE_FONT_SIZE] };
    [mutableAttributedString addAttributes:userAttributes range:NSMakeRange(0, [username length])];

    // Give timestamp right attributes
    NSDictionary *timeAttributes = @{NSForegroundColorAttributeName:[TDConstants commentTimeTextColor], NSFontAttributeName: TIME_FONT };
    NSUInteger strLength = [[mutableAttributedString string] length];
    [mutableAttributedString addAttributes:timeAttributes range:NSMakeRange(strLength - [createdAtText length], [createdAtText length])];

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
    if (self.delegate && [self.delegate respondsToSelector:@selector(userProfilePressedWithId:)]) {
        [self.delegate userProfilePressedWithId:[NSNumber numberWithInteger:[[url path] integerValue]]];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(activityPressedFromRow:)]) {
        [self.delegate activityPressedFromRow:[NSNumber numberWithInteger:self.row]];
    }
}


@end
