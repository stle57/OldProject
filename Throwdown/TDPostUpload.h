//
//  TDPostUpload.h
//  Throwdown
//
//  Created by Andrew C on 3/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUploadProgressDelegate.h"

@interface TDPostUpload : NSObject

@property (nonatomic) NSString *persistedVideoPath;
@property (nonatomic) NSString *persistedPhotoPath;

- (id)initWithVideoPath:(NSString *)videoPath thumbnailPath:(NSString *)thumbnailPath newName:(NSString *)newName;
- (id)initWithAvatarPath:(NSString *)avatarPath newName:(NSString *)filename;
- (void)retryUpload;
- (void)setDelegate:(id<TDUploadProgressDelegate>)delegate;
- (CGFloat)totalProgress;

@end
