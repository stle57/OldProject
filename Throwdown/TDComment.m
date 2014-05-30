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
        [self figureOutMessageLabelHeightForThisMessage:_body];
    }
    return self;
}

- (void)user:(TDUser *)user dict:(NSDictionary *)commentDict {
    _user = user;
    [self loadFromDict:commentDict];
    [self figureOutMessageLabelHeightForThisMessage:_body];
}

- (void)loadFromDict:(NSDictionary *)dict {
    _commentId = [dict objectForKey:@"id"];
    _body = [dict objectForKey:@"body"];
    _mentions = [dict objectForKey:@"mentions"];
    _createdAt = [TDViewControllerHelper dateForRFC3339DateTimeString:[dict objectForKey:@"created_at"]];
}

- (void)figureOutMessageLabelHeightForThisMessage:(NSString *)text {
    _messageHeight = [TDAppDelegate heightOfTextForString:text
                                                  andFont:COMMENT_MESSAGE_FONT
                                                  maxSize:CGSizeMake(COMMENT_MESSAGE_WIDTH, MAXFLOAT)];
}

- (void)replaceUser:(TDUser *)newUser {
    _user = newUser;
}

@end
