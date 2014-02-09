//
//  PostAPI.h
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDPost.h"
#import "TDUserAPI.h"

@interface TDPostAPI : NSObject
+ (TDPostAPI *)sharedInstance;
+ (NSString *)createUploadFileNameFor:(TDUserAPI *)user;

- (void)uploadVideo:(NSString *)fromVideoPath withThumbnail:(NSString *)localPhotoPath newName:(NSString *)newName;
- (void)addPost:(TDPost *)post;
- (void)fetchPostsUpstream;
- (NSArray *)getPosts;
- (UIImage *)getImage:(NSString *)imageName;

@end
