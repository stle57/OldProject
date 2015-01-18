//
//  PostAPI.m
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPostAPI.h"
#import "TDConstants.h"
#import "TDCurrentUser.h"
#import "RSClient.h"
#import "RSContainer.h"
#import "RSStorageObject.h"
#import "AFNetworking.h"
#import "TDAppDelegate.h"
#import "UIImage+Resizing.h"
#import "TDFileSystemHelper.h"
#import "TDDeviceInfo.h"
#import "iRate.h"
#import "TDRequestSerializer.h"
#import "TDHomeViewController.h"

@interface TDPostAPI ()

@property (nonatomic) BOOL fetchingUpstream;
@property (weak, nonatomic) NSNumber* lastLikedPostId;

@end

@implementation TDPostAPI

+ (TDPostAPI *)sharedInstance {
    static TDPostAPI *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDPostAPI alloc] init];
    });
    return _sharedInstance;
}

+ (NSString *)createUploadFileNameFor:(TDCurrentUser *)user {
    return [NSString stringWithFormat:@"%@_%f",user.userId, [[NSDate date] timeIntervalSince1970]];
}

- (id)init {
    self = [super init];
    if (self) {
        self.fetchingUpstream = NO;
    }
    return self;
}

#pragma mark - posts get/add/remove

- (void)addPost:(NSString *)filename comment:(NSString *)comment isPR:(BOOL)pr kind:(NSString *)kind userGenerated:(BOOL)ug sharingTo:(NSArray *)sharing isPrivate:(BOOL)isPrivate location:(NSDictionary*)location success:(void (^)(NSDictionary *response))success failure:(void (^)(void))failure {
    NSMutableDictionary *post = [@{
                                   @"kind": kind,
                                   @"personal_record": [NSNumber numberWithBool:pr],
                                   @"user_generated": [NSNumber numberWithBool:ug],
                                   @"private": [NSNumber numberWithBool:isPrivate],
                                   @"location" : location
                                } mutableCopy];
    if (filename) {
        [post addEntriesFromDictionary:@{@"filename": filename}];
    }
    if (comment) {
        [post addEntriesFromDictionary:@{@"comment": comment}];
    }
    if (!sharing) {
        sharing = @[];
    }
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setRequestSerializer:[[TDRequestSerializer alloc] init]];
    [manager POST:url parameters:@{ @"post": post, @"share_to": sharing, @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[TDCurrentUser sharedInstance] updateCurrentUserInfo]; // updates post/or counts etc

        // This isn't the prettiest thing. But all the current alternatives aren't great either.
        // We really need to refactor the way uploads are handled.
        TDHomeViewController *homeViewController = [TDHomeViewController getHomeViewController];
        if (homeViewController) {
            if (success) {
                [homeViewController fetchPostsWithCompletion:^{
                    success(responseObject);
                }];
            } else {
                [homeViewController fetchPosts];
            }
        } else if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Add Post Error: %@", error);

        if (failure) {
            failure();
        }
        if (error && [operation.response statusCode] == 401) {
            [self logOutUser];
        }
    }];
}

- (void)fetchPostsForFeed:(kFetchPostsForFeed)feed start:(NSNumber *)start success:(void (^)(NSDictionary*response))successHandler error:(void (^)(void))errorHandler {
    if (self.fetchingUpstream) {
        return;
    }
    self.fetchingUpstream = YES;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    switch (feed) {
        case kFetchPostsForFeedAll:
            [params setObject:@"all" forKey:@"feed"];
            break;
        case kFetchPostsForFeedFollowing:
            [params setObject:@"following" forKey:@"feed"];
            break;
    }

    if (start) {
        [params setObject:start forKey:@"start"];
    }
    if ([TDCurrentUser sharedInstance].deviceToken) {
        [params setObject:[TDCurrentUser sharedInstance].deviceToken forKey:@"device_token"];
    }
    if ([TDCurrentUser sharedInstance].authToken) {
        [params setObject:[TDCurrentUser sharedInstance].authToken forKey:@"user_token"];
    }

    [self fetchPostsPath:@"/api/v1/posts.json" parameters:params success:^(NSDictionary *response) {
        self.fetchingUpstream = NO;
        if (successHandler) {
            successHandler(response);
        }
    } error:^{
        self.fetchingUpstream = NO;
        if (errorHandler) {
            errorHandler();
        }
    }];
}

#pragma mark posts for a particular user

- (void)fetchPostsForUser:(NSString *)userIdentifier start:(NSNumber *)start success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler {
    NSMutableString *url = [NSMutableString stringWithFormat:@"/api/v1/users/%@.json?user_token=%@", userIdentifier, [TDCurrentUser sharedInstance].authToken];

    if (start) {
        [url appendString:[NSString stringWithFormat:@"&start=%@", start]];
    }
    [self fetchPostsPath:url parameters:nil success:successHandler error:errorHandler];
}

