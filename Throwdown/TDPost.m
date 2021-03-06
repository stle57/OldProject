//
//  Post.m
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPost.h"
#import "TDConstants.h"
#import "TDCurrentUser.h"
#import "TDViewControllerHelper.h"

static NSString *const kKindVideo = @"video";
static NSString *const kKindPhoto = @"photo";
static NSString *const kKindText  = @"text";

@interface TDPost ()

@property (nonatomic) NSArray *comments;

@end

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
    _unfollowed = [[dict objectForKey:@"unfollowed"] boolValue];
    _mutedUser = [[dict objectForKey:@"muted"] boolValue];
    _likers = [dict objectForKey:@"likers"];
    _unfollowers = [dict objectForKey:@"unfollow_posts"];
    _commentsTotalCount = [dict objectForKey:@"comment_count"];
    _likersTotalCount = [dict objectForKey:@"like_count"];
    _slug = [dict objectForKey:@"slug"];
    _personalRecord = [[dict objectForKey:@"personal_record"] boolValue];
    _updated = [[dict objectForKey:@"updated"] boolValue];

    if ([dict objectForKey:@"comment"] && ![[dict objectForKey:@"comment"] isEqual:[NSNull null]]) {
        _comment = [[dict objectForKey:@"comment"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([_comment length] == 0) {
            _comment = nil;
        }
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

    NSString * visibility = [NSString stringWithFormat:@"%@", [dict objectForKey:@"visibility"]];
    if ([visibility isEqualToString:@"public"]) {
        _visibility = TDPostPrivacyPublic;
    } else if ([visibility isEqualToString:@"hidden"]){
        _visibility = TDPostPrivacyPrivate;
    } else if ([visibility isEqualToString:@"direct"]){
        _visibility = TDPostSemiPrivate;
    }
    NSMutableArray *commentsArray = [NSMutableArray arrayWithCapacity:0];
    for (NSDictionary *commentsDict in [dict objectForKey:@"comments"]) {
        [commentsArray addObject:[[TDComment alloc] initWithDictionary:commentsDict]];
    }

    _comments = commentsArray;
    _locationId = [[dict objectForKey:@"location"] objectForKey:@"id"];
    _locationName = [[dict objectForKey:@"location"] objectForKey:@"name"];
}

- (void)addLikerUser:(TDUser *)likerUser {
    if (!self.liked) {
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
        _likersTotalCount = [NSNumber numberWithInt:([_likersTotalCount intValue] + 1)];
        _liked = YES;
    }
}

- (void)removeLikerUser:(TDUser *)likerUser {
    if (self.liked) {
        for (NSDictionary *likerDict in [NSArray arrayWithArray:self.likers]) {
            if ([[likerDict objectForKey:@"id"] isEqualToNumber:likerUser.userId]) {
                // Remove it
                NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.likers];
                [newArray removeObject:likerDict];
                _likers = newArray;
                _likersTotalCount = [NSNumber numberWithInt:([_likersTotalCount intValue] - 1)];
                break;
            }
        }
        _liked = NO;
    }
}

- (void)addUnfollowUser:(TDUser *)unfollowUser {
    if (!self.unfollowed) {
        NSMutableDictionary *unfollowDict = [NSMutableDictionary dictionaryWithCapacity:0];
        [unfollowDict setObject:unfollowUser.userId forKey:@"id"];
        [unfollowDict setObject:unfollowUser.username forKey:@"username"];
        [unfollowDict setObject:unfollowUser.name forKey:@"name"];
        if (unfollowUser.picture) {
            [unfollowDict setObject:unfollowUser.picture forKey:@"picture"];
        }
        NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.likers];
        [newArray addObject:unfollowDict];
        _unfollowers = newArray;
        _unfollowed = YES;
    }
}

- (void)removeUnfollowUser:(TDUser *)unfollowUser {
    if (self.unfollowed) {
        for (NSDictionary *unfollowDict in [NSArray arrayWithArray:self.unfollowers]) {
            if ([[unfollowDict objectForKey:@"id"] isEqualToNumber:unfollowUser.userId]) {
                // Remove it
                NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.unfollowers];
                [newArray removeObject:unfollowDict];
                _unfollowers = newArray;
                break;
            }
        }
        _unfollowed = NO;
    }
}

- (void)updatePostComment:(NSNumber*)postId comment:(NSString*)comment {
    if ([self.postId isEqualToNumber:postId]) {
        self.updated = YES;
        self.comment = comment;
    }
}

- (void)addComment:(TDComment *)newComment {
    if (newComment == nil) {
        return;
    }
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.comments];
    [newArray addObject:newComment];
    _comments = newArray;
    _commentsTotalCount = [NSNumber numberWithInt:[_commentsTotalCount intValue] + 1];
}

- (void)updateComment:(TDComment*)updateComment text:(NSString *)text{
    if (updateComment == nil) {
        return;
    }

    updateComment.body = text;

    NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.comments];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.body contains %@", text ];
    NSArray *data = [self.comments filteredArrayUsingPredicate:predicate];
    if (data) {
        NSUInteger index = [self.comments indexOfObject:data[0]];
        TDComment *comment = [self.comments objectAtIndex:index];
        comment.updated = YES;
        [newArray replaceObjectAtIndex:index withObject:comment];
    }
    _comments = newArray;
}

