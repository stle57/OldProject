//
//  TDFileSystemHelper.m
//  Throwdown
//
//  Created by Andrew C on 3/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDFileSystemHelper.h"

@implementation TDFileSystemHelper


+ (void)removeFileAt:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSError *err;
        [fm removeItemAtPath:path error:&err];
        if (err) {
            debug NSLog(@"file remove error, %@", err.localizedDescription);
        }
    }
}

+ (uint64_t)getFreeDiskspace {
//    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];

    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
//        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
//        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    } else {
        debug NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return totalFreeSpace;
}

+ (uint64_t)getTotalDiskspace {
    uint64_t totalSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];

    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
    } else {
        debug NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return totalSpace;
}

+ (BOOL)fileExistsAtPath:(NSString *)path {
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    if (exists) {
        return !isDir;
    }
    return NO;
}

+ (BOOL)directoryExistsAtPath:(NSString *)path {
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return (exists && isDir);
}


# pragma mark - getting and saving cached files

+ (NSString *)getCachePath {
    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [cachePathArray lastObject];
}

+ (BOOL)imageExists:(NSString *)filename {
    return [TDFileSystemHelper fileExistsAtPath:[[self getCachePath] stringByAppendingFormat:@"/%@", filename]];
}

+ (UIImage *)getImage:(NSString *)filename {
    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
    NSData *data = [NSData dataWithContentsOfFile:filename];
    return [UIImage imageWithData:data];
}

+ (void)saveImage:(UIImage*)image filename:(NSString*)filename {
    NSData *data = UIImageJPEGRepresentation(image, 0.99f);
    [self saveData:data filename:filename];
}

+ (void)saveData:(NSData *)data filename:(NSString*)filename {
    filename = [[self getCachePath] stringByAppendingFormat:@"/%@", filename];
    [data writeToFile:filename atomically:YES];
}


@end
