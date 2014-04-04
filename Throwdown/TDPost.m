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
        [self loadUpFromDict:dict];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Post id:%@\ncomments:%@\nlikers:%@\nLiked:%d", self.postId, self.comments, self.likers, self.liked];
}

-(void)loadUpFromDict:(NSDictionary *)dict
{
    _postId   = [dict objectForKey:@"id"];
    _user = [[TDUser alloc] initWithDictionary:[dict objectForKey:@"user"]];
    _filename = [dict objectForKey:@"filename"];
    _createdAt = [TDPost dateForRFC3339DateTimeString:[dict objectForKey:@"created_at"]];
    _liked = [[dict objectForKey:@"liked"] boolValue];
    _likers = [dict objectForKey:@"likers"];
    _commentsTotalCount = [dict objectForKey:@"comment_count"];
    _likersTotalCount = [dict objectForKey:@"like_count"];

    TDComment *comment = nil;
    NSMutableArray *commentsArray = [NSMutableArray arrayWithCapacity:0];
    for (NSDictionary *commentsDict in [dict objectForKey:@"comments"]) {
        comment = [[TDComment alloc] initWithDictionary:commentsDict];
        [commentsArray addObject:comment];
        comment = nil;
    }

    _comments = commentsArray;
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

-(void)addLikerUser:(TDUser *)likerUser
{
    NSMutableDictionary *likerDict = [NSMutableDictionary dictionaryWithCapacity:0];
    [likerDict setObject:likerUser.userId forKey:@"id"];
    [likerDict setObject:likerUser.username forKey:@"username"];
    [likerDict setObject:likerUser.name forKey:@"name"];
    if (likerUser.picture) {
        [likerDict setObject:likerUser.picture forKey:@"picture"];
    }
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.likers];
    [newArray addObject:likerDict];
    _likers = newArray;
    _likersTotalCount = [NSNumber numberWithInteger:[newArray count]];

    // Assume it's current user
    _liked = YES;
}

-(void)removeLikerUser:(TDUser *)likerUser
{
    for (NSDictionary *likerDict in [NSArray arrayWithArray:self.likers]) {
        if ([[likerDict objectForKey:@"id"] isEqualToNumber:likerUser.userId]) {
            // Remove it
            NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.likers];
            [newArray removeObject:likerDict];
            _likers = newArray;
            _likersTotalCount = [NSNumber numberWithInteger:[newArray count]];
            break;
        }
    }

    // Assume it's current user
    _liked = NO;
}

-(void)addComment:(TDComment *)newComment
{
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.comments];
    [newArray addObject:newComment];
    _comments = newArray;
    _commentsTotalCount = [NSNumber numberWithInt:[_commentsTotalCount intValue] + 1];
}

-(void)orderCommentsForHomeScreen
{
    NSMutableArray *sortingArray = [self.comments mutableCopy];

    // Sort by dates - newest on bottom
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                               ascending:YES];
    [sortingArray sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];

    // Only need the FIRST 2, including original comment on top
    if ([sortingArray count] > 2) {
        [sortingArray removeObjectsInRange:NSMakeRange(2, [sortingArray count]-2)];
    }
    _comments = [NSArray arrayWithArray:sortingArray];
}

-(void)orderCommentsForDetailsScreen
{
    NSMutableArray *sortingArray = [self.comments mutableCopy];

    // Sort by dates - newest on bottom
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                               ascending:YES];
    [sortingArray sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    _comments = [NSArray arrayWithArray:sortingArray];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        TDPost *otherPost = (TDPost *)other;
        return [self.postId isEqualToNumber:otherPost.postId];
    }
}

@end
