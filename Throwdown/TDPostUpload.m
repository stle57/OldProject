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

typedef enum {
    UploadNotStarted,
    UploadStarted,
    UploadFailed,
    UploadCompleted
} UploadStatus;


@interface TDPostUpload ()

@property (nonatomic) NSString *fileName;
@property (nonatomic) NSString *finalVideoName;
@property (nonatomic) NSString *finalPhotoName;
@property (nonatomic) float videoProgress;
@property (nonatomic) float photoProgress;
@property (nonatomic) UploadStatus videoStatus;
@property (nonatomic) UploadStatus photoStatus;
@property (nonatomic) UploadStatus postStatus;
@property (nonatomic) unsigned long long videoFileSize;
@property (nonatomic) unsigned long long photoFileSize;
@property (nonatomic) RSClient *client;
@property (nonatomic) RSContainer *container;
@property (strong, nonatomic) id<TDUploadProgressDelegate> delegate;

@end

@implementation TDPostUpload

- (id)initWithVideoPath:(NSString *)videoPath thumbnailPath:(NSString *)thumbnailPath newName:(NSString *)fileName {
    self = [super init];
    if (self) {
        self.fileName = fileName;

        self.postStatus = UploadNotStarted;

        self.client = [[RSClient alloc] initWithProvider:RSProviderTypeRackspaceUS username:RSUsername apiKey:RSApiKey];

        self.finalVideoName = [self.fileName stringByAppendingString:FTVideo];
        self.persistedVideoPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", self.finalVideoName];
        self.videoProgress = 0.0;
        self.videoStatus = UploadNotStarted;

        self.finalPhotoName = [self.fileName stringByAppendingString:FTImage];
        self.persistedPhotoPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", self.finalPhotoName];
        self.photoProgress = 0.0;
        self.photoStatus = UploadNotStarted;

        // Copy photo syncroniously b/c we use it for thumbnails
        [self copyTempFile:thumbnailPath to:self.persistedPhotoPath];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self copyTempFile:videoPath to:self.persistedVideoPath];
            self.videoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.persistedVideoPath error:nil][NSFileSize] unsignedLongLongValue];
            self.photoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.persistedPhotoPath error:nil][NSFileSize] unsignedLongLongValue];
        });
    }
    return self;
}

- (CGFloat)totalProgress {
    // - 0.05 is for the application server post to register the post
    CGFloat progress =  (CGFloat)(self.videoFileSize * self.videoProgress + self.photoFileSize * self.photoProgress) / (self.videoFileSize + self.photoFileSize);
    if (progress > 0.0 && progress < 0.05) {
        progress = 0;
    } else {
        progress -= 0.05;
    }
    return progress;
}

- (void)updateProgress:(UploadType)uploadType percentage:(float)progress {
    if (uploadType == UploadTypeVideo) {
        self.videoProgress = progress;
    } else {
        self.photoProgress = progress;
    }

    CGFloat totalProgress = [self totalProgress];
    NSLog(@"Total progress for %@: %f", self.fileName, totalProgress);
    if ([self.delegate respondsToSelector:@selector(uploadDidUpdate:)]) {
        [self.delegate uploadDidUpdate:totalProgress];
    }
}

- (void)setDelegate:(id<TDUploadProgressDelegate>)delegate {
    _delegate = delegate;
    // TODO: This is hacky.
    // It won't start uploading until we have a delegate
    // b/c we assign the delegate async through NSNotification
    [self startUploads];
}

- (void)finalizeUpload {
    if (self.photoStatus == UploadCompleted &&
        self.videoStatus == UploadCompleted &&
        self.postStatus  != UploadCompleted) {

        self.postStatus = UploadStarted;
        [[TDPostAPI sharedInstance] addPost:self.fileName success:^{
            self.postStatus = UploadCompleted;
            if ([self.delegate respondsToSelector:@selector(uploadComplete)]) {
                [self.delegate uploadComplete];
            }
            self.delegate = nil;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[TDPostAPI sharedInstance] saveImage:[UIImage imageWithContentsOfFile:self.persistedPhotoPath] filename:self.finalPhotoName];
                [self removeFileAt:self.persistedPhotoPath];
                [self removeFileAt:self.persistedVideoPath];
            });
        } failure:^{
            self.postStatus = UploadFailed;
            [self uploadFailed];
        }];
    }
}

- (void)uploadFailed:(UploadType)uploadType {
    if (uploadType == UploadTypeVideo) {
        self.videoStatus = UploadFailed;
        self.videoProgress = 0.0;
    } else {
        self.photoStatus = UploadFailed;
        self.photoProgress = 0.0;
    }
    [self uploadFailed];
}

- (void)uploadFailed {
    if ([self.delegate respondsToSelector:@selector(uploadFailed)]) {
        [self.delegate uploadFailed];
    }
}

- (void)retryUpload {
    [self startUploads];
}

- (void)startUploads {
    if (self.photoStatus == UploadCompleted && self.videoStatus == UploadCompleted) {
        [self finalizeUpload];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.client authenticate:^{
                [self.client getContainers:^(NSArray *containers, NSError *jsonError) {
                    self.container = [containers objectAtIndex:0];

                    if (self.videoStatus == UploadNotStarted || self.videoStatus == UploadFailed) {
                        [self uploadFile:UploadTypeVideo location:self.persistedVideoPath storageName:self.finalVideoName];
                    }

                    if (self.photoStatus == UploadNotStarted || self.photoStatus == UploadFailed) {
                        [self uploadFile:UploadTypeImage location:self.persistedPhotoPath storageName:self.finalPhotoName];
                    }

                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    debug NSLog(@"ERROR: Couldn't find containers");
                    [self uploadFailed];
                }];
            } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                debug NSLog(@"ERROR: Authentication failed");
                [self uploadFailed];
            }];
        });
    }
}

- (void)uploadFile:(UploadType)fileType location:(NSString *)filePath storageName:(NSString *)name   {
    debug NSLog(@"Upload %@ from %@", name, filePath);

    RSStorageObject *storageObject = [[RSStorageObject alloc] init];
    storageObject.name = name;

    [self.container uploadObject:storageObject fromFile:filePath success:^{
        debug NSLog(@"%@ upload completed", (fileType == UploadTypeVideo ? @"VIDEO" : @"IMAGE"));
        if (fileType == UploadTypeVideo) {
            self.videoStatus = UploadCompleted;
        } else {
            self.photoStatus = UploadCompleted;
        }
        [self finalizeUpload];
    } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        debug NSLog(@"%@ upload failed", (fileType == UploadTypeVideo ? @"VIDEO" : @"IMAGE"));
        [self uploadFailed:fileType];
    } progressHandler:^(float progress) {
        [self updateProgress:fileType percentage:progress];
        debug NSLog(@"%@ upload progress: %f", (fileType == UploadTypeVideo ? @"VIDEO" : @"IMAGE"), progress);
    }];
}

- (void)removeFileAt:(NSString *)location {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:location]) {
        NSError *err;
        [fm removeItemAtPath:location error:&err];
        if (err) {
            debug NSLog(@"file remove error, %@", err.localizedDescription);
        }
    }
}

- (void)copyTempFile:(NSString *)originalLocation to:(NSString *)newLocation {
    [self removeFileAt:newLocation];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    if (![fm copyItemAtPath:originalLocation toPath:newLocation error:&error]) {
        NSLog(@"Couldn't copy file %@ to %@: %@", originalLocation, newLocation, [error localizedDescription]);
    }
}

@end
