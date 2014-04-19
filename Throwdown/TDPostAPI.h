//
//  PostAPI.h
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDPost.h"
#import "TDCurrentUser.h"

@interface TDPostAPI : NSObject

+ (TDPostAPI *)sharedInstance;
+ (NSString *)createUploadFileNameFor:(TDCurrentUser *)user;

- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath withName:(NSString *)newName;
- (void)addPost:(NSString *)filename comment:(NSString *)comment success:(void (^)(void))success failure:(void (^)(void))failure;
- (void)saveImage:(UIImage*)image filename:(NSString*)filename;
- (void)fetchPostsUpstream;
- (BOOL)fetchPostsDownstream;
- (NSNumber *)lowestIdOfPosts;
- (void)fetchPostsUpstreamWithErrorHandlerStart:(NSNumber *)start error:(void (^)(void))errorHandler;
- (NSArray *)getPosts;
- (void)likePostWithId:(NSNumber *)postId;
- (void)unLikePostWithId:(NSNumber *)postId;
- (void)getFullPostInfoForPostId:(NSNumber *)postId;
- (void)postNewComment:(NSString *)messageBody forPost:(NSNumber *)postId;
- (UIImage *)getImage:(NSString *)imageName;
- (void)deletePostWithId:(NSNumber *)postId;

- (void)fetchPostsUpstreamForUser:(NSNumber *)userId success:(void(^)(NSDictionary *response))successHandler;
- (BOOL)fetchPostsDownstreamForUser:(NSNumber *)userId lowestId:(NSNumber *)lowestId success:(void(^)(NSDictionary *))successHandler;
- (void)fetchPostsForUserUpstreamWithErrorHandlerStart:(NSNumber *)start userId:(NSNumber *)userId error:(void (^)(void))errorHandler success:(void(^)(NSDictionary *response))successHandler;

@end
