//
//  PostAPI.m
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPostAPI.h"
#import "RSClient.h"
#import "RSContainer.h"
#import "RSStorageObject.h"

#define RS_USERNAME @"throwdown"
#define RS_API_KEY @"c93395c50887cf4926d2d24e1d9ed4e7"

#define FILE_TYPE_VIDEO @".mp4"
#define FILE_TYPE_IMAGE @".jpg"
#define CONTENT_TYPE_VIDEO @"video/mp4"
#define CONTENT_TYPE_IMAGE @"image/jpeg"

@implementation TDPostAPI

+ (TDPostAPI *)sharedInstance
{
    static TDPostAPI *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDPostAPI alloc] init];
    });
    return _sharedInstance;
}

+ (NSString *)createUploadFileNameFor:(TDUserAPI *)user
{
    return [NSString stringWithFormat:@"%d_%f",[user getUserId], [[NSDate date] timeIntervalSince1970]];
}

- (void)uploadAsyncVideo:(NSString *)fromLocalVideoPath withThumbnail:(NSString *)fromPhotoPath newName:(NSString *)newName
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RSClient *client = [[RSClient alloc] initWithProvider:RSProviderTypeRackspaceUS username:RS_USERNAME apiKey:RS_API_KEY];

        [client authenticate:^{
            NSLog(@"Authentication successful");
            [client getContainers:^(NSArray *containers, NSError *jsonError) {

                RSContainer *storage = [containers objectAtIndex:0];

                unsigned long long videoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:fromLocalVideoPath error:nil][NSFileSize] unsignedLongLongValue];
                NSString *newVideoPath = [newName stringByAppendingString:FILE_TYPE_VIDEO];
                NSLog(@"VIDEO FROM %@ TO %@ SIZE %llu", fromLocalVideoPath, newVideoPath, videoFileSize);

                RSStorageObject *video = [[RSStorageObject alloc] init];
                video.name = newVideoPath;
                [storage uploadObject:video fromFile:fromLocalVideoPath success:^{
                    NSLog(@"Video upload success");
                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    NSLog(@"ERROR: Video upload fail");
                }];

                unsigned long long photoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:fromPhotoPath error:nil][NSFileSize] unsignedLongLongValue];
                NSString *newPhotoPath = [newName stringByAppendingString:FILE_TYPE_IMAGE];
                NSLog(@"IMAGE FROM %@ TO %@ SIZE %llu", fromPhotoPath, newPhotoPath, photoFileSize);

                RSStorageObject *image = [[RSStorageObject alloc] init];
                image.name = newPhotoPath;
                [storage uploadObject:image fromFile:fromPhotoPath success:^{
                    NSLog(@"Image upload success");
                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    NSLog(@"ERROR: Image upload fail");
                }];

            } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                NSLog(@"ERROR: Couldn't find containers");
            }];
        } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            NSLog(@"ERROR: Authentication failed");
        }];
    });
}

@end