- (void)removeComment:(NSNumber *)commentId {
    if (commentId == nil) {
        return;
    }

    NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:self.comments];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.commentId = %@", commentId];
    NSArray *data = [self.comments filteredArrayUsingPredicate:predicate];
    if (data && data.count) {
        NSUInteger index = [newArray indexOfObject:data[0]];
        [newArray removeObjectAtIndex:index];

        _comments = newArray;
        _commentsTotalCount = [NSNumber numberWithInt:[_commentsTotalCount intValue] - 1];
    }
}

- (void)removeLastComment {
    if (_commentsTotalCount > 0) {
        NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.comments];
        [newArray removeObjectAtIndex:[self.comments count] - 1];
        _comments = newArray;
        _commentsTotalCount = [NSNumber numberWithInt:[_commentsTotalCount intValue] - 1];
    }
}

- (NSArray *)commentsForFeed {
    if (!self.comments || [self.comments count] == 0) {
        return @[];
    }
    if ([self.comments count] < 3) {
        return self.comments;
    }

    NSMutableArray *newList = [self.comments mutableCopy];
    // Only need the FIRST 2
    if ([newList count] > 2) {
        [newList removeObjectsInRange:NSMakeRange(2, [newList count] - 2)];
    }

    return [NSArray arrayWithArray:newList];
}

- (NSArray *)commentsForDetailView {
    if (!self.comments || [self.comments count] == 0) {
        return @[];
    }
    return self.comments;
}

- (TDComment *)findCommentById:(NSNumber*)commentId {
    if (self.comments && commentId) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.commentId = %@", commentId];
        NSArray *data = [self.comments filteredArrayUsingPredicate:predicate];
        if (data && data.count) {
            NSUInteger index = [self.comments indexOfObject:data[0]];
            return (TDComment*)[self.comments objectAtIndex:index];
        }
    }
    return nil;
}

- (TDComment *)commentAtIndex:(NSUInteger)index {
    if (self.comments && index < [self.comments count]) {
        return [self.comments objectAtIndex:index];
    }
    return nil;
}

- (void)sortComments {
    NSMutableArray *sortingArray = [self.comments mutableCopy];
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    [sortingArray sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    self.comments = [NSArray arrayWithArray:sortingArray];
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

- (void)updateFromNotification:(NSNotification *)n {
    NSUInteger change = [(NSNumber *)[n.userInfo objectForKey:@"change"] unsignedIntegerValue];
    switch (change) {
        case kUpdatePostTypeLike:
            [self addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
            break;
        case kUpdatePostTypeUnlike:
            [self removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
            break;
        case kUpdatePostTypeAddComment:
            [self addComment:[[TDComment alloc] initWithDictionary:[n.userInfo objectForKey:@"comment"]]];
            break;
        case kUpdatePostTypeUpdateComment:
        {
            TDComment *comment = [self findCommentById:[n.userInfo objectForKey:@"commentId"]];
            [self updateComment:comment text:[n.userInfo objectForKey:@"comment"]];
        }
        break;
        case kUpdatePostTypeUpdatePostComment:
        {
            [self updatePostComment:[n.userInfo objectForKey:@"postId"] comment:[n.userInfo objectForKey:@"comment"]];
        }
        break;
    }
}

- (void)updateUserInfoFor:(TDUser *)newUser {
    if ([self.user.userId isEqualToNumber:newUser.userId]) {
        [self replaceUser:newUser];
    }

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
            if (newUser.location) {
                [newLiker setObject:newUser.location forKey:@"location"];
            } else {
                [newLiker setObject:@"" forKey:@"location"];
            }
            if (newUser.followingCount) {
                [newLiker setObject:newUser.followingCount forKey:@"following_count"];
            } else {
                [newLiker setObject:@"" forKey:@"following_count"];

            }
            if (newUser.followerCount) {
                [newLiker setObject:newUser.followerCount forKey:@"follower_count"];
            } else {
                [newLiker setObject:@"" forKey:@"follower_count"];
                
            }
            if (newUser.prCount) {
                [newLiker setObject:newUser.prCount forKey:@"pr_count"];
            } else {
                [newLiker setObject:@"" forKey:@"pr_count"];
                
            }
            if (newUser.postCount) {
                [newLiker setObject:newUser.postCount forKey:@"post_count"];
            } else {
                [newLiker setObject:@"" forKey:@"post_count"];
                
            }
            
            [newLikers replaceObjectAtIndex:[newLikers indexOfObject:liker] withObject:newLiker];
            newLiker = nil;
        }
    }
    [self replaceLikers:newLikers];
    newLikers = nil;

    for (TDComment *comment in [NSArray arrayWithArray:self.comments]) {
        if ([comment.user.userId isEqualToNumber:newUser.userId]) {
            [comment replaceUser:newUser];
        }
    }
}

@end