#pragma mark PR posts for a particular user

- (void)fetchPRPostsForUser:(NSString *)userIdentifier success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler {
    NSMutableString *url = [NSMutableString stringWithFormat:@"/api/v1/users/%@.json?user_token=%@&kind=pr", userIdentifier, [TDCurrentUser sharedInstance].authToken];
    
    debug NSLog(@"inside fetchPRPostsForUser=%@", url);
    [self fetchPostsPath:url parameters:nil success:successHandler error:errorHandler];
}

#pragma mark - Posts for location

- (void)fetchPostsForLocationId:(NSNumber *)locationId start:(NSNumber *)start success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler {
    NSMutableString *url = [NSMutableString stringWithFormat:@"/api/v1/locations/%@.json?user_token=%@", locationId, [TDCurrentUser sharedInstance].authToken];
    if (start) {
        [url appendString:[NSString stringWithFormat:@"&start=%@", start]];
    }
    [self fetchPostsPath:url parameters:nil success:successHandler error:errorHandler];
}

#pragma mark - Posts for tag

- (void)fetchPostsForTagName:(NSString *)tagName start:(NSNumber *)start success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler {
    NSMutableString *url = [NSMutableString stringWithFormat:@"/api/v1/tags/%@.json?user_token=%@", tagName, [TDCurrentUser sharedInstance].authToken];
    if (start) {
        [url appendString:[NSString stringWithFormat:@"&start=%@", start]];
    }
    [self fetchPostsPath:url parameters:nil success:successHandler error:errorHandler];
}

#pragma mark Posts fetcher

- (void)fetchPostsPath:(NSString *)path parameters:(NSDictionary *)params success:(void(^)(NSDictionary *response))successHandler error:(void (^)(void))errorHandler {
    if (![[TDCurrentUser sharedInstance] isLoggedIn]) {
        return;
    }

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:TDDeviceInfo.bundleVersion forHTTPHeaderField:kHTTPHeaderBundleVersion];
    [manager GET:[[TDConstants getBaseURL] stringByAppendingString:path] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            successHandler(responseObject);
        } else if (errorHandler) {
            errorHandler();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"HTTP Post fetch Error: %@", error);

        if (errorHandler) {
            errorHandler();
        }

        if ([operation.response statusCode] == 401) {
            [self logOutUser];
        }
    }];
}


#pragma mark - Report post

- (void)reportPostWithId:(NSNumber *)postId {
    debug NSLog(@"API-report post with id:%@", postId);

    NSString *url = [NSString stringWithFormat:@"%@/api/v1/posts/%@/report.json", [TDConstants getBaseURL], postId];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken }
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success reporting %@", postId);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error reporting: %@", error);
            }];
}

#pragma delete post

- (void)deletePostWithId:(NSNumber *)postId isPR:(BOOL)isPR {
    debug NSLog(@"API-delete post with id:%@", postId);

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID].json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager DELETE:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken}
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
                    if ([returnDict objectForKey:@"success"] && [[returnDict objectForKey:@"success"] boolValue]) {
                        // Notify any view controllers about the removal which will cache the post and refresh table
                        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationRemovePost object:nil userInfo:@{@"postId": postId}];
                        
                        NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
                        [userInfo setObject:@1 forKey:TD_DECREMENT_STRING];
                        if (isPR) {
                            [userInfo setObject:@1 forKey:@"PR"];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdatePostCount object:[TDCurrentUser sharedInstance].userId userInfo:userInfo];
                    } else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationRemovePostFailed object:nil userInfo:@{@"postId": postId}];
                    }
                }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Error: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationRemovePostFailed
                                                            object:nil
                                                          userInfo:@{ @"postId": postId }];
    }];
}

#pragma mark - like & comment
- (void)likePostWithId:(NSNumber *)postId {
    debug NSLog(@"inside likePostWithId");
    //  /api/v1/posts/{post's id}/like.json
    if (self.lastLikedPostId == nil) {
        debug NSLog(@"setting event count inside like post");
        [iRate sharedInstance].eventCount = [iRate sharedInstance].eventCount + TD_LIKE_EVENT_COUNT;
        self.lastLikedPostId = postId;
    }

    // Notify any views to reload
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdatePost
                                                        object:self
                                                      userInfo:@{
                                                                 @"postId": postId,
                                                                 @"change": [NSNumber numberWithUnsignedInteger:kUpdatePostTypeLike]
                                                                 }];

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID]/like.json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // TODO: There is no failure handling here
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
            if ([returnDict objectForKey:@"success"]) {
                if ([[returnDict objectForKey:@"success"] boolValue]) {
                    debug NSLog(@"Like Success!");
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"LIKE Error: %@", error);
        if ([operation.response statusCode] == 401) {
            [self logOutUser];
        }
    }];
}

