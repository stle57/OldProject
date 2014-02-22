//
//  UserAPI.m
//  Throwdown
//
//  Created by Andrew C on 1/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserAPI.h"
#import "TDAPIClient.h"

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
        }
        callback(success);
    }];
}

- (void)loginUser:(NSString *)email withPassword:(NSString *)password callback:(void (^)(BOOL))callback
{
    [[TDAPIClient sharedInstance] loginUser:email withPassword:password callback:^(BOOL success, NSDictionary *user) {
        if (success) {
            [self.currentUser updateFromDictionary:user];
        }
        callback(success);
    }];
}

- (BOOL)isLoggedIn {
    return [self.currentUser isLoggedIn];
}

- (void)logout {
    [self.currentUser logout];
}

@end