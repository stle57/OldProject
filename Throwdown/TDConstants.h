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

// Cloud
static NSString *const RSUsername = @"throwdown";
static NSString *const RSApiKey = @"c93395c50887cf4926d2d24e1d9ed4e7";
static NSString *const RSHost = @"http://tdstore2.throwdown.us";

// HTTP Headers
static NSString *const kHTTPHeaderBundleVersion = @"X-Bundle-Version";

// File types
static NSString *const FTVideo = @".mp4";
static NSString *const FTImage = @".jpg";
static NSString *const CTVideo = @"video/mp4";
static NSString *const CTImage = @"image/jpeg";

static double const kMaxSessionLength = 1800; // in seconds = 30min
static NSString *const kAnalyticsLogfile = @"analyticsLogfile.bin";
static NSString *const kApplicationUUIDKey = @"TDApplicationUUIDKey";

// File locations
static NSString *const kVideoTrimmedFilePath = @"Documents/current_trimmed_video.m4v";
static NSString *const kVideoExportedFilePath = @"Documents/current_exported_video.m4v";
static NSString *const kThumbnailExportFilePath = @"Documents/current_thumbnail.jpg";

static NSString *const kPhotoFilePath = @"Documents/current_photo.jpg";
static NSString *const kRecordedMovieFilePath = @"Documents/current_recorded_video.m4v";
static NSString *const kRecordedTrimmedMovieFilePath = @"Documents/current_recorded_trimmed_video.m4v";

// Recording settings
static int const kMaxRecordingSeconds = 30;

// NSNotification types
static NSString *const TDPostUploadStarted = @"TDPostUploadStarted";
static NSString *const TDNotificationStopPlayers = @"TDNotificationStopPlayers";
static NSString *const TDNotificationUploadComments = @"TDNotificationUploadComments";
static NSString *const TDNotificationUploadCancelled = @"TDNotificationUploadCancelled";
static NSString *const TDNotificationUpdate = @"TDNotificationUpdate";
static NSString *const TDRefreshPostsNotification = @"TDRefreshPostsNotification";
static NSString *const TDUpdateWithUserChangeNotification = @"TDUpdateWithUserChangeNotification";
static NSString *const TDUploadCompleteNotification = @"TDUploadCompleteOK";
static NSString *const TDUploadFailedNotification = @"TDUploadCompleteFailed";
static NSString *const TDAvatarUploadCompleteNotification = @"TDAvatarUploadCompleteOK";
static NSString *const TDAvatarUploadFailedNotification = @"TDAvatarUploadCompleteFailed";

static NSString *const TDFontProximaNovaRegular = @"ProximaNova-Regular";
static NSString *const TDFontProximaNovaSemibold = @"ProximaNova-Semibold";
static CGFloat const TDCommentCellProfileHeight = 18.0;

// 1.27 is the lowest we can go without cutting off the emoji
static CGFloat const TDTextLineHeight = 1.27;

static NSString *const kSpinningAnimation = @"rotationAnimation";

@interface TDConstants : NSObject

#define CELL_IDENTIFIER_POST_VIEW       @"TDPostView"
#define CELL_IDENTIFIER_LIKE_VIEW       @"TDLikeView"
#define CELL_IDENTIFIER_COMMENT_VIEW    @"TDTwoButtonView"
#define CELL_IDENTIFIER_MORE_COMMENTS   @"TDMoreComments"
#define CELL_IDENTIFIER_ACTIVITY        @"TDActivityCell"
#define CELL_IDENTIFIER_PROFILE         @"TDUserProfileCell"
#define CELL_IDENTIFIER_EDITPROFILE     @"TDUserEditCell"
#define TOAST_TAG                       87352
#define COMMENT_MESSAGE_WIDTH           306.0
#define COMMENT_MESSAGE_FONT            [TDConstants fontRegularSized:15.0]
#define BIO_FONT                        [TDConstants fontRegularSized:16.0]
#define TITLE_FONT                      [TDConstants fontRegularSized:19.0]
#define TIME_FONT                       [TDConstants fontLightSized:13.0]
#define USERNAME_FONT                   [TDConstants fontBoldSized:16.0]
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
+ (UIColor *)activityUnseenColor;

+ (UIFont *)fontLightSized:(NSUInteger)size;
+ (UIFont *)fontRegularSized:(NSUInteger)size;
+ (UIFont *)fontSemiBoldSized:(NSUInteger)size;
+ (UIFont *)fontBoldSized:(NSUInteger)size;

+ (NSDictionary *)defaultVideoCompressionSettings;

@end
