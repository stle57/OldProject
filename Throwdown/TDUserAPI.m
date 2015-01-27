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
#import "TDDeviceInfo.h"
#import <Crashlytics/Crashlytics.h>
#import "TDDeviceInfo.h"

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
            [[TDCurrentUser sharedInstance] isNewUser:YES];
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

- (void)editUserWithName:(NSString *)name email:(NSString *)email username:(NSString *)username phone:(NSString *)phone bio:(NSString *)bio picture:(NSString *)pictureFileName location:(NSString*)location callback:(void (^)(BOOL success, NSDictionary *dict))callback
{
    [[TDAPIClient sharedInstance] editUserWithName:name email:email username:username phone:phone bio:bio picture:pictureFileName location:location callback:^(BOOL success, NSDictionary *user) {
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
    [[TDUserList sharedInstance] clearList];
    [[TDAPIClient sharedInstance] logoutUserWithDeviceToken:self.currentUser.deviceToken];
    [self.currentUser logout];
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

- (void)getCommunityUserList:(void (^)(BOOL success, NSArray *communityList))callback {
    NSAssert(callback != nil, @"getCommunityUserList callback required");

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    TDCurrentUser *currentUser = [TDCurrentUser sharedInstance];

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/users.json?user_token=%@", currentUser.authToken]];

    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary*)responseObject;
            callback(YES, [response objectForKey:@"users"]);
        } else {
            debug NSLog(@"did not get userlist");
            callback(NO, @[]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get community list Error: %@", error);
        callback(NO, @[]);
    }];
}

- (void)followUser:(NSNumber *)userID callback:(void (^)(BOOL))callback {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/users/%@/follow.json", [TDConstants getBaseURL], userID];

    // posting this notificaiton makes all UI update immidiately
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUserFollow object:userID];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager POST:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken }
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              debug NSLog(@"Following %@", userID);
              callback(YES);
              [[TDCurrentUser sharedInstance] updateCurrentUserInfo];
              // Send notification to update user profile stat button-add
              [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[[TDCurrentUser sharedInstance] currentUserObject].userId userInfo:@{TD_INCREMENT_STRING: @1}];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              // Triggering this will make UI revert the previous update
              [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUserUnfollow object:userID];
              debug NSLog(@"Error following: %@ with error%@", userID, error);
              callback(NO);
          }];

}

- (void)unFollowUser:(NSNumber *)userID callback:(void (^)(BOOL))callback {
    NSString *url = [NSString stringWithFormat:@"%@/api/v1/users/%@/follow.json", [TDConstants getBaseURL], userID];

    // posting this notificaiton makes all UI update immidiately
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUserUnfollow object:userID];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager DELETE:url parameters:@{ @"user_token": [TDCurrentUser sharedInstance].authToken }
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              debug NSLog(@"Unfollowed %@", userID);
              callback(YES);
              [[TDCurrentUser sharedInstance] updateCurrentUserInfo];
              // send notification to update user follow count-subtract
              [[NSNotificationCenter defaultCenter] postNotificationName:TDUpdateFollowingCount object:[[TDCurrentUser sharedInstance] currentUserObject].userId userInfo:@{TD_DECREMENT_STRING: @1}];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              // Triggering this will make UI revert the previous update
              [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUserFollow object:userID];

              debug NSLog(@"Error unfollowing: %@ with error%@", userID, error);
              callback(NO);
          }];
}

- (void)getSuggestedUserList:(void (^)(BOOL success, NSArray *suggestedList))callback {
    NSAssert(callback != nil, @"getSuggestedUserList callback required");
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    TDCurrentUser *currentUser = [TDCurrentUser sharedInstance];
    
    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/users/featured.json?user_token=%@", currentUser.authToken]];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary*)responseObject;
            callback(YES, [response objectForKey:@"users"]);
        } else {
            debug NSLog(@"did not get userlist");
            callback(NO, @[]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get community list Error: %@", error);
        callback(NO, @[]);
    }];
}

- (void)getChallengersList:(NSString*)tagName callback:(void (^)(BOOL success, NSArray *challengerList))callback {
    NSAssert(callback != nil, @"getChallengersLists callback required");

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    TDCurrentUser *currentUser = [TDCurrentUser sharedInstance];

    NSString *url = [[TDConstants getBaseURL] stringByAppendingString:[NSString stringWithFormat:@"/api/v1/tags/%@/users.json?user_token=%@&bundle_version=%@", tagName, currentUser.authToken,  [TDDeviceInfo bundleVersion] ? [TDDeviceInfo bundleVersion] : @""]];
    debug NSLog(@"url to load challengers=%@", url);
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *response = (NSDictionary*)responseObject;
            callback(YES, [response objectForKey:@"users"]);
        } else {
            debug NSLog(@"did not get challengers list");
            callback(NO, @[]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        debug NSLog(@"Get challengers list Error: %@", error);
        callback(NO, @[]);
    }];
}
- (void)getGoalsAndInterests:(void (^)(NSDictionary *dict))callback {

    [[TDAPIClient sharedInstance] getGoalsAndInterests:^(NSDictionary *goalsAndInterests) {
            callback(goalsAndInterests);
    } ];
}

//- (void)saveGoalsAndInterestsForUser:goalsList interestsList:(NSArray*)interestsList callback:(void (^)(BOOL success))callback{
//    NSArray *goalsArray = [[NSMutableArray alloc] init];
//    goalsArray = [self createArray:goalsList];
//
//    NSArray *interestsArray = [[NSMutableArray alloc] init];
//    interestsArray = [self createArray:interestsList];
//
//    [[TDAPIClient sharedInstance] saveGoalsAndInterestsForUser:goalsArray interestsList:interestsArray callback:^(BOOL success) {
//        if (success) {
//            debug NSLog(@"saved everything");
//            callback(success);
//        } else {
//            debug NSLog(@"could not save");
//            callback(NO);
//        }
//    }];
//}
//- (void)saveGoalsAndInterestsForGuest:(NSArray*)goalsList interestsList:(NSArray*)interestsList callback:(void (^)(BOOL success, NSDictionary *posts))callback {
//    NSArray *goalsArray = [[NSMutableArray alloc]init];
//    goalsArray = [self createArray:goalsList];
//
//    NSArray *interestsArray = [[NSMutableArray alloc] init];
//    interestsArray = [self createArray:interestsList];
//
//    debug NSLog(@"num goals sent to server=%lu, num interests sent to server = %lu", (unsigned long)goalsArray.count, (unsigned long)interestsArray.count);
//    [[TDAPIClient sharedInstance] saveGoalsAndInterestsForGuest:goalsArray interestsList:interestsArray callback:^(BOOL success, NSDictionary *posts) {
//        if (success) {
//            debug NSLog(@"saved everything");
//            callback(success, posts);
//        } else {
//            debug NSLog(@"could not save");
//            callback(NO, nil);
//        }
//    }];
//}
//
//- (NSArray*)createArray:(NSArray*)list {
//    NSMutableArray *array = [[NSMutableArray alloc]init];
//    for (NSDictionary *data in list) {
//        if([[data objectForKey:@"selected"] boolValue] == YES) {
//            [array addObject:[data objectForKey:@"name"]];
//        }
//    }
//    return array;
//}
@end
