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
#include <math.h>
#import "AssetsLibrary/ALAssetsLibrary.h"

typedef enum {
    UploadTypeVideo,
    UploadTypeImage
} UploadType;

typedef enum {
    UploadNotStarted,
    UploadStarted,
    UploadFailed,
    UploadCompleted,
    UploadNotReceivedFile
} UploadStatus;


@interface TDPostUpload () <UIDocumentInteractionControllerDelegate>

@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *photoPath;
@property (nonatomic) NSString *videoPath;
@property (nonatomic) NSString *comment;
@property (nonatomic) BOOL isPR;
@property (nonatomic) TDPostPrivacy visibility;
@property (nonatomic) BOOL userGenerated;
@property (nonatomic) NSString *finalVideoName;
@property (nonatomic) NSString *finalPhotoName;
@property (nonatomic) BOOL hasReceivedComment;
@property (nonatomic) BOOL videoUpload;
@property (nonatomic) float videoProgress;
@property (nonatomic) float photoProgress;
@property (nonatomic) UploadStatus videoStatus;
@property (nonatomic) UploadStatus photoStatus;
@property (nonatomic) UploadStatus postStatus;
@property (nonatomic) unsigned long long videoFileSize;
@property (nonatomic) unsigned long long photoFileSize;
@property (nonatomic) RSClient *client;
@property (nonatomic) RSContainer *container;
@property (nonatomic) NSArray *shareOptions;
@property (nonatomic) NSDictionary *locationData;
@property (nonatomic) BOOL saveToInstagram;
@property (nonatomic) NSString *instagramLibraryLocation;

@end

@implementation TDPostUpload

- (instancetype)initWithVideoThumbnail:(NSString *)photoPath newName:(NSString *)filename {
    self = [super init];
    if (self) {
        self.filename = filename;
        self.photoPath = photoPath;
        self.videoUpload = YES;
        self.videoStatus = UploadNotReceivedFile;
        [self setupUpload];
    }
    return self;
}

- (instancetype)initWithPhotoPath:(NSString *)photoPath newName:(NSString *)filename {
    self = [super init];
    if (self) {
        self.filename = filename;
        self.photoPath = photoPath;
        self.videoUpload = NO;
        [self setupUpload];
        [self startUploads];
    }
    return self;
}

- (instancetype)initWithVideoPath:(NSString *)videoPath thumbnailPath:(NSString *)thumbnailPath newName:(NSString *)filename {
    self = [super init];
    if (self) {
        self.filename = filename;
        self.photoPath = thumbnailPath;
        [self setupUpload];

        self.videoUpload = YES;
        [self attachVideo:videoPath];
    }
    return self;
}

- (void)attachVideo:(NSString *)videoPath {
    self.videoPath = videoPath;
    self.finalVideoName = [self.filename stringByAppendingString:FTVideo];
    self.persistedVideoPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", self.finalVideoName];
    self.videoProgress = 0.0;
    self.videoStatus = UploadNotStarted;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self copyTempFile:self.videoPath to:self.persistedVideoPath];
        self.videoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.persistedVideoPath error:nil][NSFileSize] unsignedLongLongValue];
        debug NSLog(@"Video File Size %ld", (long)self.videoFileSize);
    });

    [self startUploads];
}

- (void)setupUpload {
    self.hasReceivedComment = NO;
    self.postStatus = UploadNotStarted;

    self.client = [[RSClient alloc] initWithProvider:RSProviderTypeRackspaceUS username:RSUsername apiKey:RSApiKey];

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

    // Copy photo in main thread b/c we use it for thumbnails
    [self copyTempFile:self.photoPath to:self.persistedPhotoPath];

    self.photoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.persistedPhotoPath error:nil][NSFileSize] unsignedLongLongValue];
    debug NSLog(@"Photo File Size %ld", (long)self.photoFileSize);
}

- (void)dealloc {
    [self cleanup];
}

- (void)cleanup {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self.delegate respondsToSelector:@selector(uploadComplete)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadComplete];
            _delegate = nil; // don't use self.delegate here, can throw exception for unknown reason (related to the start hack?)
        });
    }
}

# pragma mark - notification selectors

