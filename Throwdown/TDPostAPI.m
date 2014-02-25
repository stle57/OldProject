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

#define RS_USERNAME @"throwdown"
#define RS_API_KEY @"c93395c50887cf4926d2d24e1d9ed4e7"
#define RS_BUCKET_HOST @"http://tdstore2.throwdown.us"

#define FILE_TYPE_VIDEO @".mp4"
#define FILE_TYPE_IMAGE @".jpg"
#define CONTENT_TYPE_VIDEO @"video/mp4"
#define CONTENT_TYPE_IMAGE @"image/jpeg"

@implementation TDPostAPI
{
    NSMutableDictionary *currentUploads;
    NSMutableArray *posts;
}

+ (TDPostAPI *)sharedInstance
{
    static TDPostAPI *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDPostAPI alloc] init];
    });
    return _sharedInstance;
}

+ (NSString *)createUploadFileNameFor:(TDCurrentUser *)user
{
    return [NSString stringWithFormat:@"%@_%f",user.userId, [[NSDate date] timeIntervalSince1970]];
}

- (id)init
{
    self = [super init];
    if (self) {
        currentUploads = [[NSMutableDictionary alloc] init];
        posts = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadImage:) name:@"TDDownloadPreviewImageNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
    currentUploads = nil;
    posts = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


# pragma mark - posts get/add/remove


-(void)addPost:(NSString *)filename {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/posts.json"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:@{ @"post": @{@"filename": filename}, @"user_token": [TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"JSON: %@", [responseObject class]);
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

- (NSArray *)getPosts
{
    return [posts mutableCopy];
}

- (void)notifyPostsReload
{
    // Notify any views to reload
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TDReloadPostsNotification"
                                                        object:self
                                                      userInfo:nil];
}

# pragma mark - image/video getting/saving

- (NSString *)getCachePath {
    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [cachePathArray lastObject];
}

- (UIImage *)getImage:(NSString *)filename
{
    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
    NSData *data = [NSData dataWithContentsOfFile:filename];
    return [UIImage imageWithData:data];
}

- (void)saveImage:(UIImage*)image filename:(NSString*)filename
{
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

- (void)saveVideo:(NSData *)data filename:(NSString*)filename
{
    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
    [data writeToFile:filename atomically:YES];
}

- (void)downloadImage:(NSNotification*)notification
{
    UIImageView *imageView = notification.userInfo[@"imageView"];
    NSString *filename = [notification.userInfo[@"filename"] stringByAppendingString:FILE_TYPE_IMAGE];

    imageView.image = [self getImage:filename];

    if (imageView.image == nil) {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSURL *imageURL = [NSURL URLWithString:[RS_BUCKET_HOST stringByAppendingFormat:@"/%@", filename]];
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


//            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:photourl]];
//            AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request
//                imageProcessingBlock:nil
//                cacheName:nil
//                success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//
//                }
//                failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
//                    debug NSLog(@"%@", [error localizedDescription]);
//                }];
//            [operation start];



//            UIImage *image = [httpClient downloadImage:coverUrl];
//
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                imageView.image = image;
//                [persistencyManager saveImage:image filename:[coverUrl lastPathComponent]];
//            });
//        });
    }
}



# pragma mark - uploads


- (void)uploadCompleteFor:(NSString *)name
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        int count = [(NSNumber *)[currentUploads objectForKey:name] intValue];
        count++;
        [currentUploads removeObjectForKey:name];
        // Only re-add if we haven't incremented twice already
        if (count < 2) {
            [currentUploads setObject:[[NSNumber alloc] initWithInt:count] forKey:name];
        }
    });
}

- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath newName:(NSString *)newName
{
    [currentUploads setObject:[[NSNumber alloc] initWithInt:0] forKey:newName];

    NSString *newVideoPath = [newName stringByAppendingString:FILE_TYPE_VIDEO];
    NSString *newPhotoPath = [newName stringByAppendingString:FILE_TYPE_IMAGE];

    NSData *imageData = [NSData dataWithContentsOfFile:localPhotoPath];
    [self saveImage:[UIImage imageWithData:imageData] filename:newPhotoPath];
    [self saveVideo:[NSData dataWithContentsOfFile:localVideoPath] filename:newVideoPath];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RSClient *client = [[RSClient alloc] initWithProvider:RSProviderTypeRackspaceUS username:RS_USERNAME apiKey:RS_API_KEY];

        [client authenticate:^{
            debug NSLog(@"Authentication successful");
            [client getContainers:^(NSArray *containers, NSError *jsonError) {

                RSContainer *storage = [containers objectAtIndex:0];

                unsigned long long videoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:localVideoPath error:nil][NSFileSize] unsignedLongLongValue];
                debug NSLog(@"VIDEO FROM %@ TO %@ SIZE %llu", localVideoPath, newVideoPath, videoFileSize);

                RSStorageObject *video = [[RSStorageObject alloc] init];
                video.name = newVideoPath;
                [storage uploadObject:video fromFile:localVideoPath success:^{
//                    [self uploadCompleteFor:newName];
                    debug NSLog(@"Video upload success");
                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    debug NSLog(@"ERROR: Video upload fail");
                }];

                unsigned long long photoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:localPhotoPath error:nil][NSFileSize] unsignedLongLongValue];
                debug NSLog(@"IMAGE FROM %@ TO %@ SIZE %llu", localPhotoPath, newPhotoPath, photoFileSize);

                RSStorageObject *image = [[RSStorageObject alloc] init];
                image.name = newPhotoPath;
                [storage uploadObject:image fromFile:localPhotoPath success:^{
//                    [self uploadCompleteFor:newName];
                    debug NSLog(@"Image upload success");
                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    debug NSLog(@"ERROR: Image upload fail");
                }];

            } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                debug NSLog(@"ERROR: Couldn't find containers");
            }];
        } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            debug NSLog(@"ERROR: Authentication failed");
        }];
    });
}

@end
