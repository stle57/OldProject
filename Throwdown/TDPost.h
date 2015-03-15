//
//  Post.h
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUser.h"
#import "TDComment.h"
#import "TDConstants.h"

typedef enum {
    TDPostKindUnknown,
    TDPostKindVideo,
    TDPostKindPhoto,
    TDPostKindText
} TDPostKind;


@interface TDPost : NSObject

@property (nonatomic, readonly) NSNumber *postId;
@property (nonatomic, copy, readonly) NSString *filename;
@property (nonatomic, copy, readonly) NSString *slug;
@property (nonatomic, copy, readonly) NSString *comment;
@property (nonatomic, readonly) TDPostKind kind;
@property (nonatomic, readonly) TDUser *user;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic, assign) BOOL personalRecord;
@property (nonatomic, assign) BOOL liked;
@property (nonatomic, assign) BOOL unfollowed;
@property (nonatomic, assign) BOOL mutedUser;
@property (nonatomic, readonly) TDPostPrivacy visibility;
@property (nonatomic, copy, readonly) NSArray *mentions;
@property (nonatomic, readonly) NSArray *likers;
@property (nonatomic, readonly) NSArray *unfollowers;
@property (nonatomic, readonly) NSNumber *commentsTotalCount;
@property (nonatomic, readonly) NSNumber *likersTotalCount;
@property (nonatomic, readonly) NSNumber *locationId;
@property (nonatomic, readonly) NSString *locationName;

- (id)initWithDictionary:(NSDictionary *)dict;

- (NSArray *)commentsForFeed;
- (NSArray *)commentsForDetailView;
- (TDComment *)commentAtIndex:(NSUInteger)index;

- (void)loadUpFromDict:(NSDictionary *)dict;
- (void)addLikerUser:(TDUser *)likerUser;
- (void)removeLikerUser:(TDUser *)likerUser;
- (void)addUnfollowUser:(TDUser *)unfollowUser;
- (void)removeUnfollowUser:(TDUser *)unfollowUser;
- (void)addComment:(TDComment *)newComment;
- (void)removeLastComment;
- (void)replaceUser:(TDUser *)newUser;
- (void)replaceLikers:(NSArray *)newLikers;
- (void)updateFromNotification:(NSNotification *)n;
- (void)updateUserInfoFor:(TDUser *)newUser;
@end
