//
//  TDConstants.h
//  Throwdown
//
//  Created by Andrew C on 2/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

const typedef NS_ENUM(NSInteger, TDEnvironment) {
    TDEnvProduction,
    TDEnvStaging,
    TDEnvDevelopment
};

enum {
    kFromProfileScreenType_OwnProfileButton,
    kFromProfileScreenType_OwnProfile,
    kFromProfileScreenType_OtherUser
};
typedef NSUInteger kFromProfileScreenType;

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
static NSString *const TDRefreshPostsNotification = @"TDRefreshPostsNotification";
static NSString *const TDDownloadPreviewImageNotification = @"TDDownloadPreviewImageNotification";

static NSString *const TDFontProximaNovaRegular = @"ProximaNova-Regular";
static NSString *const TDFontProximaNovaSemibold = @"ProximaNova-Semibold";
static CGFloat const TDCommentCellProfileHeight = 18.0;

static NSString *const kSpinningAnimation = @"rotationAnimation";

@interface TDConstants : NSObject

#define CELL_IDENTIFIER_POST_VIEW       @"TDPostView"
#define CELL_IDENTIFIER_LIKE_VIEW       @"TDLikeView"
#define CELL_IDENTIFIER_COMMENT_VIEW    @"TDTwoButtonView"
#define CELL_IDENTIFIER_MORE_COMMENTS   @"TDMoreComments"
#define CELL_IDENTIFIER_ACTIVITY        @"TDActivityCell"
#define CELL_IDENTIFIER_PROFILE         @"TDUserProfileCell"
#define CELL_IDENTIFIER_EDITPROFILE     @"TDUserEditCell"
#define COMMENT_MESSAGE_WIDTH           306.0
#define COMMENT_MESSAGE_FONT            [UIFont systemFontOfSize:14.0]
#define kCommentDefaultText             @"Write a comment..."
#define FULL_POST_INFO_NOTIFICATION     @"TDFullPostInfoNotification"
#define NEW_COMMENT_INFO_NOTICIATION    @"TDNewCommentPostInfoNoticifation"
#define POST_DELETED_NOTIFICATION       @"TDPostDeletedNotification"
#define POST_DELETED_FAIL_NOTIFICATION  @"TDPostDeletedNotificationFail"
#define START_MAIN_SPINNER_NOTIFICATION @"TDMainSpinnerStart"
#define STOP_MAIN_SPINNER_NOTIFICATION  @"TDMainSpinnerStop"
#define LOG_OUT_NOTIFICATION            @"TDLogOutNotification"

+ (TDEnvironment)environment;
+ (NSString *)getBaseURL;
+ (NSString *)flurryKey;
+ (NSURL *)getStreamingUrlFor:(NSString *)filename;

+ (UIColor *)brandingRedColor;
+ (UIColor *)backgroundColor;
+ (UIColor *)borderColor;
+ (UIColor *)headerTextColor;
+ (UIColor *)commentTextColor;
+ (UIColor *)commentTimeTextColor;

+ (UIFont *)fontLightSized:(NSUInteger)size;
+ (UIFont *)fontRegularSized:(NSUInteger)size;
+ (UIFont *)fontSemiBoldSized:(NSUInteger)size;
+ (UIFont *)fontBoldSized:(NSUInteger)size;


@end
