//
//  Post.m
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPost.h"
#import "TDViewControllerHelper.h"

static NSString *const kKindVideo = @"video";
static NSString *const kKindPhoto = @"photo";
static NSString *const kKindText  = @"text";

@implementation TDPost

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self loadUpFromDict:dict];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Post id:%@\nUser:%@\ncomments:%@\nlikers:%@\nLiked:%d", self.postId, self.user, self.comments, self.likers, self.liked];
}

- (void)loadUpFromDict:(NSDictionary *)dict {
    _postId   = [dict objectForKey:@"id"];
    _user = [[TDUser alloc] initWithDictionary:[dict objectForKey:@"user"]];
    if ([dict objectForKey:@"filename"] && ![[dict objectForKey:@"filename"] isEqual:[NSNull null]]) {
        _filename = [dict objectForKey:@"filename"];
    }
    _createdAt = [TDViewControllerHelper dateForRFC3339DateTimeString:[dict objectForKey:@"created_at"]];
    _liked = [[dict objectForKey:@"liked"] boolValue];
    _likers = [dict objectForKey:@"likers"];
    _commentsTotalCount = [dict objectForKey:@"comment_count"];
    _likersTotalCount = [dict objectForKey:@"like_count"];
    _slug = [dict objectForKey:@"slug"];
    _personalRecord = [[dict objectForKey:@"personal_record"] boolValue];
    _isPrivate = [[dict objectForKey:@"private"] boolValue];
    if ([dict objectForKey:@"comment"] && ![[dict objectForKey:@"comment"] isEqual:[NSNull null]]) {
        _comment = [[dict objectForKey:@"comment"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    _mentions = [dict objectForKey:@"mentions"];

    // Covers NSNull cases
    NSString *kind = [NSString stringWithFormat:@"%@", [dict objectForKey:@"kind"]];
    if ([kind isEqualToString:kKindPhoto]) {
        _kind = TDPostKindPhoto;
    } else if ([kind isEqualToString:kKindVideo]) {
        _kind = TDPostKindVideo;
    } else if ([kind isEqualToString:kKindText]) {
        _kind = TDPostKindText;
    }

    TDComment *comment = nil;
    NSMutableArray *commentsArray = [NSMutableArray arrayWithCapacity:0];
    for (NSDictionary *commentsDict in [dict objectForKey:@"comments"]) {
        comment = [[TDComment alloc] initWithDictionary:commentsDict];
        [commentsArray addObject:comment];
        comment = nil;
    }

    _comments = commentsArray;
}

- (void)addLikerUser:(TDUser *)likerUser {
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

- (void)removeLikerUser:(TDUser *)likerUser {
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

- (void)addComment:(TDComment *)newComment {
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.comments];
    [newArray addObject:newComment];
    _comments = newArray;
    _commentsTotalCount = [NSNumber numberWithInt:[_commentsTotalCount intValue] + 1];
}

- (void)removeLastComment {
    if (_commentsTotalCount > 0) {
        NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.comments];
        [newArray removeObjectAtIndex:[self.comments count] - 1];
        _comments = newArray;
        _commentsTotalCount = [NSNumber numberWithInt:[_commentsTotalCount intValue] - 1];
    }
}

- (void)orderCommentsForHomeScreen {
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

- (void)orderCommentsForDetailsScreen {
    NSMutableArray *sortingArray = [self.comments mutableCopy];

    // Sort by dates - newest on bottom
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                               ascending:YES];
    [sortingArray sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    _comments = [NSArray arrayWithArray:sortingArray];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        TDPost *otherPost = (TDPost *)other;
        return [self.postId isEqualToNumber:otherPost.postId];
    }
}

- (void)replaceUser:(TDUser *)newUser {
    _user = newUser;
}

- (void)replaceLikers:(NSArray *)newLikers {
    _likers = newLikers;
}

- (void)replaceComments:(NSArray *)newComments {
    _comments = newComments;
}

- (void)replaceUserAndLikesAndCommentsWithUser:(TDUser *)newUser {
    // User
    [self replaceUser:newUser];

    // Likers
    NSMutableArray *newLikers = [NSMutableArray arrayWithArray:self.likers];
    for (NSDictionary *liker in [NSArray arrayWithArray:self.likers]) {
        if ([liker objectForKey:@"id"] && [[liker objectForKey:@"id"] isEqualToNumber:newUser.userId]) {
            NSMutableDictionary *newLiker = [NSMutableDictionary dictionaryWithDictionary:liker];
            if (newUser.bio) {
                [newLiker setObject:newUser.bio forKey:@"bio"];
            } else {
                [newLiker setObject:@"" forKey:@"bio"];
            }
            if (newUser.name) {
                [newLiker setObject:newUser.name forKey:@"name"];
            } else {
                [newLiker setObject:@"" forKey:@"name"];
            }
            if (newUser.picture) {
                [newLiker setObject:newUser.picture forKey:@"picture"];
            } else {
                [newLiker setObject:@"" forKey:@"picture"];
            }
            if (newUser.username) {
                [newLiker setObject:newUser.username forKey:@"username"];
            } else {
                [newLiker setObject:@"" forKey:@"username"];
            }
            [newLikers replaceObjectAtIndex:[newLikers indexOfObject:liker] withObject:newLiker];
            newLiker = nil;
        }
    }
    [self replaceLikers:newLikers];
    newLikers = nil;

    // Comments
    for (TDComment *comment in [NSArray arrayWithArray:self.comments]) {
        if ([comment.user.userId isEqualToNumber:newUser.userId]) {
            // User
            [comment replaceUser:newUser];
        }
    }

}

@end
