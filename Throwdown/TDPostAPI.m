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
#import "UIImage+Resizing.h"
#import "TDFileSystemHelper.h"

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setImage:) name:TDDownloadPreviewImageNotification object:nil];
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

        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        } else {
            if (failure) {
                failure();
            }
        }
    }];
}

- (void)fetchPostsUpstream {
    [self fetchPostsUpstreamWithErrorHandlerStart:nil error:nil];
}

- (BOOL)fetchPostsDownstream {
    NSNumber *lowestId = [self lowestIdOfPosts];
    if ([lowestId compare:[NSNumber numberWithInt:0]] == NSOrderedAscending ||
        [lowestId compare:[NSNumber numberWithInt:0]] == NSOrderedSame) {
        return NO;
    }
    [self fetchPostsUpstreamWithErrorHandlerStart:lowestId error:nil];
    return YES;
}

- (void)fetchPostsUpstreamWithErrorHandlerStart:(NSNumber *)start error:(void (^)(void))errorHandler {
    NSMutableDictionary *params = [@{@"user_token": [TDCurrentUser sharedInstance].authToken} mutableCopy];
    if (start) {
        [params addEntriesFromDictionary:@{@"start": start}];
    }
    if ([TDCurrentUser sharedInstance].deviceToken) {
        [params addEntriesFromDictionary:@{@"device_token": [TDCurrentUser sharedInstance].deviceToken}];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {

            if (!start) {
                [posts removeAllObjects];
            }
            for (NSDictionary *postObject in [responseObject valueForKeyPath:@"posts"]) {
                [posts addObject:[[TDPost alloc]initWithDictionary:postObject]];
            }
            if ([responseObject valueForKey:@"notification_count"]) {
                [self notifyNotificationCount:[responseObject valueForKey:@"notification_count"]];
            }
            [self notifyPostsRefreshed];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"HTTP Error: %@", error);

        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        } else {
            if (errorHandler) {
                errorHandler();
            }
        }
    }];
}

- (NSArray *)getPosts {
    return [posts mutableCopy];
}

-(NSNumber *)lowestIdOfPosts
{
    NSNumber *lowestId = [NSNumber numberWithLongLong:LONG_LONG_MAX];
    for (TDPost *post in posts) {
        if ([lowestId compare:post.postId] == NSOrderedDescending) {
            lowestId = post.postId;
        }
    }
    long lowest = [lowestId longValue]-1;
    lowestId = [NSNumber numberWithLong:lowest];
    return lowestId;
}

#pragma mark posts for a particular user
- (void)fetchPostsUpstreamForUser:(NSNumber *)userId success:(void(^)(NSDictionary *response))successHandler {
    [self fetchPostsForUserUpstreamWithErrorHandlerStart:nil userId:userId error:nil success:successHandler];
}

- (BOOL)fetchPostsDownstreamForUser:(NSNumber *)userId lowestId:(NSNumber *)lowestId success:(void(^)(NSDictionary *))successHandler {
    if ([lowestId compare:[NSNumber numberWithInt:0]] == NSOrderedAscending ||
        [lowestId compare:[NSNumber numberWithInt:0]] == NSOrderedSame) {
        return NO;
    }
    [self fetchPostsForUserUpstreamWithErrorHandlerStart:lowestId userId:userId error:nil success:successHandler];
    return YES;
}

- (void)fetchPostsForUserUpstreamWithErrorHandlerStart:(NSNumber *)start userId:(NSNumber *)userId error:(void (^)(void))errorHandler success:(void(^)(NSDictionary *response))successHandler {
    NSMutableString *url = [NSMutableString stringWithFormat:@"/api/v1/users/%@.json?user_token=%@", [userId stringValue], [TDCurrentUser sharedInstance].authToken];

    if (start) {
        [url appendString:[NSString stringWithFormat:@"&start=%@", start]];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[[TDConstants getBaseURL] stringByAppendingString:url] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            successHandler(responseObject);
        } else if (errorHandler) {
            errorHandler();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"HTTP Error: %@", error);

        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        } else {
            if (errorHandler) {
                errorHandler();
            }
        }
    }];
}

#pragma delete post
- (void)deletePostWithId:(NSNumber *)postId {
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

                            // Remove the post from 'posts'
                            NSMutableArray *mutablePosts = [NSMutableArray arrayWithCapacity:0];
                            for (TDPost *post in posts) {
                                if (![post.postId isEqualToNumber:postId]) {
                                    [mutablePosts addObject:post];
                                }
                            }
                            [posts removeAllObjects];
                            [posts addObjectsFromArray:mutablePosts];

                            // Success
                            [[NSNotificationCenter defaultCenter] postNotificationName:POST_DELETED_NOTIFICATION
                                                                                object:postId
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
                       // [self notifyPostsRefreshed];
                    }
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        NSLog(@"LIKE Error: %@", error);

        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        } else {
            [self notifyPostsRefreshed];
        }
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
                      //  [self notifyPostsRefreshed];
                    }
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        NSLog(@"UNLIKE Error: %@", error);

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

        if (error) {
            if ([operation.response statusCode] == 401) {
                [self logOutUser];
            }
        }
    }];
}

