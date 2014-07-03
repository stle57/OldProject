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

- (id)initWithUser:(TDUser *)user body:(NSString *)body createdAt:(NSDate *)date {
    self = [super init];
    if (self) {
        _user = user;
        _body = body;
        _mentions = @[];
        _createdAt = date;
        _messageHeight = [TDViewControllerHelper heightForComment:_body withMentions:_mentions];
    }
    return self;
}

- (void)loadFromDict:(NSDictionary *)dict {
    _commentId = [dict objectForKey:@"id"];
    _body = [dict objectForKey:@"body"];
    _mentions = [dict objectForKey:@"mentions"];
    _createdAt = [TDViewControllerHelper dateForRFC3339DateTimeString:[dict objectForKey:@"created_at"]];
    _messageHeight = [TDViewControllerHelper heightForComment:_body withMentions:_mentions];
}

- (void)replaceUser:(TDUser *)newUser {
    _user = newUser;
}

@end
