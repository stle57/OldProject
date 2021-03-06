//
//  TDConstants.h
//  Throwdown
//
//  Created by Andrew C on 2/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

const typedef NS_ENUM(NSInteger, TDEnvironment) {
    TDEnvProduction,
    TDEnvStaging,
    TDEnvDevelopment
};

const typedef NS_ENUM(NSUInteger, kFeedProfileType) {
    kFeedProfileTypeNone,
    kFeedProfileTypeOwnViaButton,
    kFeedProfileTypeOwn,
    kFeedProfileTypeOther
};

typedef NS_ENUM(NSUInteger, TDPostPrivacy) {
    TDPostPrivacyPublic,
    TDPostPrivacyPrivate,
    TDPostRestricted, // This is not used in the front end, but need it here.  That way we pass on the correct value to the backend
    TDPostSemiPrivate
};

enum {
    kUserListType_Followers,
    kUserListType_Following
};
typedef NSUInteger kUserListType;

enum {
    kInviteType_Email,
    kInviteType_Phone,
    kInviteType_None
};
typedef NSInteger kInviteType;

enum {
    kView1_Loading,
    kView2_Loading,
    kView3_Loading
};
typedef NSInteger kLoadingViewType;

enum {
    kEnjoyView_Rate,
    kRateAppView_Rate,
    kFeedbackView_Rate
};
typedef NSInteger kRateAppViewType;

// for TDNotificationUpdatePost notifications, set user data's "change" field to a NSNumber version of these:
const typedef NS_ENUM(NSUInteger, kUpdatePostType) {
    kUpdatePostTypeLike,
    kUpdatePostTypeUnlike,
    kUpdatePostTypeAddComment,
    kUpdatePostTypeUpdateComment,
    kUpdatePostTypeUpdatePostComment
};

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

static double const kAutomaticRefreshTimeout = 30; // in seconds - minium time between reloading feed after opening app
static double const kMaxSessionLength = 30; // in seconds
static double const kReloadUserListTime = 30 * 60; // in seconds
static NSString *const kAnalyticsLogfile = @"analyticsLogfile.bin";
static NSString *const kApplicationUUIDKey = @"TDApplicationUUIDKey";

// File locations
static NSString *const kVideoTrimmedFilePath = @"Documents/current_trimmed_video.mp4";
static NSString *const kVideoExportedFilePath = @"Documents/current_exported_video.mp4";
static NSString *const kThumbnailExportFilePath = @"Documents/current_thumbnail.jpg";
static NSString *const kAssetsVideoFilePath = @"Documents/current_video.mp4";

static NSString *const kPhotoFilePath = @"Documents/current_photo.jpg";
static NSString *const kRecordedMovieFilePath = @"Documents/current_recorded_video.mov";
static NSString *const kRecordedTrimmedMovieFilePath = @"Documents/current_recorded_trimmed_video.mov";

// Recording settings
static int const kMaxRecordingSeconds = 30;
static double const kMinFileSpaceForRecording = 50 * 1024^2; // 50mb
static double const kGlobalVideoTrimTime = 0.05; // seconds

// Map settings
// Amount of north-to-south distance (measured in meters) to use for the span. (note used for east-to-west too):
static CLLocationDistance const kMapDefaultDistance = 9000;

