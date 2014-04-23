//
//  TDFileSystemHelper.h
//  ;
//
//  Created by Andrew C on 3/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDFileSystemHelper : NSObject

+ (void)removeFileAt:(NSString *)path;
+ (uint64_t)getFreeDiskspace;
+ (uint64_t)getTotalDiskspace;
+ (BOOL)fileExistsAtPath:(NSString *)path;
+ (BOOL)directoryExistsAtPath:(NSString *)path;


// getting and saving cached files

+ (BOOL)imageExists:(NSString *)filename;
+ (void)saveImage:(UIImage*)image filename:(NSString*)filename;
+ (void)saveData:(NSData *)data filename:(NSString*)filename;
+ (UIImage *)getImage:(NSString *)imageName;

@end
