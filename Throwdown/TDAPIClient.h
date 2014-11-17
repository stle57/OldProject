//
//  TDAPIClient.h
//  Throwdown
//
//  Created by Andrew C on 2/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDToastView.h"
#import "TDToastViewController.h"

@interface TDAPIClient : NSObject

+ (TDAPIClient *)sharedInstance;
+ (TDToastViewController*)toastControllerDelegate;

- (void)validateCredentials:(NSDictionary *)parameters success:(void (^)(NSDictionary *response))success failure:(void (^)())failure;
- (void)signupUser:(NSDictionary *)userAttributes callback:(void (^)(BOOL success, NSDictionary *user))callback;
- (void)loginUser:(NSString *)email withPassword:(NSString *)password callback:(void (^)(BOOL success, NSDictionary *user))callback;
- (void)resetPassword:(NSString *)requestString callback:(void (^)(BOOL success, NSDictionary *user))callback;
- (void)getUserSettings:(NSString *)userToken success:(void (^)(NSDictionary *settings))success failure:(void (^)(void))failure;
- (void)editUserWithName:(NSString *)name email:(NSString *)email username:(NSString *)username phone:(NSString *)phone bio:(NSString *)bio picture:(NSString *)pictureFileName location:(NSString*)location callback:(void (^)(BOOL success, NSDictionary *user))callback;
- (void)changePasswordFrom:(NSString *)oldPassword newPassword:(NSString *)newPassword confirmPassword:(NSString *)confirmPassword callback:(void (^)(BOOL success, NSDictionary *user))callback;
- (void)getPushNotificationSettingsForUserToken:(NSString *)userToken success:(void (^)(NSDictionary *pushNotifications))success failure:(void (^)(void))failure;
- (void)sendPushNotificationSettings:(NSDictionary *)pushSettings callback:(void (^)(BOOL success))callback;
- (void)logoutUser;
- (void)logoutUserWithDeviceToken:(NSString *)token;
- (void)updateCurrentUser:(NSString *)token callback:(void (^)(BOOL success, NSDictionary *user))callback;
- (void)registerDeviceToken:(NSString *)token forUserToken:(NSString *)userToken;
- (void)getActivityForUserToken:(NSString *)userToken success:(void (^)(NSArray *activities))success failure:(void (^)(void))failure;
- (void)updateActivity:(NSNumber *)activityId seen:(BOOL)seen clicked:(BOOL)clicked;
- (void)getFollowingSettings:(NSNumber*)userId currentUserToken:(NSString *)currentUserToken success:(void (^)(NSArray *users))success failure:(void (^)(void))failure;
- (void)getFollowerSettings:(NSNumber*)userId currentUserToken:(NSString *)currentUserToken success:(void (^)(NSArray *users))success failure:(void (^)(void))failure;
- (void)sendInvites:(NSString*)senderName contactList:(NSArray*)contactList callback:(void (^)(BOOL success, NSArray *contacts))callback;

- (void)setImage:(NSDictionary *)options;
- (void)getVideo:(NSString *)filename callback:(void(^)(NSURL *videoLocation))callback error:(void(^)(void))errorCallback;

- (void)logEvent:(NSString *)event sessionId:(NSNumber *)sessionId withInfo:(NSString *)info source:(NSString *)source;
- (void)logAppLinksVisit:(NSDictionary *)appLinks sourceApplication:(NSString *)sourceApplication;
- (void)startSession:(NSDictionary *)metrics callback:(void(^)(NSNumber *sessionId))callback;
- (void)updateSession:(NSNumber *)sessionId duration:(double)duration;

- (void)callURL:(NSString *)url;

- (void)registerFacebookAccessToken:(NSString *)token expiresAt:(NSDate *)expiresAt userId:(NSString *)userId identifier:(NSString *)identifier permissions:(NSArray *)permissions callback:(void (^)(BOOL success))callback;
- (void)deleteFacebookAccessTokenForUID:(NSString *)userId;

- (void)registerTwitterAccessToken:(NSString *)token tokenSecret:(NSString *)secret userId:(NSString *)userId identifier:(NSString *)identifier callback:(void (^)(BOOL success))callback;
- (void)deleteTwitterAccessTokenForUID:(NSString *)userId;
- (void)sendFeedbackEmail:(NSString*)body callback:(void (^)(BOOL success))callback;
@end
