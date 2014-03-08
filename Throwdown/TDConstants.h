//
//  TDConstants.h
//  Throwdown
//
//  Created by Andrew C on 2/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const RSUsername = @"throwdown";
static NSString *const RSApiKey = @"c93395c50887cf4926d2d24e1d9ed4e7";
static NSString *const RSHost = @"http://tdstore2.throwdown.us";

static NSString *const FTVideo = @".mp4";
static NSString *const FTImage = @".jpg";
static NSString *const CTVideo = @"video/mp4";
static NSString *const CTImage = @"image/jpeg";

@interface TDConstants : NSObject

#define CELL_IDENTIFIER_POST_VIEW   @"TDPostView"
#define COMMENT_MESSAGE_WIDTH       268.0
#define COMMENT_MESSAGE_FONT        [UIFont systemFontOfSize:14.0]
#define FULL_POST_INFO_NOTIFICATION @"TDFullPostInfoNotification"

+ (NSString *)getBaseURL;
+ (NSURL *)getStreamingUrlFor:(NSString *)filename;
+ (UIColor *)brandingRedColor;

@end
