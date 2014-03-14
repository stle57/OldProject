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

@interface TDPost : NSObject

@property (strong, nonatomic, readonly) NSNumber *postId;
@property (nonatomic, copy, readonly) NSString *filename;
@property (nonatomic, readonly) TDUser *user;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic, assign) BOOL liked;
@property (strong, nonatomic, readonly) NSArray *likers;
@property (strong, nonatomic, readonly) NSArray *comments;

- (id)initWithDictionary:(NSDictionary *)dict;
-(void)loadUpFromDict:(NSDictionary *)dict;
- (NSDictionary *)jsonRepresentation;
+ (NSDate *)dateForRFC3339DateTimeString:(NSString *)rfc3339DateTimeString;
-(void)addLikerUser:(TDUser *)likerUser;
-(void)removeLikerUser:(TDUser *)likerUser;
-(void)addComment:(TDComment *)newComment;
-(void)orderCommentsForHomeScreen;
-(void)orderCommentsForDetailsScreen;
@end
