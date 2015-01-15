//
//  TDCurrentUser.m
//  Throwdown
//
//  Created by Andrew C on 2/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDCurrentUser.h"
#import "TDFileSystemHelper.h"
#import "TDAPIClient.h"
#import "UIAlertView+TDBlockAlert.h"
#import "TDAnalytics.h"
#import <FacebookSDK/FacebookSDK.h>
#import <SSKeychain.h>
#import "TDConstants.h"

static NSString *const DATA_LOCATION = @"/Documents/current_user.bin";
static NSString *const kConfirmed = @"YES";
static NSString *const kPushNotificationAsked    = @"push-notification-asked";
static NSString *const kPushNotificationApproved = @"push-notification-approved";

@implementation TDCurrentUser

+ (TDCurrentUser *)sharedInstance
{
    static TDCurrentUser *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        NSData *data = [NSData dataWithContentsOfFile:[NSHomeDirectory() stringByAppendingString:DATA_LOCATION]];
        _sharedInstance = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_sharedInstance == nil) {
            _sharedInstance = [[TDCurrentUser alloc] init];
        }
    });
    return _sharedInstance;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.userId forKey:@"id"];
    [aCoder encodeObject:self.username forKey:@"username"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.email forKey:@"email"];
    [aCoder encodeObject:self.authToken forKey:@"authentication_token"];
    [aCoder encodeObject:self.deviceToken forKey:@"device_token"];
    [aCoder encodeObject:self.phoneNumber forKey:@"phone_number"];
    [aCoder encodeObject:self.bio forKey:@"bio"];
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.picture forKey:@"picture"];

    [aCoder encodeObject:self.postCount forKey:@"post_count"];
    [aCoder encodeObject:self.prCount forKey:@"pr_count"];
    [aCoder encodeObject:self.followerCount forKey:@"follower_count"];
    [aCoder encodeObject:self.followingCount forKey:@"following_count"];

    [aCoder encodeObject:self.fbToken forKey:@"fb_token"];
    [aCoder encodeObject:self.fbUID forKey:@"fb_uid"];
    [aCoder encodeObject:self.fbIdentifier forKey:@"fb_identifer"];
    [aCoder encodeObject:self.fbTokenExpiration forKey:@"fb_token_expiration"];
    [aCoder encodeObject:self.fbPermissions forKey:@"fb_permissions"];

    [aCoder encodeObject:self.twitterToken forKey:@"tw_token"];
    [aCoder encodeObject:self.twitterSecret forKey:@"tw_secret"];
    [aCoder encodeObject:self.twitterUID forKey:@"tw_uid"];
    [aCoder encodeObject:self.twitterIdentifier forKey:@"tw_identifier"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _userId      = [aDecoder decodeObjectForKey:@"id"];
        _username    = [aDecoder decodeObjectForKey:@"username"];
        _name        = [aDecoder decodeObjectForKey:@"name"];
        _email       = [aDecoder decodeObjectForKey:@"email"];
        _authToken   = [aDecoder decodeObjectForKey:@"authentication_token"];
        _deviceToken = [aDecoder decodeObjectForKey:@"device_token"];
        _phoneNumber = [aDecoder decodeObjectForKey:@"phone_number"];
        if ([self nullcheck:[aDecoder decodeObjectForKey:@"bio"]]) {
            _bio     = [aDecoder decodeObjectForKey:@"bio"];
        }
        if ([self nullcheck:[aDecoder decodeObjectForKey:@"location"]]) {
            _location     = [aDecoder decodeObjectForKey:@"location"];
        }
        if ([self nullcheck:[aDecoder decodeObjectForKey:@"picture"]]) {
            _picture = [aDecoder decodeObjectForKey:@"picture"];
        }

        _postCount         = [aDecoder decodeObjectForKey:@"post_count"];
        _prCount           = [aDecoder decodeObjectForKey:@"pr_count"];
        _followerCount     = [aDecoder decodeObjectForKey:@"follower_count"];
        _followingCount    = [aDecoder decodeObjectForKey:@"following_count"];

        _fbToken           = [aDecoder decodeObjectForKey:@"fb_token"];
        _fbUID             = [aDecoder decodeObjectForKey:@"fb_uid"];
        _fbIdentifier      = [aDecoder decodeObjectForKey:@"fb_identifer"];
        _fbTokenExpiration = [aDecoder decodeObjectForKey:@"fb_token_expiration"];
        _fbPermissions     = [aDecoder decodeObjectForKey:@"fb_permissions"];

        _twitterToken      = [aDecoder decodeObjectForKey:@"tw_token"];
        _twitterSecret     = [aDecoder decodeObjectForKey:@"tw_secret"];
        _twitterUID        = [aDecoder decodeObjectForKey:@"tw_uid"];
        _twitterIdentifier = [aDecoder decodeObjectForKey:@"tw_identifier"];

    }
    return self;
}

