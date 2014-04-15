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

@interface TDActivitiesCell ()

@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;

@end

@implementation TDActivitiesCell

- (void)awakeFromNib {
    self.activityLabel.font = [TDConstants fontRegularSized:14.0];
    self.timeLabel.font = [TDConstants fontLightSized:12.0];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textTapped:)];
    [self.activityLabel addGestureRecognizer:tap];
}

- (void)dealloc {
    for (UIGestureRecognizer *gr in self.activityLabel.gestureRecognizers) {
        [self.activityLabel removeGestureRecognizer:gr];
    }
}

- (void)setActivity:(NSDictionary *)activity {
    _activity = activity;

    NSDictionary *post = (NSDictionary *)[activity objectForKey:@"post"];
    NSDictionary *user = (NSDictionary *)[activity objectForKey:@"user"];
    NSString *username = [user objectForKey:@"username"];

    NSDate *createdAt  = [TDViewControllerHelper dateForRFC3339DateTimeString:[activity objectForKey:@"created_at"]];
    self.timeLabel.text = [createdAt timeAgo];

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
                                 @"username": @(YES)
                                 };
    [mutableAttributedString addAttributes:attributes range:range];
    self.activityLabel.attributedText = mutableAttributedString;
}

- (void)textTapped:(UITapGestureRecognizer *)recognizer
{
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
        id value = [textView.attributedText attribute:@"username" atIndex:characterIndex effectiveRange:&range];

        // Handle as required...

        NSLog(@"%@, %d, %d", value, range.location, range.length);

    }
}


@end
