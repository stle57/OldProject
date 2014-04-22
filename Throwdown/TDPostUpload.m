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
#import "TDFileSystemHelper.h"

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

@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *comment;
@property (nonatomic) NSString *finalVideoName;
@property (nonatomic) NSString *finalPhotoName;
@property (nonatomic) BOOL hasReceivedComment;
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

- (id)initWithVideoPath:(NSString *)videoPath thumbnailPath:(NSString *)thumbnailPath newName:(NSString *)filename {
    self = [super init];
    if (self) {
        self.filename = filename;
        self.hasReceivedComment = NO;

        self.postStatus = UploadNotStarted;

        self.client = [[RSClient alloc] initWithProvider:RSProviderTypeRackspaceUS username:RSUsername apiKey:RSApiKey];

        self.finalVideoName = [self.filename stringByAppendingString:FTVideo];
        self.persistedVideoPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", self.finalVideoName];
        self.videoProgress = 0.0;
        self.videoStatus = UploadNotStarted;

        self.finalPhotoName = [self.filename stringByAppendingString:FTImage];
        self.persistedPhotoPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", self.finalPhotoName];
        self.photoProgress = 0.0;
        self.photoStatus = UploadNotStarted;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(uploadCommentsReceived:)
                                                     name:TDNotificationUploadComments
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cancelUpload:)
                                                     name:TDNotificationUploadCancelled
                                                   object:nil];

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

- (id)initWithAvatarPath:(NSString *)avatarPath newName:(NSString *)filename {
    self = [super init];
    if (self) {
        self.filename = filename;
        self.hasReceivedComment = NO;

        self.postStatus = UploadNotStarted;

        self.client = [[RSClient alloc] initWithProvider:RSProviderTypeRackspaceUS username:RSUsername apiKey:RSApiKey];

        self.finalPhotoName = self.filename;    // already has .jpg at the end
        self.persistedPhotoPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", self.finalPhotoName];
        self.photoProgress = 0.0;
        self.photoStatus = UploadNotStarted;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cancelUpload:)
                                                     name:TDNotificationUploadCancelled
                                                   object:nil];

        // Copy photo syncroniously b/c we use it for thumbnails
        [self copyTempFile:avatarPath to:self.persistedPhotoPath];

        NSLog(@"initWithAvatarPath:%@ %@", avatarPath, filename);

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.photoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.persistedPhotoPath error:nil][NSFileSize] unsignedLongLongValue];

            [self startUploadAvatar];
        });
    }
    return self;
}

- (void)dealloc {
    [self cleanup];
}

- (void)cleanup {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.delegate respondsToSelector:@selector(uploadComplete)]) {
        [self.delegate uploadComplete];
    }
    _delegate = nil; // don't use self.delegate here, can throw exception for unknown reason (related to the start hack?)
}

# pragma mark - notification selectors

- (void)uploadCommentsReceived:(NSNotification *)notification {
    NSString *notificationFilename = (NSString *)[notification.userInfo objectForKey:@"filename"];
    if ([self.filename isEqualToString:notificationFilename]) {
        debug NSLog(@"Received correct comment notification");
        self.hasReceivedComment = YES;
        self.comment = [notification.userInfo objectForKey:@"comment"];
        [self finalizeUpload];
    }
}

- (void)cancelUpload:(NSNotification *)notification {
    NSString *notificationFilename = (NSString *)[notification.userInfo objectForKey:@"filename"];
    if ([self.filename isEqualToString:notificationFilename]) {
        debug NSLog(@"Received cancel notification");
        // TODO: Delete video and image from CDN
        [self cleanup];
    }
}

# pragma mark - progress updates, delegates

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
    NSLog(@"Total progress for %@: %f", self.filename, totalProgress);
    if ([self.delegate respondsToSelector:@selector(uploadDidUpdate:)]) {
        [self.delegate uploadDidUpdate:totalProgress];
    }
}