- (void)updateFromDictionary:(NSDictionary *)dictionary {

    _userId      = [dictionary objectForKey:@"id"];
    _username    = [dictionary objectForKey:@"username"];
    _name        = [dictionary objectForKey:@"name"];
    _email       = [dictionary objectForKey:@"email"];
    _authToken   = [dictionary objectForKey:@"authentication_token"];
    _phoneNumber = [dictionary objectForKey:@"phone_number"];
    if ([self nullcheck:[dictionary objectForKey:@"bio"]]) {
        _bio     = [dictionary objectForKey:@"bio"];
    }
    if ([self nullcheck:[dictionary objectForKey:@"location"]]) {
        _location     = [dictionary objectForKey:@"location"];
    }
    if ([self nullcheck:[dictionary objectForKey:@"picture"]]) {
        _picture     = [dictionary objectForKey:@"picture"];
    }

    _postCount      = [dictionary objectForKey:@"post_count"];
    _prCount        = [dictionary objectForKey:@"pr_count"];
    _followingCount = [dictionary objectForKey:@"following_count"];
    _followerCount  = [dictionary objectForKey:@"follower_count"];

    if ([dictionary objectForKey:@"identities"] && [[dictionary objectForKey:@"identities"] count] > 0) {
        for (NSDictionary *identity in [dictionary objectForKey:@"identities"]) {
            if ([[identity objectForKey:@"provider"] isEqualToString:@"twitter"]) {
                _twitterUID        = [identity objectForKey:@"uid"];
                _twitterIdentifier = [identity objectForKey:@"identifier"];
                _twitterSecret     = [identity objectForKey:@"token_secret"];
                _twitterToken      = [identity objectForKey:@"access_token"];
            } else if ([[identity objectForKey:@"provider"] isEqualToString:@"facebook"]) {
                _fbUID             = [identity objectForKey:@"uid"];
                _fbIdentifier      = [identity objectForKey:@"identifier"];
                _fbToken           = [identity objectForKey:@"access_token"];
                _fbTokenExpiration = [identity objectForKey:@"expires_at"];
                _fbPermissions     = [[identity objectForKey:@"permissions"] componentsSeparatedByString:@"|"];
            }
        }
    }

    // FYI: _deviceToken not part of dictionary
    [self save];

//    if ([TDConstants environment] != TDEnvProduction) {
//        [self resetAskedForPush]; //- This is for testing purposes
//    }
    if ([self isLoggedIn] && [self didAskForPush]) {
        [self registerForRemoteNotificationTypes];
    }
}

- (BOOL)hasCachedFacebookToken {
    return self.fbToken != nil;
}

// Call this when session is closed but we have it cached from the server
- (void)authenticateFacebookWithCachedToken:(void (^)(BOOL success))callback {
    FBAccessTokenData *tokenData = [FBAccessTokenData createTokenFromString:self.fbToken
                                                                permissions:self.fbPermissions
                                                             expirationDate:self.fbTokenExpiration
                                                                  loginType:FBSessionLoginTypeNone
                                                                refreshDate:[NSDate date]];
    if (tokenData) {
        FBSessionTokenCachingStrategy *tokenCache = [[FBSessionTokenCachingStrategy alloc] init];
        [tokenCache cacheFBAccessTokenData:tokenData];

        NSString *fbAppId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FacebookAppID"];

        FBSession *session = [[FBSession alloc] initWithAppID:fbAppId
                                                  permissions:self.fbPermissions
                                              urlSchemeSuffix:nil
                                           tokenCacheStrategy:tokenCache];


        [session openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            if (callback) {
                callback(error == nil && (status == FBSessionStateOpen || status == FBSessionStateOpenTokenExtended));
            }
        }];
        [FBSession setActiveSession:session];
    }
}

- (BOOL)isLoggedIn {
    return self.authToken != nil;
}

- (BOOL)isNewUser {
   return self.newUser;
}

