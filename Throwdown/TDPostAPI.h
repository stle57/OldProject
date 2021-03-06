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
#import "TDPostUpload.h"
#import "TDTextUpload.h"
#import "TDNotice.h"

const typedef NS_ENUM(NSUInteger, kFetchPostsForFeed) {
    kFetchPostsForFeedAll,
    kFetchPostsForFeedFollowing
};

@interface TDPostAPI : NSObject

+ (TDPostAPI *)sharedInstance;
+ (NSString *)createUploadFileNameFor:(TDCurrentUser *)user;

- (TDPostUpload *)initializeVideoUploadwithThumnail:(NSString *)localPhotoPath withName:(NSString *)newName;
- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath withName:(NSString *)newName;
- (void)uploadPhoto:(NSString *)localPhotoPath withName:(NSString *)newName;
- (void)addTextPost:(NSString *)comment isPR:(BOOL)isPR visibility:(TDPostPrivacy)visibility shareOptions:(NSArray *)shareOptions location:(NSDictionary*)location;

- (void)addPost:(NSString *)filename comment:(NSString *)comment isPR:(BOOL)pr kind:(NSString *)kind userGenerated:(BOOL)ug sharingTo:(NSArray *)sharing visibility:(TDPostPrivacy)visibility location:(NSDictionary*)location success:(void (^)(NSDictionary *response))success failure:(void (^)(void))failure;
- (void)updatePostText:(NSString *)postComment postId:(NSNumber*)postId;
- (void)likePostWithId:(NSNumber *)postId;
- (void)unLikePostWithId:(NSNumber *)postId;
- (void)getFullPostInfoForPost:(NSString *)identifier success:(void (^)(NSDictionary *response))successCallback error:(void (^)(void))errorCallback;
- (void)postNewComment:(NSString *)messageBody forPost:(NSNumber *)postId;
- (void)postUpdateComment:(NSString *)messageBody forPost:(NSNumber *)postId forComment:(NSNumber*)commentId;
- (void)postDeleteComment:(NSNumber*)commentId forPost:(NSNumber*)postId;
- (void)reportPostWithId:(NSNumber *)postId;
- (void)reportCommentWithId:(NSNumber *)commentId postId:(NSNumber*)postId;
- (void)deletePostWithId:(NSNumber *)postId isPR:(BOOL)isPR;
- (void)unfollowPostWithId:(NSNumber*)postId;
- (void)followPostWithId:(NSNumber *)postId;

- (void)fetchPostsForFeed:(kFetchPostsForFeed)feed start:(NSNumber *)start success:(void (^)(NSDictionary*response))successHandler error:(void (^)(void))errorHandler;
- (void)fetchPostsForUser:(NSString *)userIdentifier start:(NSNumber *)start success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler;
- (void)fetchPRPostsForUser:(NSString *)userIdentifier success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler;
- (void)fetchPostsForLocationId:(NSNumber *)locationId start:(NSNumber *)start success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler;
- (void)fetchPostsForTagName:(NSString *)tagName start:(NSNumber *)start success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler;
- (void)fetchUsersPostsTagged:(NSNumber *)userId tag:(NSString *)tagName start:(NSNumber *)start success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler;
@end
