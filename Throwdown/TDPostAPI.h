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

@interface TDPostAPI : NSObject

+ (TDPostAPI *)sharedInstance;
+ (NSString *)createUploadFileNameFor:(TDCurrentUser *)user;

- (TDPostUpload *)initializeVideoUploadwithThumnail:(NSString *)localPhotoPath withName:(NSString *)newName;
- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath withName:(NSString *)newName;
- (void)uploadPhoto:(NSString *)localPhotoPath withName:(NSString *)newName;
- (void)addTextPost:(NSString *)comment isPR:(BOOL)isPR isPrivate:(BOOL)isPrivate shareOptions:(NSArray *)shareOptions;

- (void)addPost:(NSString *)filename comment:(NSString *)comment isPR:(BOOL)pr kind:(NSString *)kind userGenerated:(BOOL)ug sharingTo:(NSArray *)sharing isPrivate:(BOOL)isPrivate success:(void (^)(NSDictionary *response))success failure:(void (^)(void))failure;
- (void)likePostWithId:(NSNumber *)postId;
- (void)unLikePostWithId:(NSNumber *)postId;
- (void)getFullPostInfoForPost:(NSString *)identifier success:(void (^)(NSDictionary *response))successCallback error:(void (^)(void))errorCallback;
- (void)postNewComment:(NSString *)messageBody forPost:(NSNumber *)postId;
- (void)reportPostWithId:(NSNumber *)postId;
- (void)deletePostWithId:(NSNumber *)postId;

- (void)fetchPostsWithSuccess:(void (^)(NSDictionary*response))successHandler error:(void (^)(void))errorHandler;
- (void)fetchPostsForAll:(NSNumber *)start success:(void (^)(NSDictionary*response))successHandler error:(void (^)(void))errorHandler;
- (void)fetchPostsForFollowing:(NSNumber *)start success:(void (^)(NSDictionary*response))successHandler error:(void (^)(void))errorHandler;
- (void)fetchPostsForUser:(NSString *)userIdentifier start:(NSNumber *)start success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler;

@end
