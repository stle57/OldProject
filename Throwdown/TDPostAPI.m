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

@interface TDPostAPI ()

@property (nonatomic) NSMutableArray *posts;
@property (nonatomic) NSArray *notices;
@property (nonatomic) BOOL noMorePosts;
@property (nonatomic) BOOL fetchingUpstream;

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
        self.posts = [[NSMutableArray alloc] init];
        self.fetchingUpstream = NO;
    }
    return self;
}

- (void)dealloc {
    self.posts = nil;
}

#pragma mark - notices

- (NSUInteger)noticeCount {
    if (self.notices) {
        return [self.notices count];
    }
    return 0;
}

- (TDNotice *)getNoticeAt:(NSUInteger)index {
    if (self.notices && index < [self.notices count]) {
        return [self.notices objectAtIndex:index];
    }
    return nil;
}

/*
 * Removes notice from list of notices if it exists
 *
 * Returns BOOL YES if an item was removed, NO if no item was found
 */
- (BOOL)removeNoticeAt:(NSUInteger)index {
    if (self.notices && index < [self.notices count]) {
        NSMutableArray *list = [[NSMutableArray alloc] initWithArray:self.notices];
        [list removeObjectAtIndex:index];
        self.notices = [[NSArray alloc] initWithArray:list];
        return YES;
    }
    return NO;
}

#pragma mark - posts get/add/remove


- (void)addPost:(NSString *)filename comment:(NSString *)comment isPR:(BOOL)pr kind:(NSString *)kind userGenerated:(BOOL)ug success:(void (^)(NSDictionary *response))success failure:(void (^)(void))failure {
    NSMutableDictionary *post = [@{ @"kind": kind, @"personal_record": [NSNumber numberWithBool:pr], @"user_generated": [NSNumber numberWithBool:ug]} mutableCopy];
    if (filename) {
        [post addEntriesFromDictionary:@{@"filename": filename}];
    }
    if (comment) {
        [post addEntriesFromDictionary:@{@"comment": comment}];
    }
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"post": post, @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Should just put the post in the feed but this is easier to implement for now + takes care of any other new posts in the feed.
        [self fetchPostsUpstreamWithErrorHandlerStart:nil error:nil];
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Error: %@", error);

        if (failure) {
            failure();
        }
        if (error && [operation.response statusCode] == 401) {
            [self logOutUser];
        }
    }];
}

- (void)fetchPostsUpstreamWithErrorHandlerStart:(NSNumber *)start error:(void (^)(void))errorHandler {
    [self fetchPostsUpstreamWithErrorHandlerStart:start success:nil error:errorHandler];
}

- (void)fetchPostsUpstreamWithErrorHandlerStart:(NSNumber *)start success:(void (^)(NSDictionary*response))successHandler error:(void (^)(void))errorHandler {
    if (self.fetchingUpstream) {
        return;
    }
    self.fetchingUpstream = YES;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if ([TDCurrentUser sharedInstance].authToken) {
        [params addEntriesFromDictionary:@{@"user_token": [TDCurrentUser sharedInstance].authToken}];
    }
    if (start) {
        [params addEntriesFromDictionary:@{@"start": start}];
    }
    if ([TDCurrentUser sharedInstance].deviceToken) {
        [params addEntriesFromDictionary:@{@"device_token": [TDCurrentUser sharedInstance].deviceToken}];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:TDDeviceInfo.bundleVersion forHTTPHeaderField:kHTTPHeaderBundleVersion];
    [manager GET:[[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.fetchingUpstream = NO;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            if (!start) {
                [self.posts removeAllObjects];
            }
            for (NSDictionary *postObject in [responseObject valueForKeyPath:@"posts"]) {
                [self.posts addObject:[[TDPost alloc]initWithDictionary:postObject]];
            }
            if ([responseObject valueForKey:@"notification_count"]) {
                [self notifyNotificationCount:[responseObject valueForKey:@"notification_count"]];
            }
            if ([responseObject valueForKey:@"next_start"] == [NSNull null]) {
                self.noMorePosts = YES;
            }
            if ([responseObject objectForKey:@"notices"]) {
                NSMutableArray *tmp = [[NSMutableArray alloc] init];
                for (NSDictionary *dict in [responseObject objectForKey:@"notices"]) {
                    [tmp addObject:[[TDNotice alloc] initWithDictionary:dict]];
                }
                self.notices = [NSArray arrayWithArray:tmp];
            } else {
                self.notices = nil;
            }
            if (successHandler) {
                successHandler(responseObject);
            }
            [self notifyPostsRefreshed];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"HTTP Error: %@", error);
        self.fetchingUpstream = NO;

        if (errorHandler) {
            errorHandler();
        }
        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        }
    }];
}

- (NSArray *)getPosts {
    return [self.posts mutableCopy];
}