- (void)unLikePostWithId:(NSNumber *)postId {
    //  /api/v1/posts/{post's id}/like.json
    if (self.lastLikedPostId == nil) {
        debug NSLog(@"setting event count");
        // This takes care of the scenario where the user liked a post and then immediately disliked it.
        [iRate sharedInstance].eventCount = [iRate sharedInstance].eventCount + TD_LIKE_EVENT_COUNT;
        self.lastLikedPostId = postId;
    }

    // Notify any views to reload
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdatePost
                                                        object:self
                                                      userInfo:@{
                                                                 @"postId": postId,
                                                                 @"change": [NSNumber numberWithUnsignedInteger:kUpdatePostTypeUnlike]
                                                                 }];

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID]/like.json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager DELETE:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
            if ([returnDict objectForKey:@"success"]) {
                if ([[returnDict objectForKey:@"success"] boolValue]) {
                    debug NSLog(@"unLike Success!");
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"UNLIKE Error: %@", error);
        if ([operation.response statusCode] == 401) {
            [self logOutUser];
        }
    }];
}

- (void)getFullPostInfoForPost:(NSString *)identifier success:(void (^)(NSDictionary *response))successCallback error:(void (^)(void))errorCallback {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/posts/%@.json", [TDConstants getBaseURL], identifier];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:TDDeviceInfo.bundleVersion forHTTPHeaderField:kHTTPHeaderBundleVersion];
    [manager GET:url parameters:@{@"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            // Notify any views to reload
            if (successCallback) {
                successCallback(responseObject);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get full HTTP Error: %@", error);
        if (errorCallback) {
            errorCallback();
        }
        if ([operation.response statusCode] == 401) {
            [self logOutUser];
        }
    }];
}

#pragma mark - Comments

- (void)postNewComment:(NSString *)messageBody forPost:(NSNumber *)postId {
    if (!messageBody || !postId) {
        return;
    }
    [iRate sharedInstance].eventCount = [iRate sharedInstance].eventCount + TD_COMMENT_EVENT_COUNT;
    
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/comments.json"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken , @"comment[body]" : messageBody, @"comment[post_id]" : postId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
            if ([returnDict objectForKey:@"success"] && [[returnDict objectForKey:@"success"] boolValue]) {
                debug NSLog(@"New Comment Success!:%@", returnDict);

                // Notify any views to reload
                [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdatePost
                                                                    object:self
                                                                  userInfo:@{
                                                                             @"postId": postId,
                                                                             @"change": [NSNumber numberWithUnsignedInteger:kUpdatePostTypeAddComment],
                                                                             @"comment": [returnDict objectForKey:@"comment"]
                                                                             }];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationNewCommentFailed object:nil userInfo:nil];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"New Comment Error: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationNewCommentFailed object:nil userInfo:nil];
        if (error && [operation.response statusCode] == 401) {
            [self logOutUser];
        }
    }];
}

# pragma mark - uploads

- (TDPostUpload *)initializeVideoUploadwithThumnail:(NSString *)localPhotoPath withName:(NSString *)newName {
    TDPostUpload *upload = [[TDPostUpload alloc] initWithVideoThumbnail:localPhotoPath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDPostUploadStarted object:upload userInfo:nil];
    return upload;
}

- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath withName:(NSString *)newName {
    [iRate sharedInstance].eventCount = [iRate sharedInstance].eventCount + TD_POST_EVENT_COUNT;
    TDPostUpload *upload = [[TDPostUpload alloc] initWithVideoPath:localVideoPath thumbnailPath:localPhotoPath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDPostUploadStarted object:upload userInfo:nil];
}

- (void)uploadPhoto:(NSString *)localPhotoPath withName:(NSString *)newName {
    [iRate sharedInstance].eventCount = [iRate sharedInstance].eventCount + TD_POST_EVENT_COUNT;

    TDPostUpload *upload = [[TDPostUpload alloc] initWithPhotoPath:localPhotoPath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDPostUploadStarted object:upload userInfo:nil];
}

- (void)addTextPost:(NSString *)comment isPR:(BOOL)isPR isPrivate:(BOOL)isPrivate shareOptions:(NSArray *)shareOptions location:(NSDictionary*)location{
    [iRate sharedInstance].eventCount = [iRate sharedInstance].eventCount + TD_POST_EVENT_COUNT;

    TDTextUpload *upload = [[TDTextUpload alloc] initWithComment:comment isPR:isPR isPrivate:isPrivate location:location];
    upload.shareOptions = shareOptions;
    [[NSNotificationCenter defaultCenter] postNotificationName:TDPostUploadStarted object:upload userInfo:nil];
}

#pragma mark - Failures

- (void)logOutUser {
    [[NSNotificationCenter defaultCenter] postNotificationName:LOG_OUT_NOTIFICATION
                                                        object:nil
                                                      userInfo:nil];
}

@end
