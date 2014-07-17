//
//  TDPostUpload.h
//  Throwdown
//
//  Created by Andrew C on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUploadProgressDelegate.h"

@interface TDPostUpload : NSObject <TDUploadProgressUIDelegate>

@property (nonatomic) NSString *persistedVideoPath;
@property (nonatomic) NSString *persistedPhotoPath;
@property (nonatomic, assign) id<TDUploadProgressDelegate> delegate;

- (instancetype)initWithVideoThumbnail:(NSString *)photoPath newName:(NSString *)filename;
- (instancetype)initWithPhotoPath:(NSString *)photoPath newName:(NSString *)filename;
- (instancetype)initWithVideoPath:(NSString *)videoPath thumbnailPath:(NSString *)thumbnailPath newName:(NSString *)newName;
- (void)attachVideo:(NSString *)videoPath;

#pragma mark TDUploadProgressUIDelegate
- (void)setUploadProgressDelegate:(id<TDUploadProgressDelegate>)delegate;
- (BOOL)displayProgressBar;
- (UIImage *)previewImage;
- (CGFloat)totalProgress;
- (void)uploadRetry;

@end
