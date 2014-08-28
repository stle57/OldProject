//
//  TDCurrentUser.h
//  Throwdown
//
//  Created by Andrew C on 2/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUser.h"

@interface TDCurrentUser : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSNumber *userId;
@property (nonatomic, copy, readonly) NSString *username;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *email;
@property (nonatomic, copy, readonly) NSString *phoneNumber;
@property (nonatomic, copy, readonly) NSString *bio;
@property (nonatomic, copy, readonly) NSString *authToken;
@property (nonatomic, copy, readonly) NSString *deviceToken;
@property (strong, nonatomic, readonly) NSString *picture;

@property (nonatomic, copy, readonly) NSString *fbToken;
@property (nonatomic, copy, readonly) NSString *fbUID;
@property (nonatomic, copy, readonly) NSString *fbIdentifier;
@property (nonatomic, copy, readonly) NSDate *fbTokenExpiration;
@property (nonatomic, copy, readonly) NSArray *fbPermissions;

@property (nonatomic, copy, readonly) NSString *twitterUID;
@property (nonatomic, copy, readonly) NSString *twitterToken;
@property (nonatomic, copy, readonly) NSString *twitterSecret;
@property (nonatomic, copy, readonly) NSString *twitterIdentifier;

+ (TDCurrentUser *)sharedInstance;
- (void)updateFromDictionary:(NSDictionary *)dictionary;
- (BOOL)isRegisteredForPush;
- (BOOL)isLoggedIn;
- (void)logout;
- (void)registerForPushNotifications:(NSString *)message;
- (void)registerDeviceToken:(NSString *)token;
- (TDUser *)currentUserObject;
- (void)registerFacebookAccessToken:(NSString *)token expiresAt:(NSDate *)expiresAt userId:(NSString *)userId identifier:(NSString *)identifier callback:(void (^)(BOOL success))callback;
- (void)unlinkFacebook;
- (void)updateFacebookPermissions;
- (BOOL)canPostToFacebook;
- (BOOL)hasCachedFacebookToken;
- (void)authenticateFacebookWithCachedToken:(void (^)(BOOL success))callback;

- (void)registerTwitterAccessToken:(NSString *)token secret:(NSString *)secret uid:(NSString *)uid identifier:(NSString *)identifier callback:(void (^)(BOOL success))callback;
- (void)unlinkTwitter;
- (BOOL)canPostToTwitter;
- (void)handleTwitterResponseData:(NSData *)data callback:(void (^)(BOOL success))callback;

@end
