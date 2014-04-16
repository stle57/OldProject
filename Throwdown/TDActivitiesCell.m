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

static NSString *const kUsernameAttribute = @"username";

@interface TDActivitiesCell ()

@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UITextView *activityText;

@end

@implementation TDActivitiesCell

- (void)awakeFromNib {
    self.activityText.font = [TDConstants fontRegularSized:14.0];
    self.timeLabel.font = [TDConstants fontLightSized:12.0];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTapped:)];
    [self.activityText addGestureRecognizer:tap];
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.previewImage addGestureRecognizer:tap];
}

- (void)dealloc {
    for (UIGestureRecognizer *gr in self.activityText.gestureRecognizers) {
        [self.activityText removeGestureRecognizer:gr];
    }
    for (UIGestureRecognizer *gr in self.previewImage.gestureRecognizers) {
        [self.previewImage removeGestureRecognizer:gr];
    }
}

- (void)setActivity:(NSDictionary *)activity {
    _activity = activity;

    NSDictionary *post = (NSDictionary *)[activity objectForKey:@"post"];
    NSDictionary *user = (NSDictionary *)[activity objectForKey:@"user"];
    NSString *username = [user objectForKey:@"username"];

    NSDate *createdAt  = [TDViewControllerHelper dateForRFC3339DateTimeString:[activity objectForKey:@"created_at"]];
    self.timeLabel.text = [createdAt timeAgo];

    // TODO: scale the image properly
    [self.previewImage setImage:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDDownloadPreviewImageNotification
                                                        object:self
                                                      userInfo:@{@"imageView":self.previewImage, @"filename":[post objectForKey:@"filename"]}];

    NSString *text;
    if ([@"comment" isEqualToString:[activity objectForKey:@"action"]]) {
        text = [NSString stringWithFormat:@"%@ said: %@",
                                          username,
                                          [[activity objectForKey:@"comment"] objectForKey:@"body"]];
    } else if ([@"like" isEqualToString:[activity objectForKey:@"action"]]) {
        text = [NSString stringWithFormat:@"%@ liked your post", username];
    }

    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange range = NSMakeRange(0, username.length);
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName: [TDConstants brandingRedColor],
                                 NSFontAttributeName: [TDConstants fontBoldSized:14.0],
                                 kUsernameAttribute: @1
                                 };
    [mutableAttributedString addAttributes:attributes range:range];
    self.activityText.attributedText = mutableAttributedString;
}


- (void)imageTapped:(UITapGestureRecognizer *)recognizer {
    if ([self.delegate respondsToSelector:@selector(postPressedFromRow:)]) {
        [self.delegate postPressedFromRow:self.row];
    }
}

- (void)textTapped:(UITapGestureRecognizer *)recognizer {
    UITextView *textView = (UITextView *)recognizer.view;

    // Location of the tap in text-container coordinates
    NSLayoutManager *layoutManager = textView.layoutManager;
    CGPoint location = [recognizer locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;

    // Find the character that's been tapped on
    NSUInteger characterIndex;
    characterIndex = [layoutManager characterIndexForPoint:location
                                           inTextContainer:textView.textContainer
                  fractionOfDistanceBetweenInsertionPoints:NULL];

    if (characterIndex < textView.textStorage.length) {
        NSRange range;
        NSDictionary *attributes = [textView.textStorage attributesAtIndex:characterIndex effectiveRange:&range];
        if ([attributes objectForKey:kUsernameAttribute] && self.delegate) {
            if ([self.delegate respondsToSelector:@selector(userProfilePressedFromRow:)]) {
                [self.delegate userProfilePressedFromRow:self.row];
            }
        }
    }
}

@end