- (void)logout {
    [[TDAnalytics sharedInstance] logEvent:@"logged_out"];
    _userId = nil;
    _username = nil;
    _name = nil;
    _email = nil;
    _phoneNumber = nil;
    _authToken = nil;
    _deviceToken = nil;
    _picture = nil;
    _bio = nil;
    _location = nil;
    _followingCount = nil;
    _followerCount = nil;
    _prCount = nil;
    _postCount = nil;
    _fbToken = nil;
    _fbUID = nil;
    _fbIdentifier = nil;
    _fbTokenExpiration = nil;
    _fbPermissions = nil;
    _twitterToken = nil;
    _twitterSecret = nil;
    _twitterUID = nil;
    _twitterIdentifier = nil;
    [TDFileSystemHelper removeFileAt:[NSHomeDirectory() stringByAppendingString:DATA_LOCATION]];
}

- (void)save {
    NSString *filename = [NSHomeDirectory() stringByAppendingString:DATA_LOCATION];
    [TDFileSystemHelper removeFileAt:filename];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [data writeToFile:filename atomically:YES];
}

- (TDUser *)currentUserObject {
    if (!self.picture) {
        _picture = @"default";
    }

    TDUser *user = [[TDUser alloc] init];
    [user userId:self.userId
        userName:self.username
            name:self.name
         picture:self.picture
             bio:self.bio
        location:self.location
  followingCount:self.followingCount
   followerCount:self.followerCount
         prCount:self.prCount
       postCount:self.postCount];
    return user;
}

- (void)updateCurrentUserInfo {
    [[TDAPIClient sharedInstance] updateCurrentUser:self.authToken callback:^(BOOL success, NSDictionary *user) {
        if (success) {
            [self updateFromDictionary:user];
        }
    }];
}

#pragma mark - Facebook integrations

- (void)registerFacebookAccessToken:(NSString *)token expiresAt:(NSDate *)expiresAt userId:(NSString *)userId identifier:(NSString *)identifier callback:(void (^)(BOOL success))callback {
    // send to api and cache values
    _fbToken           = token;
    _fbUID             = userId;
    _fbIdentifier      = identifier;
    _fbTokenExpiration = expiresAt;
    _fbPermissions     = [FBSession activeSession].permissions;
    [self save];
    [[TDAPIClient sharedInstance] registerFacebookAccessToken:token expiresAt:expiresAt userId:userId identifier:identifier permissions:self.fbPermissions callback:(void (^)(BOOL success))callback];
}

- (void)unlinkFacebook {
    // This method might get called from the AppDelegate when a session is already closed
    if (self.fbUID) {
        [[TDAPIClient sharedInstance] deleteFacebookAccessTokenForUID:[self.fbUID copy]];
        _fbToken           = nil;
        _fbUID             = nil;
        _fbIdentifier      = nil;
        _fbTokenExpiration = nil;
        _fbPermissions     = nil;
        [self save];
    }
}

- (BOOL)canPostToFacebook {
    return (self.fbToken != nil && self.fbPermissions && [self.fbPermissions containsObject:@"publish_actions"]);
}

- (void)updateFacebookPermissions {
    _fbPermissions = [FBSession activeSession].permissions;
    [self save];
}

#pragma mark - Twitter integration

- (void)registerTwitterAccessToken:(NSString *)token secret:(NSString *)secret uid:(NSString *)uid identifier:(NSString *)identifier callback:(void (^)(BOOL success))callback {
    [[TDAPIClient sharedInstance] registerTwitterAccessToken:token
                                                 tokenSecret:secret
                                                      userId:uid
                                                  identifier:identifier
                                                    callback:^(BOOL success) {
                                                        if (success) {
                                                            _twitterToken = token;
                                                            _twitterSecret = secret;
                                                            _twitterUID = uid;
                                                            _twitterIdentifier = identifier;
                                                            [self save];
                                                        }
                                                        if (callback) {
                                                            callback(success);
                                                        }
                                                    }];
}

- (void)unlinkTwitter {
    if (self.twitterUID) {
        [[TDAPIClient sharedInstance] deleteTwitterAccessTokenForUID:[self.twitterUID copy]];
        _twitterToken      = nil;
        _twitterSecret     = nil;
        _twitterUID        = nil;
        _twitterIdentifier = nil;
        [self save];
    }
}

- (BOOL)canPostToTwitter {
    return self.twitterUID != nil;
}

