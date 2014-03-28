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
#import "TDPostUpload.h"

@implementation TDPostAPI
{
    NSMutableArray *posts;
}

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
        posts = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadImage:) name:@"TDDownloadPreviewImageNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    posts = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


# pragma mark - posts get/add/remove


- (void)addPost:(NSString *)filename comment:(NSString *)comment success:(void (^)(void))success failure:(void (^)(void))failure {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"post": @{@"filename": filename, @"comment": comment}, @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"JSON: %@", [responseObject class]);
        // Not the best way to do this but for now...
        [self fetchPostsUpstream];
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Error: %@", error);
        if (failure) {
            failure();
        }
    }];
}

- (void)fetchPostsUpstream {
    [self fetchPostsUpstreamWithErrorHandler:nil];
}

- (void)fetchPostsUpstreamWithErrorHandler:(void (^)(void))errorHandler {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"] parameters:@{@"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            [posts removeAllObjects];
            for (NSDictionary *postObject in [responseObject valueForKeyPath:@"posts"]) {
                [posts addObject:[[TDPost alloc]initWithDictionary:postObject]];
            }
            [self notifyPostsRefreshed];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"HTTP Error: %@", error);
        if (errorHandler) {
            errorHandler();
        }
    }];
}

- (NSArray *)getPosts {
    return [posts mutableCopy];
}

-(void)deletePostWithId:(NSNumber *)postId
{
    NSLog(@"API-delete post with id:%@", postId);

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID].json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager DELETE:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken}
            success:^(AFHTTPRequestOperation *operation, id responseObject) {

                if ([responseObject isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
                    if ([returnDict objectForKey:@"success"]) {
                        if ([[returnDict objectForKey:@"success"] boolValue]) {
                            // Success
                            [[NSNotificationCenter defaultCenter] postNotificationName:POST_DELETED_NOTIFICATION
                                                                                object:responseObject
                                                                              userInfo:nil];
                        } else {
                            // Fail
                        }
                    }
                }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Error: %@", error);

        [[NSNotificationCenter defaultCenter] postNotificationName:POST_DELETED_FAIL_NOTIFICATION
                                                            object:error
                                                          userInfo:nil];
    }];
}

/* Notify any views to reload, does not update or fetch posts from server */
- (void)notifyPostsRefreshed {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDRefreshPostsNotification"
                                                        object:self
                                                      userInfo:nil];
}

#pragma mark - like & comment
-(void)likePostWithId:(NSNumber *)postId
{
    //  /api/v1/posts/{post's id}/like.json

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID]/like.json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {

        if ([responseObject isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
            if ([returnDict objectForKey:@"success"]) {
                if ([[returnDict objectForKey:@"success"] boolValue]) {
                    NSLog(@"Like Success!");

                    // Change the like in that post
                    TDPost *post = (TDPost *)[[TDAppDelegate appDelegate] postWithPostId:postId];

                    if (post) {
                        post.liked = YES;
                        [self notifyPostsRefreshed];
                    }
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        NSLog(@"LIKE Error: %@", error);

        [self notifyPostsRefreshed];
    }];
}

-(void)unLikePostWithId:(NSNumber *)postId
{
    //  /api/v1/posts/{post's id}/like.json

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID]/like.json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager DELETE:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {

        if ([responseObject isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
            if ([returnDict objectForKey:@"success"]) {
                if ([[returnDict objectForKey:@"success"] boolValue]) {
                    NSLog(@"unLike Success!");

                    // Change the like in that post
                    TDPost *post = (TDPost *)[[TDAppDelegate appDelegate] postWithPostId:postId];

                    if (post) {
                        post.liked = NO;
                        [self notifyPostsRefreshed];
                    }
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        NSLog(@"UNLIKE Error: %@", error);

        [self notifyPostsRefreshed];

    }];
}

-(void)getFullPostInfoForPostId:(NSNumber *)postId
{
    //  /api/v1/posts/{post-id}.json
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts/[POST_ID].json"];
    url = [url stringByReplacingOccurrencesOfString:@"[POST_ID]"
                                         withString:[postId stringValue]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:@{@"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {

        NSLog(@"Full response:%@", responseObject);

        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            // Notify any views to reload
            [[NSNotificationCenter defaultCenter] postNotificationName:FULL_POST_INFO_NOTIFICATION
                                                                object:self
                                                              userInfo:responseObject];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get full HTTP Error: %@", error);
    }];
}

#pragma mark - Comments
-(void)postNewComment:(NSString *)messageBody forPost:(NSNumber *)postId
{
    /*
    
    POST /api/v1/comments.json with parameters:
    + comment[body]={COMMENT BODY}
    + comment[post_id]={POST ID}
    + user_token={CURRENT USER TOKEN}
    
    */

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/comments.json"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken , @"comment[body]" : messageBody, @"comment[post_id]" : postId} success:^(AFHTTPRequestOperation *operation, id responseObject) {

        if ([responseObject isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *returnDict = [NSDictionary dictionaryWithDictionary:responseObject];
            if ([returnDict objectForKey:@"success"]) {
                if ([[returnDict objectForKey:@"success"] boolValue]) {

                    NSLog(@"New Comment Success!");
                    [self notifyPostsRefreshed];
                    NSLog(@"New Comment Success!:%@", returnDict);

                    // Notify any views to reload
                    [[NSNotificationCenter defaultCenter] postNotificationName:NEW_COMMENT_INFO_NOTICIATION
                                                                        object:self
                                                                      userInfo:returnDict];
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"New Comment Error: %@", error);
    }];
}

# pragma mark - image/video getting/saving

- (NSString *)getCachePath {
    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [cachePathArray lastObject];
}

- (UIImage *)getImage:(NSString *)filename {
    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
    NSData *data = [NSData dataWithContentsOfFile:filename];
    return [UIImage imageWithData:data];
}

- (void)saveImage:(UIImage*)image filename:(NSString*)filename {
    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
    NSData *data = UIImageJPEGRepresentation(image, 0.99f);
    [data writeToFile:filename atomically:YES];
}

//- (UIImage *)getVideo:(NSString *)filename
//{
//    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
//    NSData *data = [NSData dataWithContentsOfFile:filename];
//    return [UIImage imageWithData:data];
//}

- (void)saveVideo:(NSData *)data filename:(NSString*)filename {
    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
    [data writeToFile:filename atomically:YES];
}

- (void)downloadImage:(NSNotification*)notification {
    UIImageView *imageView = notification.userInfo[@"imageView"];
    NSString *filename = [notification.userInfo[@"filename"] stringByAppendingString:FTImage];

    imageView.image = [self getImage:filename];

    if (imageView.image == nil) {
        NSURL *imageURL = [NSURL URLWithString:[RSHost stringByAppendingFormat:@"/%@", filename]];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:[[NSURLRequest alloc] initWithURL:imageURL]];
        operation.responseSerializer = [AFImageResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject isKindOfClass:[UIImage class]]) {
                UIImage *image = (UIImage *)responseObject;
                imageView.image = image;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self saveImage:image filename:filename];
                });
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            debug NSLog(@"Image error: %@, %@", filename, error);
        }];
        [operation start];
    }
}


# pragma mark - uploads

- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath withName:(NSString *)newName {
    TDPostUpload *upload = [[TDPostUpload alloc] initWithVideoPath:localVideoPath thumbnailPath:localPhotoPath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDPostUploadStarted" object:upload userInfo:nil];
}

@end
