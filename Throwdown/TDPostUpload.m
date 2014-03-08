//
//  TDPostUpload.m
//  Throwdown
//
//  Created by Andrew C on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPostUpload.h"
#import "TDPostAPI.h"
#import "TDConstants.h"
#import "RSClient.h"
#import "TDProgressIndicator.h"

typedef enum {
    UploadTypeVideo,
    UploadTypeImage
} UploadType;

@interface TDPostUpload ()

@property (nonatomic) NSString *fileName;
@property (nonatomic) NSString *videoPath;
@property (nonatomic) NSString *photoPath;
@property (nonatomic) float videoProgress;
@property (nonatomic) float photoProgress;
@property (nonatomic) unsigned long long videoFileSize;
@property (nonatomic) unsigned long long photoFileSize;

@end

@implementation TDPostUpload

- (id)initWithVideoPath:(NSString *)videoPath thumbnailPath:(NSString *)thumbnailPath newName:(NSString *)fileName {
    self = [super init];
    if (self) {
        self.videoPath = videoPath;
        self.photoPath = thumbnailPath;
        self.fileName = fileName;
        self.videoProgress = 0.0;
        self.photoProgress = 0.0;
        [self start];
    }
    return self;
}

- (void)updateProgress:(UploadType)uploadType percentage:(float)progress {
    if (uploadType == UploadTypeVideo) {
        self.videoProgress = progress;
    } else {
        self.photoProgress = progress;
    }

    CGFloat totalProgress = (self.videoFileSize * self.videoProgress + self.photoFileSize * self.photoProgress) / (self.videoFileSize + self.photoFileSize);
    NSLog(@"Total progress for %@: %f", self.fileName, totalProgress);

    if (totalProgress == 1.0) {
        [[TDPostAPI sharedInstance] addPost:self.fileName];
    }

    if ([self.delegate respondsToSelector:@selector(uploadDidUpdate:)]) {
        [self.delegate uploadDidUpdate:totalProgress];
    }
}

- (void)start {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *newVideoName = [self.fileName stringByAppendingString:FTVideo];
        NSString *newPhotoName = [self.fileName stringByAppendingString:FTImage];
        NSString *newVideoPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", newVideoName];
        NSString *newPhotoPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", newPhotoName];

        [self saveTempFile:self.videoPath to:newVideoPath];
        [self saveTempFile:self.photoPath to:newPhotoPath];

        RSClient *client = [[RSClient alloc] initWithProvider:RSProviderTypeRackspaceUS username:RSUsername apiKey:RSApiKey];

        [client authenticate:^{
            debug NSLog(@"Authentication successful");
            [client getContainers:^(NSArray *containers, NSError *jsonError) {

                RSContainer *storage = [containers objectAtIndex:0];

                self.videoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:newVideoPath error:nil][NSFileSize] unsignedLongLongValue];
                debug NSLog(@"VIDEO FROM %@ TO %@ SIZE %llu", newVideoPath, newVideoName, self.videoFileSize);

                RSStorageObject *video = [[RSStorageObject alloc] init];
                video.name = newVideoName;
                [storage uploadObject:video fromFile:newVideoPath success:^{
                    debug NSLog(@"Video upload success");
                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    debug NSLog(@"ERROR: Video upload fail");
                } progressHandler:^(float progress) {
                    debug NSLog(@"video upload progress %f", progress);
                    [self updateProgress:UploadTypeVideo percentage:progress];
                }];

                self.photoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:newPhotoPath error:nil][NSFileSize] unsignedLongLongValue];
                debug NSLog(@"IMAGE FROM %@ TO %@ SIZE %llu", newPhotoPath, newPhotoName, self.photoFileSize);

                RSStorageObject *image = [[RSStorageObject alloc] init];
                image.name = newPhotoName;
                [storage uploadObject:image fromFile:newPhotoPath success:^{
                    debug NSLog(@"Image upload success");
                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    debug NSLog(@"ERROR: Image upload fail");
                } progressHandler:^(float progress) {
                    debug NSLog(@"image upload progress %f", progress);
                    [self updateProgress:UploadTypeImage percentage:progress];
                }];


                // TODO: addPost

            } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                debug NSLog(@"ERROR: Couldn't find containers");
            }];
        } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            debug NSLog(@"ERROR: Authentication failed");
        }];
    });
}

- (void)saveTempFile:(NSString *)originalLocation to:(NSString *)newLocation {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:newLocation]) {
        NSError *err;
        [fm removeItemAtPath:newLocation error:&err];
        if (err) {
            debug NSLog(@"file remove error, %@", err.localizedDescription);
        }
    }

    NSError *error;
    if (![fm copyItemAtPath:originalLocation toPath:newLocation error:&error]) {
        NSLog(@"Couldn't copy file %@ to %@: %@", originalLocation, newLocation, [error localizedDescription]);
    }
}

@end
