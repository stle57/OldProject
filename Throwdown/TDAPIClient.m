//
//  TDAPIClient.m
//  Throwdown
//
//  Created by Andrew C on 2/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDAPIClient.h"
#import "AFNetworking.h"
#import "TDConstants.h"
#import "TDCurrentUser.h"
#import "TDFileSystemHelper.h"
#import "TDDeviceInfo.h"
#import "UIImage+Resizing.h"
#import "TDViewControllerHelper.h"
#import "TDURLHelper.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "TDDeviceInfo.h"

@interface TDAPIClient ()

@property (strong, nonatomic) AFHTTPRequestOperationManager *httpManager;
@property (strong, nonatomic) AFHTTPRequestOperation *credentialsTask;
@property (nonatomic) NSMutableArray *currentVideoDownloads;
@end

@implementation TDAPIClient

#pragma mark - init

+ (TDAPIClient *)sharedInstance {
    static TDAPIClient *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDAPIClient alloc] init];
    });
    return _sharedInstance;
}

+ (TDToastViewController*)toastControllerDelegate {
    static TDToastViewController *_toastControllerDelegate = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^ {
        _toastControllerDelegate = [[TDToastViewController alloc] init];
    });
    return _toastControllerDelegate;
}

- (id)init {
    self = [super init];
    if (self) {
        self.httpManager = [AFHTTPRequestOperationManager manager];
    }
    return self;
}

- (void)dealloc {
    self.httpManager = nil;
    self.credentialsTask = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - api calls

- (void)validateCredentials:(NSDictionary *)parameters success:(void (^)(NSDictionary *response))success failure:(void (^)())failure {

    // cancels any previous request
    [self.credentialsTask cancel];

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/validate.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    self.credentialsTask = [self.httpManager POST:url parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            success((NSDictionary *)responseObject);
        } else {
            failure();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in validation call: %@", [error localizedDescription]);
        // -999 = ignore cancelled as we do that on purpose but don't want the callback to be called
        if ([error code] != -999) {
            failure();
        }
    }];
}

- (void)signupUser:(NSDictionary *)userAttributes callback:(void (^)(BOOL success, NSDictionary *user))callback
{
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/users.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager POST:url parameters:@{@"user": userAttributes, @"uuid": [TDDeviceInfo uuid]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue], [response objectForKey:@"user"]);
            } else {
                callback(NO, nil);
            }
        } else {
            debug NSLog(@"ERROR in signup response, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in signup call: %@", [error localizedDescription]);
        callback(NO, nil);
    }];
}

- (void)loginUser:(NSString *)email withPassword:(NSString *)password callback:(void (^)(BOOL success, NSDictionary *user))callback
{
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/users/sign_in.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];

    // We're keeping email param name for backward compatibility
    [self.httpManager POST:url parameters:@{@"user": @{ @"email": email, @"password": password }, @"uuid": [TDDeviceInfo uuid]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue], [response objectForKey:@"user"]);
            } else {
                callback(NO, nil);
            }
        } else {
            debug NSLog(@"ERROR in signup response, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in signup call: %@", [error localizedDescription]);
        callback(NO, nil);
    }];
}

- (void)updateCurrentUser:(NSString *)token callback:(void (^)(BOOL success, NSDictionary *user))callback {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/users/me.json?user_token=%@", [TDConstants getBaseURL], token];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue], [response objectForKey:@"user"]);
            } else {
                callback(NO, nil);
            }
        } else {
            debug NSLog(@"ERROR in user update response, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in user update call: %@", [error localizedDescription]);
        callback(NO, nil);
        if (error && [operation.response statusCode] == 401) {
            [[NSNotificationCenter defaultCenter] postNotificationName:LOG_OUT_NOTIFICATION object:nil userInfo:nil];
        }
    }];
}

- (void)resetPassword:(NSString *)requestString callback:(void (^)(BOOL success, NSDictionary *user))callback
{
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/users/password.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];

    [self.httpManager POST:url parameters:@{@"user": @{ @"email": requestString}} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue], response);
            } else {
                callback(NO, response);
            }
        } else {
            debug NSLog(@"ERROR in reset password response, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in reset password call: %@", [error localizedDescription]);
        callback(NO, nil);
    }];
}

