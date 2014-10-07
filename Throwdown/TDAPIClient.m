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

@interface TDAPIClient ()

@property (strong, nonatomic) AFHTTPRequestOperationManager *httpManager;
@property (strong, nonatomic) AFHTTPRequestOperation *credentialsTask;
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
    [self.httpManager POST:url parameters:@{@"user": userAttributes} success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    [self.httpManager POST:url parameters:@{@"user": @{ @"email": email, @"password": password }} success:^(AFHTTPRequestOperation *operation, id responseObject) {
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

-(void)editUserWithName:(NSString *)name email:(NSString *)email username:(NSString *)username phone:(NSString *)phone bio:(NSString *)bio picture:(NSString *)pictureFileName callback:(void (^)(BOOL success, NSDictionary *user))callback
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
                                      @"picture": (pictureFileName ? pictureFileName : null)
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
    [self.httpManager POST:url parameters:@{@"contacts":contactList, @"user_token":[TDCurrentUser sharedInstance].authToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSNumber *success = [response objectForKey:@"success"];
            if (success && [success boolValue]) {
                debug NSLog(@"success response=%@", [response objectForKey:@"contacts"]);
                callback([success boolValue], [response objectForKey:@"contacts"]);
            } else {
                callback(NO, [response objectForKey:@"contacts"]);
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


#pragma mark - set or get cached images from web and resizing image to fit view

- (void)setImage:(NSDictionary *)options {
    UIImageView *imageView = options[@"imageView"];
    NSString *filename = options[@"filename"];

    if ([options objectForKey:@"width"] && [options objectForKey:@"height"]) {
        NSNumber *width = options[@"width"];
        NSNumber *height = options[@"height"];
        NSString *filenameWithSize = [NSString stringWithFormat:@"%@_%@x%@%@",
                                      options[@"filename"],
                                      width,
                                      height,
                                      FTImage];
        CGSize size = CGSizeMake([width floatValue], [height floatValue]);

        // First check for sized image cached
        // Then resize and save larger res image
        // Then download original and save as both original size and resized
        if ([TDFileSystemHelper imageExists:filenameWithSize]) {
            [self setImageFromFile:filenameWithSize toView:imageView size:CGSizeZero sizedFilename:nil];
        } else if ([TDFileSystemHelper imageExists:filenameWithSize]) {
            [self setImageFromFile:filename toView:imageView size:size sizedFilename:filenameWithSize];
        } else {
            [self downloadImage:filename imageView:imageView size:size sizedFilename:filenameWithSize];
        }
    } else {
        if ([TDFileSystemHelper imageExists:filename]) {
            [self setImageFromFile:filename toView:imageView size:CGSizeZero sizedFilename:nil];
        } else {
            [self downloadImage:filename imageView:imageView size:CGSizeZero sizedFilename:nil];
        }
    }
}

- (void)setImageFromFile:(NSString *)filename toView:(UIImageView *)view size:(CGSize)size sizedFilename:(NSString *)sizedFilename {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [TDFileSystemHelper getImage:filename];
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
            image = [image scaleToSize:size];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            view.image = image;
        });
        if (!CGSizeEqualToSize(size, CGSizeZero) && ![TDFileSystemHelper imageExists:sizedFilename]) {
            [TDFileSystemHelper saveImage:image filename:sizedFilename];
        }
    });
}

- (void)setImage:(UIImage *)image filename:(NSString *)filename toView:(UIImageView *)view size:(CGSize)size sizedFilename:(NSString *)sizedFilename {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *newImage = image;
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
            newImage = [image scaleToSize:size];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            view.image = newImage;
        });
        if (![TDFileSystemHelper imageExists:filename]) {
            [TDFileSystemHelper saveImage:image filename:filename];
        }
        if (!CGSizeEqualToSize(size, CGSizeZero) && ![TDFileSystemHelper imageExists:sizedFilename]) {
            [TDFileSystemHelper saveImage:newImage filename:sizedFilename];
        }
    });
}

- (void)downloadImage:(NSString *)filename imageView:(UIImageView *)imageView size:(CGSize)size sizedFilename:(NSString *)sizedFilename {
    NSURL *imageURL = [NSURL URLWithString:[RSHost stringByAppendingFormat:@"/%@", filename]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:[[NSURLRequest alloc] initWithURL:imageURL]];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[UIImage class]]) {
            [self setImage:(UIImage *)responseObject filename:filename toView:imageView size:size sizedFilename:sizedFilename];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Image error: %@, %@", filename, error);
    }];
    [operation start];
}

- (void)getVideo:(NSString *)filename callback:(void(^)(NSURL *videoLocation))callback error:(void(^)(void))errorCallback {

    if ([TDFileSystemHelper videoExists:filename]) {
        if (callback) {
            callback([TDFileSystemHelper getVideoLocation:filename]);
        }
        return;
    }

    NSURL *imageURL = [NSURL URLWithString:[RSHost stringByAppendingFormat:@"/%@", filename]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:[[NSURLRequest alloc] initWithURL:imageURL]];
    operation.responseSerializer = [AFHTTPResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Because it could have been downloaded twice (hopefully not)
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
        if (errorCallback) {
            errorCallback();
        }
    }];
    [operation start];
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

@end
