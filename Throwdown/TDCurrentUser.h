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
@property (nonatomic, copy, readonly) NSString *authToken;
@property (strong, nonatomic, readonly) NSString *picture;

+ (TDCurrentUser *)sharedInstance;
- (void)updateFromDictionary:(NSDictionary *)dictionary;
- (BOOL)isLoggedIn;
- (void)logout;
-(TDUser *)currentUserObject;

@end
