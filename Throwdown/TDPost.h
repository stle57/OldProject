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

typedef enum {
    TDPostKindUnknown,
    TDPostKindVideo,
    TDPostKindPhoto
} TDPostKind;


@interface TDPost : NSObject

@property (strong, nonatomic, readonly) NSNumber *postId;
@property (nonatomic, copy, readonly) NSString *filename;
@property (nonatomic, copy, readonly) NSString *slug;
@property (nonatomic, readonly) TDPostKind kind;
@property (nonatomic, readonly) TDUser *user;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic, assign) BOOL liked;
@property (strong, nonatomic, readonly) NSArray *likers;
@property (strong, nonatomic, readonly) NSArray *comments;
@property (strong, nonatomic, readonly) NSNumber *commentsTotalCount;
@property (strong, nonatomic, readonly) NSNumber *likersTotalCount;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)loadUpFromDict:(NSDictionary *)dict;
- (void)addLikerUser:(TDUser *)likerUser;
- (void)removeLikerUser:(TDUser *)likerUser;
- (void)addComment:(TDComment *)newComment;
- (void)removeLastComment;
- (void)orderCommentsForHomeScreen;
- (void)orderCommentsForDetailsScreen;
- (void)replaceUser:(TDUser *)newUser;
- (void)replaceLikers:(NSArray *)newLikers;
- (void)replaceComments:(NSArray *)newComments;
- (void)replaceUserAndLikesAndCommentsWithUser:(TDUser *)newUser;
@end