#pragma mark posts for a particular user
- (void)fetchPostsUpstreamForUser:(NSNumber *)userId success:(void(^)(NSDictionary *response))successHandler error:(void(^)(void))errorHandler {
    [self fetchPostsForUserUpstreamWithErrorHandlerStart:nil userId:userId error:errorHandler success:successHandler];
}

- (void)fetchPostsDownstreamForUser:(NSNumber *)userId lowestId:(NSNumber *)lowestId success:(void(^)(NSDictionary *))successHandler {
    [self fetchPostsForUserUpstreamWithErrorHandlerStart:lowestId userId:userId error:nil success:successHandler];
}

- (void)fetchPostsForUserUpstreamWithErrorHandlerStart:(NSNumber *)start userId:(NSNumber *)userId error:(void (^)(void))errorHandler success:(void(^)(NSDictionary *response))successHandler {
    NSMutableString *url = [NSMutableString stringWithFormat:@"/api/v1/users/%@.json?user_token=%@", [userId stringValue], [TDCurrentUser sharedInstance].authToken];

    if (start) {
        [url appendString:[NSString stringWithFormat:@"&start=%@", start]];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:TDDeviceInfo.bundleVersion forHTTPHeaderField:kHTTPHeaderBundleVersion];
    [manager GET:[[TDConstants getBaseURL] stringByAppendingString:url] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            successHandler(responseObject);
        } else if (errorHandler) {
            errorHandler();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"HTTP Error: %@", error);

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

- (void)deletePostWithId:(NSNumber *)postId {
    debug NSLog(@"API-delete post with id:%@", postId);

    // First remove post from main feed's lists
    NSMutableArray *mutablePosts = [NSMutableArray arrayWithCapacity:0];
    for (TDPost *post in self.posts) {
        if (![post.postId isEqualToNumber:postId]) {
            [mutablePosts addObject:post];
        }
    }
    [self.posts removeAllObjects];
    [self.posts addObjectsFromArray:mutablePosts];

    // Then notify any view controllers about the removal which will cache the post and refresh table
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationRemovePost object:nil userInfo:@{@"postId": postId}];

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID].json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager DELETE:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken}
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
                    if (![returnDict objectForKey:@"success"] || ![[returnDict objectForKey:@"success"] boolValue]) {
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

/* Notify any views to reload, does not update or fetch posts from server */
- (void)notifyPostsRefreshed {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDRefreshPostsNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)notifyNotificationCount:(NSNumber *)count {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUpdate
                                                        object:self
                                                      userInfo:@{@"notificationCount": count}];
}

#pragma mark - like & comment
- (void)likePostWithId:(NSNumber *)postId {
    //  /api/v1/posts/{post's id}/like.json

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID]/like.json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
            if ([returnDict objectForKey:@"success"]) {
                if ([[returnDict objectForKey:@"success"] boolValue]) {
                    debug NSLog(@"Like Success!");

                    // Change the like in that post
                    TDPost *post = (TDPost *)[[TDAppDelegate appDelegate] postWithPostId:postId];

                    if (post) {
                        post.liked = YES;
                       // [self notifyPostsRefreshed];
                    }
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        debug NSLog(@"LIKE Error: %@", error);

        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        } else {
            [self notifyPostsRefreshed];
        }
    }];
}

- (void)unLikePostWithId:(NSNumber *)postId {
    //  /api/v1/posts/{post's id}/like.json

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

                    // Change the like in that post
                    TDPost *post = (TDPost *)[[TDAppDelegate appDelegate] postWithPostId:postId];
                    if (post) {
                        post.liked = NO;
                    }
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"UNLIKE Error: %@", error);
        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        } else {
            [self notifyPostsRefreshed];
        }
    }];
}

- (void)getFullPostInfoForPostId:(NSNumber *)postId {
    //  /api/v1/posts/{post-id}.json
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID].json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:TDDeviceInfo.bundleVersion forHTTPHeaderField:kHTTPHeaderBundleVersion];
    [manager GET:url parameters:@{@"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            // Notify any views to reload
            [[NSNotificationCenter defaultCenter] postNotificationName:FULL_POST_INFO_NOTIFICATION
                                                                object:self
                                                              userInfo:responseObject];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get full HTTP Error: %@", error);
        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        }
    }];
}

#pragma mark - Comments