- (void)getUserSettings:(NSString *)userToken success:(void (^)(NSDictionary *settings))success failure:(void (^)(void))failure {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/users/%@/edit.json?user_token=%@", [TDCurrentUser sharedInstance].userId, userToken]];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success([responseObject objectForKey:@"user"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure();
        }
    }];
}

-(void)editUserWithName:(NSString *)name email:(NSString *)email username:(NSString *)username phone:(NSString *)phone bio:(NSString *)bio picture:(NSString *)pictureFileName location:(NSString*)location callback:(void (^)(BOOL success, NSDictionary *user))callback
{
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/users/%@.json", [TDCurrentUser sharedInstance].userId]];

    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];

    // Avoid any nils in the dictionary
    NSNull *null = [NSNull null];
    NSDictionary *params = @{@"user": @{ @"name": (name ? name : null),
                                     @"username": (username ?username : null),
                                 @"phone_number": (phone ? phone : null),
                                        @"email": (email ? email : null),
                                          @"bio": (bio ? bio : null),
                                      @"picture": (pictureFileName ? pictureFileName : null),
                                      @"location": (location ? location : null)
                             }, @"user_token": [TDCurrentUser sharedInstance].authToken};
    [self.httpManager PUT:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;

            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue], [response objectForKey:@"user"]);
            } else {
                callback(NO, [response objectForKey:@"errors"]);
            }
        } else {
            debug NSLog(@"ERROR in edit user response, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in edit user call: %@", [error localizedDescription]);
        callback(NO, error.userInfo);
    }];
}

-(void)changePasswordFrom:(NSString *)oldPassword newPassword:(NSString *)newPassword confirmPassword:(NSString *)confirmPassword callback:(void (^)(BOOL success, NSDictionary *user))callback
{
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/change_password.json"]];

    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];

    // Avoid any nils in the dictionary
    NSNull *null = [NSNull null];
    NSDictionary *params = @{@"user": @{ @"current_password": (oldPassword ? oldPassword : null),
                                         @"password": (newPassword ? newPassword : null),
                                         @"password_confirmation": (confirmPassword ? confirmPassword : null)
                                         }, @"user_token": [TDCurrentUser sharedInstance].authToken};
    [self.httpManager PUT:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;

            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue], [response objectForKey:@"user"]);
            } else {
                callback(NO, [response objectForKey:@"errors"]);
            }
        } else {
            debug NSLog(@"ERROR in change password response, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in edit user call: %@", [error localizedDescription]);
        callback(NO, error.userInfo);
    }];
}

- (void)getPushNotificationSettingsForUserToken:(NSString *)userToken success:(void (^)(NSDictionary *pushNotifications))success failure:(void (^)(void))failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/push_notification_settings.json?user_token=%@", [TDConstants getBaseURL], userToken];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    debug NSLog(@"bundleVersion-%@", TDDeviceInfo.bundleVersion);
    [manager.requestSerializer setValue:TDDeviceInfo.bundleVersion forHTTPHeaderField:kHTTPHeaderBundleVersion];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success([responseObject objectForKey:@"settings"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure();
        }
    }];
}

- (void)sendPushNotificationSettings:(NSDictionary *)pushSettings callback:(void (^)(BOOL success))callback {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/push_notification_settings.json"]];

    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager.requestSerializer setValue:TDDeviceInfo.bundleVersion forHTTPHeaderField:kHTTPHeaderBundleVersion];

//    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
//    for (id key in pushSettings) {
//        NSString * keyEmailStr = [key stringByAppendingString:@"_email"];
//        NSString * keyPushStr = [key stringByAppendingString:@"_push"];
//        NSDictionary *values = pushSettings[key];
//        if (values.count > 1) {
//            settings [keyEmailStr] = values[@"email"];
//            settings [keyPushStr] = values[@"push"];
//        } else {
//            // For the posts_push value
//            settings[keyPushStr] = values[@"value"];
//        }
//    }
    debug NSLog(@"settings to send to server=%@", pushSettings);
    
    NSDictionary *params = @{@"settings": pushSettings, @"user_token": [TDCurrentUser sharedInstance].authToken};
    [self.httpManager PUT:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;

            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue]);
            } else {
                callback(NO);
            }
        } else {
            debug NSLog(@"ERROR in edit user push settings, got: %@", responseObject);
            callback(NO);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in edit user push settings: %@", [error localizedDescription]);
        callback(NO);
    }];
}