- (void)handleTwitterResponseData:(NSData *)data callback:(void (^)(BOOL success))callback {
    NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableDictionary *credentials = [[NSMutableDictionary alloc] init];
    for (NSString *pair in [responseStr componentsSeparatedByString:@"&"]) {
        NSArray *keyvalue = [pair componentsSeparatedByString:@"="];
        [credentials setObject:[keyvalue lastObject] forKey:[keyvalue firstObject]];
    }
    NSString *screenName = [credentials objectForKey:@"screen_name"];
    if (screenName) {
        [[TDCurrentUser sharedInstance] registerTwitterAccessToken:[credentials objectForKey:@"oauth_token"]
                                                            secret:[credentials objectForKey:@"oauth_token_secret"]
                                                               uid:[credentials objectForKey:@"user_id"]
                                                        identifier:[NSString stringWithFormat:@"@%@", screenName]
                                                          callback:callback];
    } else {
        [[TDAnalytics sharedInstance] logEvent:@"error" withInfo:[credentials description] source:@"TDCurrentUser#handleTwitterResponseData"];
    }

}

#pragma mark - push notification device token

- (void)checkPushNotificationToken {
    debug NSLog(@"APN::checkPushNotificationToken");
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    // Migrate UserDefaults to the permanent Keychain
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"approvedPushNotification"]) {
        [defaults removeObjectForKey:@"approvedPushNotification"];
        [defaults synchronize];
        [SSKeychain setPassword:kConfirmed forService:service account:kPushNotificationApproved];
    }

    NSString *value = [SSKeychain passwordForService:service account:kPushNotificationApproved];
    if ((value && [value isEqualToString:kConfirmed]) || [self isRegisteredForPush]) {
        [self registerForRemoteNotificationTypes];
    }
}

- (BOOL)isRegisteredForPush {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
        UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        return (settings.types != UIUserNotificationTypeNone);
    } else {
        return self.deviceToken != nil;
    }
}

- (BOOL)didAskForPush {
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    // Migrate UserDefaults to the permanent Keychain
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"hasAskedPushNotification"]) {
        [defaults removeObjectForKey:@"hasAskedPushNotification"];
        [defaults synchronize];
        [SSKeychain setPassword:kConfirmed forService:service account:kPushNotificationAsked];
        return true;
    }

    NSString *value = [SSKeychain passwordForService:service account:kPushNotificationAsked];
    return (value && [value isEqualToString:kConfirmed]);
}

- (void)setAskedForPush {
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    [SSKeychain setPassword:kConfirmed forService:service account:kPushNotificationAsked];
}

// Used for resetting push settings during testing
- (void)resetAskedForPush {
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    [SSKeychain setPassword:@"NO" forService:service account:kPushNotificationAsked];
}

- (BOOL)registerForPushNotifications:(NSString *)message {
    if ([[TDCurrentUser sharedInstance] isLoggedIn] && ![self isRegisteredForPush]) {
        // for some reason we don't have the device token stored, so we'll either ask for it if never asked before or register it
        if ([self didAskForPush]) {
            [self registerForRemoteNotificationTypes];
        } else {
            [[TDAnalytics sharedInstance] logEvent:@"notification_asked"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Requested" message:message delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ask me", nil];
            [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    [[TDAnalytics sharedInstance] logEvent:@"notification_accept"];
                    [self registerForRemoteNotificationTypes];
                    
                    [self changeUserPushSettings];
                }
            }];
            return YES;
        }
    }
    return NO;
}

- (void)registerDeviceToken:(NSString *)token {
    [[TDAnalytics sharedInstance] logEvent:@"notification_approved"];
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    [SSKeychain setPassword:kConfirmed forService:service account:kPushNotificationApproved];
	token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (self.deviceToken == nil || ![token isEqualToString:self.deviceToken]) {
        _deviceToken = token;
        [self save];
        [[TDAPIClient sharedInstance] registerDeviceToken:token forUserToken:self.authToken];
    }
}

- (void)registerForRemoteNotificationTypes {
    debug NSLog(@"APN::registerForRemoteNotificationTypes");
    if ([self isLoggedIn]) {
        [self setAskedForPush];
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) { // iOS 8
            debug NSLog(@"  inside IF of APN::registerForRemoteNotificationTypes");
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        } else {
            debug NSLog(@"  inside else of APN::registerForRemoteNotificationTypes");
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
        }
    }
}