- (void)postNewComment:(NSString *)messageBody forPost:(NSNumber *)postId {
    if (!messageBody || !postId) {
        return;
    }

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/comments.json"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken , @"comment[body]" : messageBody, @"comment[post_id]" : postId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
            if ([returnDict objectForKey:@"success"] && [[returnDict objectForKey:@"success"] boolValue]) {
                [self notifyPostsRefreshed];
                debug NSLog(@"New Comment Success!:%@", returnDict);

                // Notify any views to reload
                [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationNewCommentPostInfo
                                                                    object:self
                                                                  userInfo:returnDict];
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
    TDPostUpload *upload = [[TDPostUpload alloc] initWithVideoPath:localVideoPath thumbnailPath:localPhotoPath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDPostUploadStarted object:upload userInfo:nil];
}

- (void)uploadPhoto:(NSString *)localPhotoPath withName:(NSString *)newName {
    TDPostUpload *upload = [[TDPostUpload alloc] initWithPhotoPath:localPhotoPath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDPostUploadStarted object:upload userInfo:nil];
}

- (void)addTextPost:(NSString *)comment isPR:(BOOL)isPR shareOptions:(NSArray *)shareOptions {
    TDTextUpload *upload = [[TDTextUpload alloc] initWithComment:comment isPR:isPR];
    upload.shareOptions = shareOptions;
    [[NSNotificationCenter defaultCenter] postNotificationName:TDPostUploadStarted object:upload userInfo:nil];
}

#pragma mark - Sharing

/**
 * If this method is called async make sure we already have the correct permissions
 */
- (void)sharePost:(NSDictionary *)shareData toNetworks:(NSArray *)networks success:(void (^)(void))success failure:(void (^)(void))failure {
    debug NSLog(@"Share data: %@", shareData);
    if ([networks containsObject:@"facebook"]) {
        if (FBSession.activeSession.isOpen) {
            [self sharePostToFacebook:shareData success:success failure:failure];
        } else {
            debug NSLog(@"FB permissions: %@", [FBSession.activeSession permissions]);
            [FBSession openActiveSessionWithPublishPermissions:@[@"public_profile", @"publish_actions"]
                                               defaultAudience:FBSessionDefaultAudienceFriends
                                                  allowLoginUI:YES
                                             completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
                [[TDAppDelegate appDelegate] sessionStateChanged:session state:state error:error success:^{
                    [self sharePostToFacebook:shareData success:success failure:failure];
                } failure:^(NSString *error) {
                    if (failure) {
                        failure();
                    }
                }];
            }];
        }
    }
}

- (void)sharePostToFacebook:(NSDictionary *)shareData success:(void (^)(void))success failure:(void (^)(void))failure {
    NSMutableDictionary<FBOpenGraphObject> *object = [FBGraphObject openGraphObjectForPost];
    for (NSString *key in @[@"type", @"title", @"description", @"url", @"image"]) {
        if ([shareData objectForKey:key]) {
            object[key] = [shareData objectForKey:key];
        }
    }

    // Post the Open Graph object
    [FBRequestConnection startForPostOpenGraphObject:object completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // get the object ID for the Open Graph object that is now stored in the Object API
            NSString *objectId = [result objectForKey:@"id"];
            NSLog(@"FB::OG object id: %@", objectId);

            // create an Open Graph action
            id<FBOpenGraphAction> action = (id<FBOpenGraphAction>)[FBGraphObject graphObject];
            [action setObject:objectId forKey:[shareData objectForKey:@"object"]];
            [action setObject:@YES forKey:@"fb:explicitly_shared"];

            // Create the Open Graph Action referencing user owned object
            [FBRequestConnection startForPostWithGraphPath:[@"/me/" stringByAppendingString:[shareData objectForKey:@"action"]]
                                               graphObject:action
                                         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    NSLog(@"FB::OG story posted, story id: %@", [result objectForKey:@"id"]);
                    [self registerFacebookStoryForPost:((NSNumber *)[shareData objectForKey:@"post_id"]) objectId:objectId actionId:[result objectForKey:@"id"]];
                    if (success) {
                        success();
                    }
                } else {
                    NSLog(@"FB::Error posting OG action: %@", error.description);
                    if (failure) {
                        failure();
                    }
                }
            }];
        } else {
            NSLog(@"FB::Error posting OG object: %@", error.description);
            if (failure) {
                failure();
            }
        }
    }];
}

- (void)registerFacebookStoryForPost:(NSNumber *)postId objectId:(NSString *)objectId actionId:(NSString *)actionId {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/facebook_actions.json"];
    NSDictionary *params = @{ @"user_token": [TDCurrentUser sharedInstance].authToken, @"facebook_action": @{ @"post_id": postId, @"fb_object_id": objectId, @"fb_action_id": actionId } };
    debug NSLog(@"saving fb story: %@", params);
    AFHTTPRequestOperationManager *httpManager = [AFHTTPRequestOperationManager manager];
    httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [httpManager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"fb story saved");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"fb story failed");
    }];
}


#pragma mark - Failures

- (void)logOutUser {
    [[NSNotificationCenter defaultCenter] postNotificationName:LOG_OUT_NOTIFICATION
                                                        object:nil
                                                      userInfo:nil];
}

@end