- (void)logoutUser {
    [self logoutUserWithDeviceToken:nil];
}

- (void)logoutUserWithDeviceToken:(NSString *)token {
    NSDictionary *params = token != nil ? @{ @"device_token": token } : nil;
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/users/sign_out.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager DELETE:url parameters:params success:nil failure:nil];
}

- (void)registerDeviceToken:(NSString *)token forUserToken:(NSString *)userToken {
    if (token == nil || userToken == nil) {
        debug NSLog(@"device token missing arguments");
        return;
    }
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/device_tokens.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager POST:url parameters:@{@"user_token": userToken, @"device_token": token} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"device token registered");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"device token failed registration");
    }];
}

- (void)getFollowerSettings:(NSNumber*)userId currentUserToken:(NSString *)currentUserToken success:(void (^)(NSArray *users))success failure:(void (^)(void))failure {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/users/%@/followers.json?user_token=%@", userId, currentUserToken]];
    debug NSLog(@"url to follower list=%@", url);
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success([responseObject objectForKey:@"users"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure();
        }
    }];
}

- (void)getFollowingSettings:(NSNumber*)userId currentUserToken:(NSString *)currentUserToken success:(void (^)(NSArray *users))success failure:(void (^)(void))failure {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/users/%@/following.json?user_token=%@", userId, currentUserToken]];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success([responseObject objectForKey:@"users"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure();
        }
    }];

}

- (void)sendInvites:(NSString*)senderName contactList:(NSArray*)contactList callback:(void (^)(BOOL success, NSArray *contacts))callback {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/contacts/invite.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager POST:url parameters:@{@"contacts":contactList, @"from_name":senderName, @"user_token":[TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                debug NSLog(@"success send invites response=%@", [response objectForKey:@"contacts"]);
                callback([success boolValue], [response objectForKey:@"contacts"]);
            } else {
                callback(NO, [response objectForKey:@"contacts"]);
            }
        } else {
            debug NSLog(@"ERROR in send invites, got: %@", [responseObject class]);
            callback(NO, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in send invites: %@", [error localizedDescription]);
        callback(NO, nil);
    }];
}

#pragma mark - Social Networks registration

- (void)registerFacebookAccessToken:(NSString *)token expiresAt:(NSDate *)expiresAt userId:(NSString *)userId identifier:(NSString *)identifier permissions:(NSArray *)permissions callback:(void (^)(BOOL success))callback {
    NSMutableDictionary *identity = [@{
                              @"provider": @"facebook",
                              @"uid": userId,
                              @"access_token": token,
                              @"expires_at": [TDViewControllerHelper getUTCFormatedDate:expiresAt],
                              @"identifier": identifier
                              } mutableCopy];
    if (permissions) {
        [identity setObject:[permissions componentsJoinedByString:@"|"] forKey:@"permissions"];
    }
    [self registerIdentity:identity callback:callback];
}

- (void)deleteFacebookAccessTokenForUID:(NSString *)userId {
    [self deleteIdentity:@{ @"provider": @"facebook", @"uid": userId }];
}

- (void)registerTwitterAccessToken:(NSString *)token tokenSecret:(NSString *)secret userId:(NSString *)userId identifier:(NSString *)identifier callback:(void (^)(BOOL success))callback {
    NSDictionary *identity = @{
                               @"provider": @"twitter",
                               @"uid": userId,
                               @"access_token": token,
                               @"token_secret": secret,
                               @"identifier": identifier
                               };
    [self registerIdentity:identity callback:callback];
}

- (void)deleteTwitterAccessTokenForUID:(NSString *)userId {
    [self deleteIdentity:@{ @"provider": @"twitter", @"uid": userId }];
}