- (NSMutableDictionary*)changeUserPushSettings {
    debug NSLog(@"inside changeUserPushSettings");
    NSMutableDictionary *pushSettings = [@{} mutableCopy];
    if ([self isLoggedIn]) {
        if ([self didAskForPush]) {
            [[TDAPIClient sharedInstance] getPushNotificationSettingsForUserToken:[TDCurrentUser sharedInstance].authToken success:^(id settings) {
                if ([settings isKindOfClass:[NSArray class]]) {
                    debug NSLog(@"settings=%@", settings);
                    for (NSDictionary *group in settings) {
                        for (NSDictionary *setting in [group objectForKey:@"keys"]) {
                            if ([setting objectForKey:@"email"] != nil) {
                                NSString *key = [NSString stringWithFormat:@"%@_push", [setting objectForKey:@"key"]];
                                [pushSettings setObject:@1 forKey:key];
                                NSString *key2 = [NSString stringWithFormat:@"%@_email", [setting objectForKey:@"key"]];
                                if ([[setting objectForKey:@"key"]  isEqual: @"follows"] ||
                                    [[setting objectForKey:@"key"]  isEqual: @"friend_joins"]){
                                    [pushSettings setObject:@1 forKey:key2];
                                    debug NSLog(@"key=%@", [setting objectForKey:@"key"]);
                                } else {
                                    [pushSettings setObject:@0 forKey:key2];
                                }

                            } else {
                                NSString *key = [NSString stringWithFormat:@"%@_push", [setting objectForKey:@"key"]];
                                [pushSettings setObject:@1 forKey:key];
                            }
                        }
                    }
                    debug NSLog(@"  changing settings to %@", pushSettings);
                    // Copy settings then call save
                    [[TDAPIClient sharedInstance] sendPushNotificationSettings:pushSettings callback:^(BOOL success) {
                        if (success) {
                        } else {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                            message:@"Sorry, there was an unexpected error while saving your changes"
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"Cancel"
                                                                  otherButtonTitles:@"Try Again", nil];
                            [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                if (alertView.cancelButtonIndex == buttonIndex) {
                                    return;
                                } else {
                                    [self save];
                                }
                            }];
                        }
                    }];
                }
            } failure:^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Sorry, there was an unexpected error while loading the settings"
                                                               delegate:nil
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:nil];
                [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (alertView.cancelButtonIndex == buttonIndex) {
                    } else {
                    }
                }];
            }];
        }
    }
    return pushSettings;
}
- (BOOL)nullcheck:(id)object {
    return (object && ![object isKindOfClass:[NSNull class]]);
}

- (BOOL)didAskForContacts {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"hasAskedForContacts"];
}

- (void)didAskForContacts:(BOOL)yes {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:yes forKey:@"hasAskedContacts"];
    [defaults synchronize];
}

- (void)didAskForPhotos:(BOOL)yes {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:yes forKey:@"hasAskedForPhotos"];
    [defaults synchronize];
}

- (BOOL)didAskForPhotos {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"hasAskedForPhotos"];
}

- (BOOL)didAskForGoalsInitially {
    NSString *key = [TDConstants getHasAskedForGoalsKey:[TDCurrentUser sharedInstance].userId initial:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}

- (void)didAskForGoalsInitially:(BOOL)yes {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [TDConstants getHasAskedForGoalsKey:[TDCurrentUser sharedInstance].userId initial:YES];
    [defaults setBool:yes forKey:key];
    [defaults synchronize];
}

- (BOOL)didAskForGoalsFinal {
    NSString *key = [TDConstants getHasAskedForGoalsKey:[TDCurrentUser sharedInstance].userId initial:NO];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}

- (void)didAskForGoalsFinal:(BOOL)yes {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [TDConstants getHasAskedForGoalsKey:[TDCurrentUser sharedInstance].userId initial:NO];
    [defaults setBool:yes forKey:key];
    [defaults synchronize];
}

- (void)resetAskedForGoals {
    NSString *key = [TDConstants getHasAskedForGoalsKey:[TDCurrentUser sharedInstance].userId initial:YES];
    NSString *key2 = [TDConstants getHasAskedForGoalsKey:[TDCurrentUser sharedInstance].userId initial:NO];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults removeObjectForKey:key];
    [defaults removeObjectForKey:key2];
    
    [defaults synchronize];

}
@end
