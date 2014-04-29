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
- (void)resetPassword:(NSString *)requestString callback:(void (^)(BOOL success, NSDictionary *dict))callback;
- (void)editUserWithName:(NSString *)name email:(NSString *)email username:(NSString *)username phone:(NSString *)phone bio:(NSString *)bio picture:(NSString *)pictureFileName callback:(void (^)(BOOL success, NSDictionary *dict))callback;
-(void)changePasswordFrom:(NSString *)oldPassword newPassword:(NSString *)newPassword confirmPassword:(NSString *)confirmPassword callback:(void (^)(BOOL success, NSDictionary *dict))callback;
- (BOOL)isLoggedIn;
- (void)logout;
- (void)uploadAvatarImage:(NSString *)localImagePath withName:(NSString *)newName;

@end