// Campaign Information
static NSString *const TDCampaginStr = @"campaign";
static NSInteger const kBigImageWidth = 75;
static NSInteger const kBigImageHeight = 50;
static NSInteger const kSmallImageWidth = 45;
static NSInteger const kSmallImageHeight = 45;
// NSNotification types
static NSString *const TDNotificationReloadHome = @"TDNotificationReloadHome";
static NSString *const TDPostUploadStarted = @"TDPostUploadStarted";
static NSString *const TDNotificationUserFollow = @"TDNotificationUserFollow";
static NSString *const TDNotificationUserUnfollow = @"TDNotificationUserUnfollow";
static NSString *const TDNotificationStopPlayers = @"TDNotificationStopPlayers";
static NSString *const TDNotificationUploadComments = @"TDNotificationUploadComments";
static NSString *const TDNotificationUploadCancelled = @"TDNotificationUploadCancelled";
static NSString *const TDNotificationUpdate = @"TDNotificationUpdate";
static NSString *const TDNotificationRemovePost = @"TDNotificationRemovePost";
static NSString *const TDNotificationRemoveComment = @"TDNotificationRemoveComment";
static NSString *const TDNotificationUpdatePost = @"TDNotificationUpdatePost"; // When a post gets a new comment or like, tells feeds to update
static NSString *const TDNotificationRemovePostFailed = @"TDNotificationRemovePostFailed";
static NSString *const TDNotificationRemoveCommentFailed = @"TDNotificationRemoveCommentFailed";
static NSString *const TDNotificationNewCommentPostInfo = @"TDNotificationNewCommentPostInfo";
static NSString *const TDNotificationNewCommentFailed = @"TDNotificationNewCommentFailed";
static NSString *const TDNotificationUpdateCommentFailed = @"TDNotificationUpdateCommentFailed";
static NSString *const TDNotificationUpdatePostCommentFailed = @"TDNotificationUpdatePostCommentFailed";
static NSString *const TDNotificationPauseTapGesture = @"TDNotificationPauseTapGesture";
static NSString *const TDNotificationResumeTapGesture = @"TDNotificationResumeTapGesture";
static NSString *const TDNotificationPostToInstagram = @"TDNotificationPostToInstagram";
static NSString *const TDUpdateWithUserChangeNotification = @"TDUpdateWithUserChangeNotification";
static NSString *const TDUpdateFollowingCount = @"TDUpdateFollowingCount";
static NSString *const TDUpdateFollowerCount = @"TDUpdateFollowerCount";
static NSString *const TDUploadCompleteNotification = @"TDUploadCompleteOK";
static NSString *const TDUploadFailedNotification = @"TDUploadCompleteFailed";
static NSString *const TDAvatarUploadCompleteNotification = @"TDAvatarUploadCompleteOK";
static NSString *const TDAvatarUploadFailedNotification = @"TDAvatarUploadCompleteFailed";
static NSString *const TDRemoveHomeViewControllerOverlay = @"TDRemoveHomeViewControllerOverlay";
static NSString *const TDRemoveRateView= @"TDRemoveRateView";
static NSString *const TDShowFeedbackViewController = @"TDShowFeedbackViewController";
static NSString *const TDPostNotificationDeclined = @"TDPostNotificationDeclined";
static NSString *const TDActivityNavBar = @"TDActivityNavBar";
static NSString *const TDUpdatePostCount = @"TDUpdatePostCount";
static NSString *const TDRemoveGuestViewControllerOverlay = @"TDRemoveGuestViewControllerOverlay";
static NSString *const TDGuestViewControllerSignUp = @"TDGuestViewControllerSignUp";
static NSString *const TDRemoveGuestJoinView = @"TDRemoveGuestJoinView";
static NSString *const TDUserListLoadedFromBackground = @"TDUserListLoadedFromBackground";

static NSString *const TDCommunityValuesStr = @"Our Community Values";
static NSString *const TDValueStr1 = @"\u2022 Always cheer each other on.";
static NSString *const TDValueStr2 = @"\u2022 Constructive tips/feedback welcomed.";
static NSString *const TDValueStr3 = @"\u2022 No negativity!  You will be removed.";
static NSString *const TDFontProximaNovaRegular = @"ProximaNova-Regular";
static NSString *const TDFontProximaNovaSemibold = @"ProximaNova-Semibold";
static CGFloat const kCommentCellUserHeight = 18.0;
static CGFloat const kCommentPadding = 8; // padding between comments
static CGFloat const kCommentMargin = 40; // 30 on left, 10 on right
static CGFloat const kCommentLastPadding = 8; // bottom padding of comments
static CGFloat const kCommentLastPaddingDetail = 25; // same as above for detail view
static NSInteger const kCommentMaxCharacters = 1000; // MAX number of characters allowed in a comment or post

static NSInteger const kMaxShownFollowers = 500; // MAX number of followers/followings we show to a user

// 1.27 is the lowest we can go without cutting off the emoji
static CGFloat const kTextLineHeight = 1.27;

static CGFloat const kHeightOfStatusBar = 64.0;

static NSString *const kSpinningAnimation = @"rotationAnimation";

static NSInteger const kInviteButtonTag = 10001;
static NSInteger const kFollowButtonTag = 20002;
static NSInteger const kFollowingButtonTag = 20003;

@interface TDConstants : NSObject

