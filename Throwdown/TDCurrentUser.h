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
@property (nonatomic) BOOL fbPublishPermission;

+ (TDCurrentUser *)sharedInstance;
- (void)updateFromDictionary:(NSDictionary *)dictionary;
- (BOOL)isRegisteredForPush;
- (BOOL)isLoggedIn;
- (void)logout;
- (void)registerForPushNotifications:(NSString *)message;
- (void)registerDeviceToken:(NSString *)token;
- (TDUser *)currentUserObject;
- (void)registerFacebookAccessToken:(NSString *)token expiresAt:(NSDate *)expiresAt userId:(NSString *)userId identifier:(NSString *)identifier;
- (void)unlinkFacebook;
- (BOOL)canPostToFacebook;

@end
