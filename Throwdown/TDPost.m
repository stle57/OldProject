//
//  Post.m
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPost.h"

@implementation TDPost

/*
 
 "comment_count" = 0;
 comments =     (
 );
 "created_at" = "2014-02-26T05:15:41.000Z";
 filename = "6_1393391740.356891";
 id = 17;
 "like_count" = 0;
 liked = 0;
 likers =     (
 );
 user =     {
    id = 6;
    name = "Joseph Huang";
    username = jh;
 };
 }

 */


- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self)
    {
        _postId   = [dict objectForKey:@"id"];
        _user = [[TDUser alloc] initWithDictionary:[dict objectForKey:@"user"]];
        _filename = [dict objectForKey:@"filename"];
        _createdAt = [TDPost dateForRFC3339DateTimeString:[dict objectForKey:@"created_at"]];
        _liked = [[dict objectForKey:@"liked"] boolValue];
        _likers = [dict objectForKey:@"likers"];
        _comments = [dict objectForKey:@"comments"];
    }
    return self;
}

- (NSDictionary *)jsonRepresentation
{
    return @{ @"filename": self.filename };
}

+ (NSDate *)dateForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString {

	NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];

	[rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
	[rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

	// Convert the RFC 3339 date time string to an NSDate.
	NSDate *result = [rfc3339DateFormatter dateFromString:rfc3339DateTimeString];
	return result;
}

@end
