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

@interface TDPostAPI ()

@property (strong, atomic) NSMutableArray *currentUploads;

@end


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
        self.currentUploads = [[NSMutableArray alloc] init];
        posts = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadImage:) name:@"TDDownloadPreviewImageNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    self.currentUploads = nil;
    posts = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


# pragma mark - posts get/add/remove


-(void)addPost:(NSString *)filename {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"post": @{@"filename": filename}, @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", [responseObject class]);
        // Not the best way to do this but for now...
        [self fetchPostsUpstream];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Error: %@", error);
    }];

    [self notifyPostsReload];
}

- (void)fetchPostsUpstream {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"] parameters:@{@"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSArray class]]) {
            [posts removeAllObjects];
            for (id postObject in (NSArray *)responseObject) {
                if ([postObject isKindOfClass:[NSDictionary class]]) {
                    [posts addObject:[[TDPost alloc]initWithDictionary:postObject]];
                }
            }
            [self notifyPostsReload];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"HTTP Error: %@", error);
    }];
}

- (NSArray *)getPosts {
    return [posts mutableCopy];
}

- (void)notifyPostsReload {
    // Notify any views to reload
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDReloadPostsNotification"
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

                        // Notify any views to reload
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"TDReloadPostsNotification"
                                                                            object:self
                                                                          userInfo:nil];
                    }
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        NSLog(@"LIKE Error: %@", error);
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

                        // Notify any views to reload
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"TDReloadPostsNotification"
                                                                            object:self
                                                                          userInfo:nil];
                    }
                }
            }
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"UNLIKE Error: %@", error);
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
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSURL *imageURL = [NSURL URLWithString:[RSHost stringByAppendingFormat:@"/%@", filename]];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:[[NSURLRequest alloc] initWithURL:imageURL]];
        operation.responseSerializer = [AFImageResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([responseObject isKindOfClass:[UIImage class]]) {
                UIImage *image = (UIImage *)responseObject;
                imageView.image = image;
                [self saveImage:image filename:notification.userInfo[@"filename"]];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            debug NSLog(@"Image error: %@, %@", filename, error);
        }];
        [operation start];
    }
}


# pragma mark - uploads

- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath {
    NSString *newName = [TDPostAPI createUploadFileNameFor:[TDCurrentUser sharedInstance]];
    TDPostUpload *upload = [[TDPostUpload alloc] initWithVideoPath:localVideoPath thumbnailPath:localPhotoPath newName:newName];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDPostUploadStarted" object:upload userInfo:@{@"thumbnailPath": localPhotoPath}];
}

@end
