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

- (void)uploadAsyncVideo:(NSString *)fromVideoPath withThumbnail:(NSString *)fromPhotoPath newName:(NSString *)newName;
@end