- (void)registerIdentity:(NSDictionary *)identity callback:(void (^)(BOOL success))callback {
    debug NSLog(@"registering identity");
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/identities.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken, @"identity": identity} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"identity registered");
        if (callback) {
            callback(YES);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"identity failed registration %@", error);
        if (callback) {
            callback(NO);
        }
    }];
}

- (void)deleteIdentity:(NSDictionary *)identity {
    debug NSLog(@"deleting token: %@", identity);
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/identities/identity.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager DELETE:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken, @"identity": identity } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"identity deleted");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"identity delete failed %@", error);
    }];
}


#pragma mark - Activity / Notifications

- (void)getActivityForUserToken:(NSString *)userToken success:(void (^)(NSArray *activities))success failure:(void (^)(void))failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/activities.json?user_token=%@", [TDConstants getBaseURL], userToken];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.requestSerializer setValue:TDDeviceInfo.bundleVersion forHTTPHeaderField:kHTTPHeaderBundleVersion];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success([responseObject objectForKey:@"activities"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure();
        }
    }];
}

- (void)updateActivity:(NSNumber *)activityId seen:(BOOL)seen clicked:(BOOL)clicked {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/activities/%@.json", [TDConstants getBaseURL], activityId];
    NSMutableDictionary *params = [@{@"user_token": [TDCurrentUser sharedInstance].authToken} mutableCopy];
    if (seen) {
        [params addEntriesFromDictionary:@{@"seen": @true }];
    }
    if (clicked) {
        [params addEntriesFromDictionary:@{@"clicked": @true }];
    }
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager PUT:url parameters:params success:nil failure:nil]; // Don't care about the result
}


#pragma mark - Download and cache videos

- (BOOL)videoExists:(NSString *)filename {
    return [TDFileSystemHelper videoExists:[NSString stringWithFormat:@"%@%@", filename, FTVideo]];
}

- (void)getVideo:(NSString *)filename callback:(void(^)(NSURL *videoLocation))callback error:(void(^)(void))errorCallback progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progress {
    NSParameterAssert(filename);
    filename = [NSString stringWithFormat:@"%@%@", filename, FTVideo];

    if ([TDFileSystemHelper videoExists:filename]) {
        if (callback) {
            callback([TDFileSystemHelper getVideoLocation:filename]);
        }
        return;
    }

    for (NSDictionary *download in self.currentVideoDownloads) {
        if ([download objectForKey:@"filename"] && [filename isEqualToString:[download objectForKey:@"filename"]]) {
            NSLog(@"Already downloading! Update this code to append a callback");
            return;
        }
    }

    [self.currentVideoDownloads addObject:@{@"filename": filename}];

    NSURL *videoURL = [NSURL URLWithString:[RSHost stringByAppendingFormat:@"/%@", filename]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:[[NSURLRequest alloc] initWithURL:videoURL]];
    operation.responseSerializer = [AFHTTPResponseSerializer serializer];
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (progress && totalBytesRead && totalBytesExpectedToRead) {
            progress(totalBytesRead, totalBytesExpectedToRead);
        }
    }];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self removeVideoDownload:filename];
        if (responseObject && [responseObject isKindOfClass:[NSData class]]) {
            if (![TDFileSystemHelper videoExists:filename]) {
                [TDFileSystemHelper saveData:responseObject filename:filename];
            }
            if (callback) {
                callback([TDFileSystemHelper getVideoLocation:filename]);
            }
        } else if (errorCallback) {
            errorCallback();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Video error: %@, %@", filename, error);
        [self removeVideoDownload:filename];
        if (errorCallback) {
            errorCallback();
        }
    }];
    [operation start];
}

- (void)removeVideoDownload:(NSString *)filename {
    for (int i = 0; i < [self.currentVideoDownloads count]; i++) {
        NSDictionary *download = [self.currentVideoDownloads objectAtIndex:i];
        if ([download objectForKey:@"filename"] && [filename isEqualToString:[download objectForKey:@"filename"]]) {
            [self.currentVideoDownloads removeObjectAtIndex:i];
            return;
        }
    }
}