- (void)setDelegate:(id<TDUploadProgressDelegate>)delegate {
    _delegate = delegate;
    // TODO: This is hacky.
    // It won't start uploading until we have a delegate
    // b/c we assign the delegate async through NSNotification
    if (delegate != nil) {
        [self startUploads];
    }
}

- (void)finalizeUpload {
    if (self.hasReceivedComment &&
        self.photoStatus == UploadCompleted &&
        self.videoStatus == UploadCompleted &&
        self.postStatus  != UploadCompleted) {

        debug NSLog(@"FINALIZING %@", self.filename);
        self.postStatus = UploadStarted;
        [[TDPostAPI sharedInstance] addPost:self.filename comment:self.comment success:^{
            self.postStatus = UploadCompleted;
            [self uploadComplete];
        } failure:^{
            self.postStatus = UploadFailed;
            [self uploadFailed];
        }];
    }
}

- (void)finalizeUploadAvatar {
    if (self.photoStatus == UploadCompleted) {

        NSLog(@"FINALIZING AVATAR %@", self.filename);
        [self uploadComplete];
    }
}

- (void)uploadComplete {
    [self cleanup];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[TDPostAPI sharedInstance] saveImage:[UIImage imageWithContentsOfFile:self.persistedPhotoPath] filename:self.finalPhotoName];
        [TDFileSystemHelper removeFileAt:self.persistedPhotoPath];
        [TDFileSystemHelper removeFileAt:self.persistedVideoPath];
    });
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

- (void)startUploadAvatar {
    if (self.photoStatus == UploadCompleted) {
        [self finalizeUpload];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.client authenticate:^{
                [self.client getContainers:^(NSArray *containers, NSError *jsonError) {
                    self.container = [containers objectAtIndex:0];

                    if (self.photoStatus == UploadNotStarted || self.photoStatus == UploadFailed) {
                        [self uploadFile:UploadTypeImage location:self.persistedPhotoPath storageName:self.finalPhotoName];
                    }

                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    NSLog(@"ERROR AVATAR: Couldn't find containers");
                    [self uploadFailed];
                }];
            } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                NSLog(@"ERROR AVATAR: Authentication failed");
                [self uploadFailed];
            }];
        });
    }
}

- (void)uploadFile:(UploadType)fileType location:(NSString *)filePath storageName:(NSString *)name   {
    NSLog(@"Upload %@ from %@", name, filePath);

    RSStorageObject *storageObject = [[RSStorageObject alloc] init];
    storageObject.name = name;

    [self.container uploadObject:storageObject fromFile:filePath success:^{
        NSLog(@"%@ upload completed", (fileType == UploadTypeVideo ? @"VIDEO" : @"IMAGE"));
        if (fileType == UploadTypeVideo) {
            self.videoStatus = UploadCompleted;
        } else {
            self.photoStatus = UploadCompleted;
            [[NSNotificationCenter defaultCenter] postNotificationName:TDUploadCompleteNotification object:self];
        }
        [self finalizeUpload];
    } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {

        [[NSNotificationCenter defaultCenter] postNotificationName:TDUploadFailedNotification object:self];
        NSLog(@"%@ upload failed", (fileType == UploadTypeVideo ? @"VIDEO" : @"IMAGE"));
        [self uploadFailed:fileType];
    } progressHandler:^(float progress) {
        [self updateProgress:fileType percentage:progress];
        NSLog(@"%@ upload progress: %f", (fileType == UploadTypeVideo ? @"VIDEO" : @"IMAGE"), progress);
    }];
}

- (void)copyTempFile:(NSString *)originalLocation to:(NSString *)newLocation {
    [TDFileSystemHelper removeFileAt:newLocation];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    if (![fm copyItemAtPath:originalLocation toPath:newLocation error:&error]) {
        NSLog(@"Couldn't copy file %@ to %@: %@", originalLocation, newLocation, [error localizedDescription]);
    }
}

@end