- (void)uploadCommentsReceived:(NSNotification *)notification {
    NSString *notificationFilename = (NSString *)[notification.userInfo objectForKey:@"filename"];
    NSLog(@"comment received from %@ for %@", self.filename, notificationFilename);
    if ([self.filename isEqualToString:notificationFilename]) {
        debug NSLog(@"Received correct comment notification");
        self.hasReceivedComment = YES;
        self.comment = [notification.userInfo objectForKey:@"comment"];
        self.isPR = [[notification.userInfo objectForKey:@"pr"] boolValue];
        self.visibility = (TDPostPrivacy)[[notification.userInfo objectForKey:@"visibility"] intValue];
        self.userGenerated = [[notification.userInfo objectForKey:@"userGenerated"] boolValue];
        self.shareOptions = [notification.userInfo objectForKey:@"shareOptions"];
        self.locationData = [notification.userInfo objectForKey:@"location"];
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

- (void)updateProgress:(UploadType)uploadType percentage:(float)progress {
    if (uploadType == UploadTypeVideo) {
        self.videoProgress = progress;
    } else {
        self.photoProgress = progress;
    }

    CGFloat totalProgress = [self totalProgress];
    debug NSLog(@"Total progress for %@: %f", self.filename, totalProgress);
    if ([self.delegate respondsToSelector:@selector(uploadDidUpdate:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadDidUpdate:totalProgress];
        });
    }
}

- (void)finalizeUpload {
    NSLog(@"Finalize upload with: %d, %d, %d, %d", self.hasReceivedComment, self.postStatus, self.photoStatus, self.videoStatus);
    if (self.hasReceivedComment &&
        self.postStatus  != UploadCompleted &&
        self.photoStatus == UploadCompleted &&
        (!self.videoUpload || self.videoStatus == UploadCompleted)) {
        debug NSLog(@"FINALIZING %@", self.filename);

        for (NSString *option in self.shareOptions) {
            if ([option isEqualToString:@"instagram"]) {
                self.saveToInstagram = YES;
            }
        }
        // Because we could technically be here many times if upload fails, we only want to save it to assets once.
        if (self.videoUpload && self.instagramLibraryLocation == nil && self.saveToInstagram) {
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:self.persistedVideoPath] completionBlock:^(NSURL *assetURL, NSError *error) {
                self.instagramLibraryLocation = [assetURL absoluteString];
                [self savePost];
            }];
        } else {
            [self savePost];
        }
    } else if (self.postStatus == UploadCompleted) {
        [self uploadComplete];
    }
}

- (void)savePost {
    self.postStatus = UploadStarted;
    [[TDPostAPI sharedInstance] addPost:self.filename
                                comment:self.comment
                                   isPR:self.isPR
                                   kind:(self.videoUpload ? @"video" : @"photo")
                          userGenerated:self.userGenerated
                              sharingTo:self.shareOptions
                             visibility:self.visibility
                               location:self.locationData
                                success:^(NSDictionary *response) {
                                    self.postStatus = UploadCompleted;
                                    if (self.saveToInstagram) {
                                        NSString *instagramLocation;
                                        if (self.videoUpload) {
                                            instagramLocation = self.instagramLibraryLocation;
                                        } else {
                                            instagramLocation = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@.igo", self.finalPhotoName];
                                            [TDFileSystemHelper copyFileFrom:self.persistedPhotoPath to:instagramLocation];
                                        }

                                        NSDictionary *info = @{@"caption":  (self.comment ? self.comment : @""), @"location": instagramLocation, @"isVideo": [NSNumber numberWithBool:self.videoUpload]};
                                        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationPostToInstagram object:nil userInfo:info];
                                    }
                                    [self uploadComplete];
                                    if ([TDCurrentUser sharedInstance].isNewUser) {
                                        debug NSLog(@"saved first post for new user");
                                        [[TDCurrentUser sharedInstance] isNewUser:NO];

                                    }
                                } failure:^{
                                    self.postStatus = UploadFailed;
                                    [self uploadFailed];
                                }];
}

- (void)uploadComplete {
    [self cleanup];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // TODO: we should be saving it to SDWebImage cache, since this is an old caching system
        [TDFileSystemHelper saveImage:[UIImage imageWithContentsOfFile:self.persistedPhotoPath] filename:self.finalPhotoName];
        [TDFileSystemHelper removeFileAt:self.persistedPhotoPath];
        if (self.videoUpload) {
            [TDFileSystemHelper removeFileAt:self.persistedVideoPath];
        }
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(uploadFailed)]) {
            [self.delegate uploadFailed];
        }
    });
}

- (void)startUploads {
    if (self.photoStatus == UploadCompleted && (!self.videoUpload || self.videoStatus == UploadCompleted)) {
        [self finalizeUpload];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.client authenticate:^{
                [self.client getContainers:^(NSArray *containers, NSError *jsonError) {
                    self.container = [containers objectAtIndex:0];

                    if (self.videoUpload && (self.videoStatus == UploadNotStarted || self.videoStatus == UploadFailed)) {
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

#pragma mark - TDUploadProgressUIDelegate

- (void)setUploadProgressDelegate:(id<TDUploadProgressDelegate>)delegate {
    self.delegate = delegate;
}

- (BOOL)displayProgressBar {
    return YES;
}

- (UIImage *)previewImage {
    return [UIImage imageWithContentsOfFile:self.persistedPhotoPath];
}

- (CGFloat)totalProgress {
    CGFloat progress;
    if (self.videoUpload) {
        progress = (CGFloat)(self.videoFileSize * self.videoProgress + self.photoFileSize * self.photoProgress) / (self.videoFileSize + self.photoFileSize);
    } else {
        progress = (CGFloat)(self.photoFileSize * self.photoProgress) / self.photoFileSize;
    }

    // Random occurance of progress being NaN found (not sure why)
    if (isnan(progress)) {
        progress = 0;
    }
    return progress;
}

- (void)uploadRetry {
    [self startUploads];
}

@end