#pragma mark - Events
- (void)logEvent:(NSString *)event sessionId:(NSNumber *)sessionId withInfo:(NSString *)info source:(NSString *)source {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/events.json", [TDConstants getBaseURL]];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];

    NSMutableDictionary *eventDetails;
    if (sessionId) {
        eventDetails = [@{@"device_session_id": sessionId, @"action": event} mutableCopy];
    } else {
        eventDetails = [@{@"action": event} mutableCopy];
    }
    if (info) {
        [eventDetails setObject:info forKey:@"extras"];
    }
    if (source) {
        [eventDetails setObject:source forKey:@"source"];
    }
    NSMutableDictionary *params = [@{@"event": eventDetails} mutableCopy];
    if ([TDCurrentUser sharedInstance].authToken) {
        [params addEntriesFromDictionary:@{@"user_token": [TDCurrentUser sharedInstance].authToken}];
    }
    [self.httpManager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"event logged: %@", event);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"event failed (%@) %@", event, [error localizedDescription]);
    }];
}

#pragma mark - AppLinks

- (void)logAppLinksVisit:(NSDictionary *)appLinks sourceApplication:(NSString *)sourceApplication {

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (sourceApplication) {
        [params setObject:sourceApplication forKey:@"source_application"];
    }
    if ([appLinks objectForKey:AppLinkTargetKeyName]) {
        [params setObject:[[appLinks objectForKey:AppLinkTargetKeyName] absoluteString] forKey:@"target_url"];
    }
    if ([appLinks objectForKey:AppLinkRefererAppLink]) {
        NSDictionary *referer = [appLinks objectForKey:AppLinkRefererAppLink];
        if ([referer objectForKey:AppLinkRefererAppName]) {
            [params setObject:[referer objectForKey:AppLinkRefererAppName] forKey:@"referer_app_name"];
        }
        if ([referer objectForKey:AppLinkRefererUrl]) {
            [params setObject:[referer objectForKey:AppLinkRefererUrl] forKey:@"referer_url"];
        }
        if ([referer objectForKey:AppLinkRefererTargetUrl]) {
            [params setObject:[referer objectForKey:AppLinkRefererTargetUrl] forKey:@"referer_target_url"];
        }
    }
    if ([appLinks objectForKey:AppLinkUserAgentKeyName]) {
        [params setObject:[appLinks objectForKey:AppLinkUserAgentKeyName] forKey:@"user_agent"];
    }
    if ([appLinks objectForKey:AppLinkExtrasKeyName]) {
        [params setObject:[[appLinks objectForKey:AppLinkExtrasKeyName] description] forKey:@"extras"];
    }

    NSMutableDictionary *request = [[NSMutableDictionary alloc] init];
    [request setObject:params forKey:@"app_links_referral"];
    if ([TDCurrentUser sharedInstance].authToken) {
        [request setObject:[TDCurrentUser sharedInstance].authToken forKey:@"user_token"];
    }

    NSString *url = [NSString stringWithFormat:@"%@/api/v1/app_links_referrals.json", [TDConstants getBaseURL]];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager POST:url parameters:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"app links logged");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"app links failed (%@) %@", appLinks, [error localizedDescription]);
    }];
}


#pragma mark - Device Sessions

- (void)startSession:(NSDictionary *)metrics callback:(void(^)(NSNumber *sessionId))callback {
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/device_sessions.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSMutableDictionary *params = [@{@"device_session": metrics} mutableCopy];
    if ([TDCurrentUser sharedInstance].authToken) {
        [params addEntriesFromDictionary:@{@"user_token": [TDCurrentUser sharedInstance].authToken}];
    }
    [self.httpManager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"session registered");
        if (callback) {
            NSString *idString = (NSString *)[responseObject objectForKey:@"id"];
            callback([NSNumber numberWithInt:[idString intValue]]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"session failed registration %@", [error localizedDescription]);
    }];
}

- (void)updateSession:(NSNumber *)sessionId duration:(double)duration {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/device_sessions/%@.json", [TDConstants getBaseURL], sessionId];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    NSMutableDictionary *params = [@{@"duration": [NSNumber numberWithDouble:duration]} mutableCopy];
    if ([TDCurrentUser sharedInstance].authToken) {
        [params addEntriesFromDictionary:@{@"user_token": [TDCurrentUser sharedInstance].authToken}];
    }
    [self.httpManager PUT:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"session updated");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"session failed update %@", [error localizedDescription]);
    }];
}

