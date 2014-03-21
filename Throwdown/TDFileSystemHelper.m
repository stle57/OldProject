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

@end
