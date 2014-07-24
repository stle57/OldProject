//
//  UserAPI.m
//  Throwdown
//
//  Created by Andrew C on 1/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserAPI.h"
#import "TDAPIClient.h"
#import "TDUserList.h"
#import "RSClient.h"
#import "TDConstants.h"
#import "AFNetworking.h"
#import <Crashlytics/Crashlytics.h>

@implementation TDUserAPI

+ (TDUserAPI *)sharedInstance
{
    static TDUserAPI *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TDUserAPI alloc] init];
    });
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _currentUser = [TDCurrentUser sharedInstance];
    }
    return self;
}

- (void)dealloc {
    _currentUser = nil;
}

# pragma mark - instance methods

- (void)signupUser:(NSDictionary *)userAttributes callback:(void (^)(BOOL))callback
{
    [[TDAPIClient sharedInstance] signupUser:userAttributes callback:^(BOOL success, NSDictionary *user) {
        if (success) {
            [self.currentUser updateFromDictionary:user];
            [self setCrashlyticsMeta];
        }
        callback(success);
    }];
}

- (void)loginUser:(NSString *)email withPassword:(NSString *)password callback:(void (^)(BOOL))callback
{
    [[TDAPIClient sharedInstance] loginUser:email withPassword:password callback:^(BOOL success, NSDictionary *user) {
        if (success) {
            [self.currentUser updateFromDictionary:user];
            [self setCrashlyticsMeta];
        }
        callback(success);
    }];
}

- (void)resetPassword:(NSString *)requestString callback:(void (^)(BOOL success, NSDictionary *dict))callback
{
    [[TDAPIClient sharedInstance] resetPassword:requestString callback:^(BOOL success, NSDictionary *returnDict) {
        callback(success, returnDict);
    }];
}

- (void)editUserWithName:(NSString *)name email:(NSString *)email username:(NSString *)username phone:(NSString *)phone bio:(NSString *)bio picture:(NSString *)pictureFileName callback:(void (^)(BOOL success, NSDictionary *dict))callback
{
    [[TDAPIClient sharedInstance] editUserWithName:name email:email username:username phone:phone bio:bio picture:pictureFileName callback:^(BOOL success, NSDictionary *user) {
        if (success) {
            debug NSLog(@"---SUCCESS:%@", user);
            if (user) {
                [self.currentUser updateFromDictionary:user];
            }
        }
        callback(success, user);
    }];
}

- (void)changePasswordFrom:(NSString *)oldPassword newPassword:(NSString *)newPassword confirmPassword:(NSString *)confirmPassword callback:(void (^)(BOOL success, NSDictionary *dict))callback {
    [[TDAPIClient sharedInstance] changePasswordFrom:oldPassword
                                         newPassword:newPassword
                                     confirmPassword:confirmPassword
                                            callback:^(BOOL success, NSDictionary *user) {
                                                if (success && user) {
                                                    [self.currentUser updateFromDictionary:user];
                                                }
                                                callback(success, user);
                                            }];
}

- (BOOL)isLoggedIn {
    return [self.currentUser isLoggedIn];
}

- (void)logout {
    [[TDAPIClient sharedInstance] logoutUserWithDeviceToken:self.currentUser.deviceToken];
    [self.currentUser logout];
    [[TDUserList sharedInstance] clearList];
    [self setCrashlyticsMeta];
}

- (void)uploadAvatarImage:(NSString *)localImagePath withName:(NSString *)newName {
    debug NSLog(@"uploadAvatar:%@ %@", localImagePath, newName);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RSClient *client = [[RSClient alloc] initWithProvider:RSProviderTypeRackspaceUS username:RSUsername apiKey:RSApiKey];

        [client authenticate:^{
            [client getContainers:^(NSArray *containers, NSError *jsonError) {
                RSContainer *container = [containers objectAtIndex:0];

                RSStorageObject *storageObject = [[RSStorageObject alloc] init];
                storageObject.name = newName;

                [container uploadObject:storageObject fromFile:localImagePath success:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:TDAvatarUploadCompleteNotification object:self];
                } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                    NSLog(@"ERROR AVATAR: %@", [error localizedDescription]);
                    [[NSNotificationCenter defaultCenter] postNotificationName:TDAvatarUploadFailedNotification object:self];
                }];
            } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                NSLog(@"ERROR AVATAR: Couldn't find containers");
                [[NSNotificationCenter defaultCenter] postNotificationName:TDAvatarUploadFailedNotification object:self];
            }];
        } failure:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            NSLog(@"ERROR AVATAR: Authentication failed");
            [[NSNotificationCenter defaultCenter] postNotificationName:TDAvatarUploadFailedNotification object:self];
        }];
    });
}

- (void)setCrashlyticsMeta {
    if ([[TDUserAPI sharedInstance] isLoggedIn]) {
        [Crashlytics setUserIdentifier:[NSString stringWithFormat:@"%@", self.currentUser.userId]];
        [Crashlytics setUserName:self.currentUser.username];
        [Crashlytics setUserEmail:self.currentUser.email];
    } else {
        [Crashlytics setUserIdentifier:nil];
        [Crashlytics setUserName:nil];
        [Crashlytics setUserEmail:nil];
    }
 }

-(void)getCommunityUserList:(void (^)(BOOL success, NSDictionary* communityList))callback {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    TDCurrentUser *currentUser = [TDCurrentUser sharedInstance];

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/users.json?user_token=%@", currentUser.authToken]];

    debug NSLog(@"url= %@", url);

    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            debug NSLog (@"calling callback");
            NSDictionary *response = (NSDictionary*)responseObject;
            callback(YES, [response objectForKey:@"users"]);
        } else {
            debug NSLog(@"did not get userlist");
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get full HTTP Error: %@", error);
    }];

}
@end
