//
//  PostAPI.m
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPostAPI.h"
#import "NMSSH.h"

//#define VOD_VIDEO_HOST @"ftp.tdvod1.throwdownlabsinc.netdna-cdn.com"
//#define VOD_VIDEO_USER @"tdvod1.throwdownlabsinc"
//#define VOD_VIDEO_PASS @"pobx2u3XVbvHfk"

#define VOD_VIDEO_HOST @"ftp.tdpush1.throwdownlabsinc.netdna-cdn.com"
#define VOD_VIDEO_USER @"tdpush1.throwdownlabsinc"
#define VOD_VIDEO_PASS @"rB9Tvii3vPgNiY"


@implementation TDPostAPI

+ (TDPostAPI *)sharedInstance
{
    static TDPostAPI *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDPostAPI alloc] init];
    });
    return _sharedInstance;
}

+ (NSString *)createUploadFileNameFor:(TDUserAPI *)user
{
    return [NSString stringWithFormat:@"%d_%f",[user getUserId], [[NSDate date] timeIntervalSince1970]];
}

- (void)uploadAsyncVideo:(NSString *)fromLocalVideoPath withThumbnail:(NSString *)fromPhotoPath newName:(NSString *)newName
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NMSSHSession *session = [NMSSHSession connectToHost:VOD_VIDEO_HOST
                                               withUsername:VOD_VIDEO_USER];
        if (session.isConnected) {
            [session authenticateByPassword:VOD_VIDEO_PASS];

            if (session.isAuthorized) {
                NSString *newVideoPath = [@"public_html/" stringByAppendingString:[newName stringByAppendingString:@".mp4"]];
                NSString *newPhotoPath = [@"public_html/" stringByAppendingString:[newName stringByAppendingString:@".jpg"]];
                // TODO: upload jpg thumnail too...

                unsigned long long videoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:fromLocalVideoPath error:nil][NSFileSize] unsignedLongLongValue];
                unsigned long long photoFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:fromPhotoPath error:nil][NSFileSize] unsignedLongLongValue];

                NSLog(@"VIDEO FROM %@ TO %@ SIZE %llu", fromLocalVideoPath, newVideoPath, videoFileSize);
                [session.channel uploadFile:fromLocalVideoPath to:newVideoPath progress:^(NSUInteger prog){
//                    dispatch_sync(dispatch_get_main_queue(), ^{
//                        float percent = (float)prog / (float)videoFileSize;
//                        NSLog(@"PROGESS on main thread %f%%", percent * 100);
//                    });
                    return YES;
                }];
                NSLog(@"PHOTO FROM %@ TO %@ SIZE %llu", fromPhotoPath, newPhotoPath, photoFileSize);
                [session.channel uploadFile:fromLocalVideoPath to:newVideoPath progress:^(NSUInteger prog){
                    return YES;
                }];
                [session disconnect];
            }
        }
    });
}
@end
