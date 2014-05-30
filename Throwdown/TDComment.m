//
//  TDComment.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDComment.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"
#import "TDPost.h"
#import "TDViewControllerHelper.h"

@implementation TDComment

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self loadFromDict:dict];
        _user = [[TDUser alloc] initWithDictionary:[dict objectForKey:@"user"]];
    }
    return self;
}

- (void)user:(TDUser *)user dict:(NSDictionary *)commentDict {
    _user = user;
    [self loadFromDict:commentDict];
}

- (void)loadFromDict:(NSDictionary *)dict {
    _commentId = [dict objectForKey:@"id"];
    _body = [dict objectForKey:@"body"];
    _mentions = [dict objectForKey:@"mentions"];
    _createdAt = [TDViewControllerHelper dateForRFC3339DateTimeString:[dict objectForKey:@"created_at"]];
    [self figureOutMessageLabelHeightForThisMessage:_body];
}

- (void)figureOutMessageLabelHeightForThisMessage:(NSString *)text {

    // Slow but the most accurate way to calculate the size
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, COMMENT_MESSAGE_WIDTH, 18)];
    label.font = COMMENT_MESSAGE_FONT;
    label.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:nil];
    [TDViewControllerHelper linkUsernamesInLabel:label users:_mentions];
    label.attributedText = [TDViewControllerHelper makeParagraphedTextWithAttributedString:label.attributedText];
    label.numberOfLines = 0;

    CGSize size = [label sizeThatFits:CGSizeMake(COMMENT_MESSAGE_WIDTH, MAXFLOAT)];
    _messageHeight = size.height;
}

- (void)replaceUser:(TDUser *)newUser {
    _user = newUser;
}

@end
