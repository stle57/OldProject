//
//  UserAPI.h
//  Throwdown
//
//  Created by Andrew C on 1/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDCurrentUser.h"

@interface TDUserAPI : NSObject

@property (strong, nonatomic, readonly) TDCurrentUser *currentUser;

+ (TDUserAPI *)sharedInstance;

- (void)signupUser:(NSDictionary *)userAttributes callback:(void (^)(BOOL success))callback;
- (void)loginUser:(NSString *)email withPassword:(NSString *)password callback:(void (^)(BOOL success))callback;
- (void)editUserWithName:(NSString *)name email:(NSString *)email username:(NSString *)username phone:(NSString *)phone callback:(void (^)(BOOL))callback;
- (BOOL)isLoggedIn;
- (void)logout;

@end