- (void)callURL:(NSString *)url {
    debug NSLog(@"GET callUrl %@", url);
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.httpManager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        debug NSLog(@"url call success %@", url);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"url call failed %@ / %@", url, error);
    }];
}

#pragma mark - Feedback Email
- (void)sendFeedbackEmail:(NSString*)body email:(NSString*)email callback:(void (^)(BOOL success))callback{
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:@"/api/v1/feedback.json"];
    self.httpManager.responseSerializer = [AFJSONResponseSerializer serializer];

    NSDictionary *params = @{@"user_token": [TDCurrentUser sharedInstance].authToken,
                             @"feedback": @{
                                 @"body": body,
                                 @"email" : email,
                                 @"bundle_version": [TDDeviceInfo bundleVersion] ? [TDDeviceInfo bundleVersion] : @"",
                                 @"os": [TDDeviceInfo osVersion] ? [TDDeviceInfo osVersion] : @"",
                                 @"model": [TDDeviceInfo device] ? [TDDeviceInfo device] : @"",
                                 @"carrier": [TDDeviceInfo carrier] ? [TDDeviceInfo carrier] : @""
                             }};

    // We're keeping email param name for backward compatibility
    [self.httpManager POST:url parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                callback([success boolValue]);
            } else {
                callback([success boolValue]);
            }
        } else {
            debug NSLog(@"ERROR sending feedback email, got: %@", [responseObject class]);
            callback(NO);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"ERROR in sending feedback email: %@", [error localizedDescription]);
        callback(NO);
    }];
}

#pragma mark Foursquare
- (void)loadNearbyLocations:(NSString*)latLon callback:(void (^)(BOOL success, NSArray *locations))callback {
    NSString *fourSquareClientId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FourSquareClientID"];
    NSString *fourSquareSecretKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FourSquareClientSecret"];
    NSURL *baseURL = [NSURL URLWithString:@"https://api.foursquare.com"];

    NSString *url = [NSString stringWithFormat:@"%@/v2/venues/search", baseURL];
    
    NSDictionary *queryParams = @{@"ll" : latLon,
                                  @"client_id" : fourSquareClientId,
                                  @"client_secret" : fourSquareSecretKey,
                                  @"categoryId" : @"4bf58dd8d48988d175941735,4bf58dd8d48988d1f9941735", // gym, food & drink shop
                                  @"radius" : @"1610", //approx 1 mile
                                  @"v" : @"20140118"};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:url parameters:queryParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            debug NSLog(@"got some data");
            NSDictionary *response = (NSDictionary*)responseObject;
            callback(YES, [[response objectForKey:@"response"] objectForKey:@"venues"]);
        } else {
            debug NSLog(@"did not get location list");
            callback(NO, @[]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get location list Error: %@", error);
        callback(NO, @[]);
    }];
}

- (void)searchForLocation:(NSString*)latLon searchString:(NSString*)searchString callback:(void (^)(BOOL success, NSArray *locations))callback {
    NSString *fourSquareClientId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FourSquareClientID"];
    NSString *fourSquareSecretKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FourSquareClientSecret"];
    NSURL *baseURL = [NSURL URLWithString:@"https://api.foursquare.com"];
    
    NSString *url = [NSString stringWithFormat:@"%@/v2/venues/suggestcompletion", baseURL];
    
    NSDictionary *queryParams = @{@"ll" : latLon,
                                  @"client_id" : fourSquareClientId,
                                  @"client_secret" : fourSquareSecretKey,
                                  @"query" : searchString,
                                  @"v" : @"20140118"};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:url parameters:queryParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            debug NSLog(@"got some data");
            NSDictionary *response = (NSDictionary*)responseObject;
            callback(YES, [[response objectForKey:@"response"] objectForKey:@"minivenues"]);
        } else {
            debug NSLog(@"did not get location list");
            callback(NO, @[]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get location list Error: %@", error);
        callback(NO, @[]);
    }];
}

@end
