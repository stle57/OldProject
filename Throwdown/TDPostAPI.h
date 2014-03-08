//
//  PostAPI.h
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDPost.h"
#import "TDCurrentUser.h"

@interface TDPostAPI : NSObject

+ (TDPostAPI *)sharedInstance;
+ (NSString *)createUploadFileNameFor:(TDCurrentUser *)user;

- (void)uploadVideo:(NSString *)localVideoPath withThumbnail:(NSString *)localPhotoPath;
- (void)addPost:(NSString *)filename;
- (void)fetchPostsUpstream;
- (NSArray *)getPosts;
-(void)likePostWithId:(NSNumber *)postId;
-(void)unLikePostWithId:(NSNumber *)postId;
- (UIImage *)getImage:(NSString *)imageName;

@end