# pragma mark - image/video getting/saving

- (NSString *)getCachePath {
    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [cachePathArray lastObject];
}

- (BOOL)imageExists:(NSString *)filename {
    return [TDFileSystemHelper fileExistsAtPath:[[self getCachePath] stringByAppendingFormat:@"/%@", filename]];
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

- (void)saveVideo:(NSData *)data filename:(NSString*)filename {
    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
    [data writeToFile:filename atomically:YES];
}


#pragma mark - get and set TDDownloadPreviewImageNotification notification and resizing image

- (void)setImage:(NSNotification *)notification {
    UIImageView *imageView = notification.userInfo[@"imageView"];
    NSString *filename = [notification.userInfo[@"filename"] stringByAppendingString:FTImage];

    if ([notification.userInfo objectForKey:@"width"] && [notification.userInfo objectForKey:@"height"]) {
        NSNumber *width = notification.userInfo[@"width"];
        NSNumber *height = notification.userInfo[@"height"];
        NSString *filenameWithSize = [NSString stringWithFormat:@"%@_%@x%@%@",
                                      notification.userInfo[@"filename"],
                                      width,
                                      height,
                                      FTImage];
        CGSize size = CGSizeMake([width floatValue], [height floatValue]);

        // First check for sized image cached
        // Then resize and save larger res image
        // Then download original and save as both original size and resized
        if ([self imageExists:filenameWithSize]) {
            [self setImageFromFile:filenameWithSize toView:imageView size:CGSizeZero sizedFilename:nil];
        } else if ([self imageExists:filenameWithSize]) {
            [self setImageFromFile:filename toView:imageView size:size sizedFilename:filenameWithSize];
        } else {
            [self downloadImage:filename imageView:imageView size:size sizedFilename:filenameWithSize];
        }
    } else {
        if ([self imageExists:filename]) {
            [self setImageFromFile:filename toView:imageView size:CGSizeZero sizedFilename:nil];
        } else {
            [self downloadImage:filename imageView:imageView size:CGSizeZero sizedFilename:nil];
        }
    }
}

- (void)setImageFromFile:(NSString *)filename toView:(UIImageView *)view size:(CGSize)size sizedFilename:(NSString *)sizedFilename {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self getImage:filename];
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
            image = [image scaleToSize:size];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            view.image = image;
        });
        if (!CGSizeEqualToSize(size, CGSizeZero) && ![self imageExists:sizedFilename]) {
            [self saveImage:image filename:sizedFilename];
        }
    });
}

- (void)setImage:(UIImage *)image filename:(NSString *)filename toView:(UIImageView *)view size:(CGSize)size sizedFilename:(NSString *)sizedFilename {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *newImage = image;
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
            newImage = [image scaleToSize:size];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            view.image = newImage;
        });
        if (![self imageExists:filename]) {
            [self saveImage:image filename:filename];
        }
        if (!CGSizeEqualToSize(size, CGSizeZero) && ![self imageExists:sizedFilename]) {
            [self saveImage:newImage filename:sizedFilename];
        }
    });
}

- (void)downloadImage:(NSString *)filename imageView:(UIImageView *)imageView size:(CGSize)size sizedFilename:(NSString *)sizedFilename {
    NSURL *imageURL = [NSURL URLWithString:[RSHost stringByAppendingFormat:@"/%@", filename]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:[[NSURLRequest alloc] initWithURL:imageURL]];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[UIImage class]]) {
            [self setImage:(UIImage *)responseObject filename:filename toView:imageView size:size sizedFilename:sizedFilename];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Image error: %@, %@", filename, error);
    }];
    [operation start];
}

# pragma mark - uploads

- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath withName:(NSString *)newName {
    TDPostUpload *upload = [[TDPostUpload alloc] initWithVideoPath:localVideoPath thumbnailPath:localPhotoPath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDPostUploadStarted" object:upload userInfo:nil];
}

- (void)uploadAvatarImage:(NSString *)localImagePath withName:(NSString *)newName {
    TDPostUpload *upload = [[TDPostUpload alloc] initWithAvatarPath:localImagePath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDAvatarUploadStarted" object:upload userInfo:nil];
}

#pragma mark - Failures
-(void)logOutUser
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LOG_OUT_NOTIFICATION
                                                        object:nil
                                                      userInfo:nil];
}

@end
