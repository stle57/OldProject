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

@implementation TDComment

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        _commentId = [dict objectForKey:@"id"];
        _body = [dict objectForKey:@"body"];
        _createdAt = [TDPost dateForRFC3339DateTimeString:[dict objectForKey:@"created_at"]];
        _user = [[TDUser alloc] initWithDictionary:[dict objectForKey:@"user"]];
        [self figureOutMessageLabelHeightForThisMessage:_body];
    }
    return self;
}

-(void)figureOutMessageLabelHeightForThisMessage:(NSString *)text
{
    _messageHeight = [TDAppDelegate heightOfTextForString:text
                                                  andFont:COMMENT_MESSAGE_FONT
                                                  maxSize:CGSizeMake(COMMENT_MESSAGE_WIDTH, MAXFLOAT)];
}

@end
