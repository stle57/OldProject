//
//  TDAPIClient.h
//  Throwdown
//
//  Created by Andrew C on 2/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDAPIClient : NSObject

+ (TDAPIClient *)sharedInstance;

- (void)validateCredentials:(NSDictionary *)parameters success:(void (^)(NSDictionary *response))success failure:(void (^)())failure;
- (void)signupUser:(NSDictionary *)userAttributes callback:(void (^)(BOOL success, NSDictionary *user))callback;
- (void)loginUser:(NSString *)email withPassword:(NSString *)password callback:(void (^)(BOOL success, NSDictionary *user))callback;
- (void)logoutUser;
- (void)logoutUserWithDeviceToken:(NSString *)token;
- (void)registerDeviceToken:(NSString *)token forUserToken:(NSString *)userToken;
- (void)getActivityForUserToken:(NSString *)userToken success:(void (^)(NSArray *activities))success failure:(void (^)(void))failure;

@end
