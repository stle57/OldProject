//
//  TDFileSystemHelper.h
//  Throwdown
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

@end
