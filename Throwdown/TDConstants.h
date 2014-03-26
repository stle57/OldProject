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

static NSString *const TDNotificationStopPlayers = @"TDNotificationStopPlayers";
static NSString *const TDNotificationUploadComments = @"TDNotificationUploadComments";
static NSString *const TDNotificationUploadCancelled = @"TDNotificationUploadCancelled";

static NSString *const TDFontProximaNovaRegular = @"ProximaNova-Regular";

@interface TDConstants : NSObject

#define CELL_IDENTIFIER_POST_VIEW       @"TDPostView"
#define CELL_IDENTIFIER_LIKE_VIEW       @"TDLikeView"
#define CELL_IDENTIFIER_COMMENT_VIEW    @"TDTwoButtonView"
#define CELL_IDENTIFIER_MORE_COMMENTS   @"TDMoreComments"
#define COMMENT_MESSAGE_WIDTH           268.0
#define COMMENT_MESSAGE_FONT            [UIFont systemFontOfSize:14.0]
#define FULL_POST_INFO_NOTIFICATION     @"TDFullPostInfoNotification"
#define NEW_COMMENT_INFO_NOTICIATION    @"TDNewCommentPostInfoNoticifation"
#define POST_DELETED_NOTIFICATION       @"TDPostDeletedNotification"

+ (NSString *)getBaseURL;
+ (NSURL *)getStreamingUrlFor:(NSString *)filename;
+ (UIColor *)brandingRedColor;
+ (UIColor *)headerTextColor;
+ (UIColor *)commentTextColor;
+ (UIColor *)commentTimeTextColor;

@end