#define APP_STORE_ID 886061848
#define CELL_IDENTIFIER_POST_VIEW          @"TDPostView"
#define CELL_IDENTIFIER_LIKE_VIEW          @"TDFeedLikeCommentCell"
#define CELL_IDENTIFIER_MORE_COMMENTS      @"TDMoreComments"
#define CELL_IDENTIFIER_COMMENT_DETAILS    @"TDDetailsCommentsCell"
#define CELL_IDENTIFIER_POST_PADDING       @"postPaddingCell"
#define CELL_IDENTIFIER_ACTIVITY           @"TDActivityCell"
#define CELL_IDENTIFIER_PROFILE            @"TDUserProfileCell"
#define CELL_IDENTIFIER_EDITPROFILE        @"TDUserEditCell"
#define CELL_NO_MORE_POSTS                 @"TDNoMorePostsCell"
#define CELL_IDENTIFIER_FOLLOWPROFILE      @"TDFollowProfileCell"
#define CELL_IDENTIFIER_INVITE             @"TDInviteCell"
#define CELL_IDENTIFIER_CREATE_POSTHEADER  @"TDCreatePostHeaderCell"
#define CELL_IDENTIFIER_CREATE_IMAGE_CELL  @"TDPhotoCellCollectionViewCell"
#define CELL_IDENTIFIER_TD_LOCATION        @"TDLocationCell"
#define CELL_IDENTIFIER_REVIEW_APP_CELL    @"TDReviewAppCell"
#define TOAST_TAG                        87352
#define COMMENT_MESSAGE_WIDTH            306.0
#define COMMENT_MESSAGE_FONT_SIZE        15.0
#define COMMENT_MESSAGE_FONT             [TDConstants fontRegularSized:COMMENT_MESSAGE_FONT_SIZE]
#define BIO_FONT                         [TDConstants fontRegularSized:16.0]
#define TIME_FONT                        [TDConstants fontLightSized:14.0]
#define POST_COMMENT_FONT                [TDConstants fontRegularSized:17]
#define kCommentDefaultText              @"Write a comment..."
#define START_MAIN_SPINNER_NOTIFICATION  @"TDMainSpinnerStart"
#define STOP_MAIN_SPINNER_NOTIFICATION   @"TDMainSpinnerStop"
#define LOG_OUT_NOTIFICATION             @"TDLogOutNotification"
#define TD_COMMENT_EVENT_COUNT           5
#define TD_LIKE_EVENT_COUNT              2
#define TD_POST_EVENT_COUNT              10
#define TD_POTRAIT_CELL_HEIGHT           44
#define TD_CELL_BORDER_WIDTH             .5
#define TD_INCREMENT_STRING              @"INCREMENT"
#define TD_DECREMENT_STRING              @"DECREMENT"
#define SCREEN_WIDTH                     [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT                    [UIScreen mainScreen].bounds.size.height
#define TD_MARGIN                        10.0
#define TD_PHOTO_CELL_LENGTH             105.
#define TD_IPHONE_4_KEYBOARD_HEIGHT      216
#define TD_IPHONE_5_KEYBOARD_HEIGHT      216
#define TD_IPHONE_6_KEYBOARD_HEIGHT      225
#define TD_IPHONE_6PLUS_KEYBOARD_HEIGHT  236
#define TD_REVIEW_APP_CELL_POST_NUM      5

+ (TDEnvironment)environment;
+ (NSString *)appScheme;
+ (NSString *)getBaseURL;
+ (NSString *)getShareURL:(NSString *)slug;
+ (NSString *)flurryKey;
+ (NSURL *)getStreamingUrlFor:(NSString *)filename;

+ (UIColor *)brandingRedColor;
+ (UIColor *)darkBackgroundColor;
+ (UIColor *)lightBackgroundColor;
+ (UIColor *)darkTextColor;
+ (UIColor *)disabledTextColor;
+ (UIColor *)headerTextColor;
+ (UIColor *)hashtagColor;
+ (UIColor *)commentTextColor;
+ (UIColor *)commentTimeTextColor;
+ (UIColor *)lightBorderColor;
+ (UIColor *)darkBorderColor;
+ (UIColor *)activityUnseenColor;
+ (UIColor *)helpTextColor;

+ (UIColor *)backgroundColor __attribute((deprecated("use lightBackgroundColor or darkBackgroundColor instead")));
+ (UIColor *)borderColor __attribute((deprecated("use lightBorderColor or darkBorderColor instead")));
+ (UIColor *)cellBorderColor  __attribute((deprecated("use lightBorderColor instead")));

+ (UIFont *)fontLightSized:(NSUInteger)size;
+ (UIFont *)fontRegularSized:(NSUInteger)size;
+ (UIFont *)fontSemiBoldSized:(NSUInteger)size;
+ (UIFont *)fontBoldSized:(NSUInteger)size;
+ (NSString *)getHasAskedForGoalsKey:(NSNumber*)userId initial:(BOOL)initial;
+ (NSDictionary *)defaultVideoCompressionSettings;

@end
