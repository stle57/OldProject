//
//  TDCurrentUser.m
//  Throwdown
//
//  Created by Andrew C on 2/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDCurrentUser.h"

static NSString *const DATA_LOCATION = @"/Documents/current_user.bin";

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
    [aCoder encodeObject:self.phoneNumber forKey:@"phone_number"];
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
        _phoneNumber = [aDecoder decodeObjectForKey:@"phone_number"];
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

    [self save];
}

- (BOOL)isLoggedIn {
    return self.authToken != nil;
}

- (void)logout {
    _userId = nil;
    _username = nil;
    _name = nil;
    _email = nil;
    _phoneNumber = nil;
    _authToken = nil;
    [self save];
}

- (void)save {
    NSString *filename = [NSHomeDirectory() stringByAppendingString:DATA_LOCATION];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [data writeToFile:filename atomically:YES];
}

@end
