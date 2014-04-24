//
//  TDCurrentUser.m
//  Throwdown
//
//  Created by Andrew C on 2/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDCurrentUser.h"
#import "TDFileSystemHelper.h"
#import "TDAPIClient.h"
#import "UIAlertView+TDBlockAlert.h"

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
    [aCoder encodeObject:self.deviceToken forKey:@"device_token"];
    [aCoder encodeObject:self.phoneNumber forKey:@"phone_number"];
    [aCoder encodeObject:self.bio forKey:@"bio"];
    [aCoder encodeObject:self.picture forKey:@"picture"];
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
        _deviceToken = [aDecoder decodeObjectForKey:@"device_token"];
        _phoneNumber = [aDecoder decodeObjectForKey:@"phone_number"];
        if ([self nullcheck:[aDecoder decodeObjectForKey:@"bio"]]) {
            _bio     = [aDecoder decodeObjectForKey:@"bio"];
        }
        if ([self nullcheck:[aDecoder decodeObjectForKey:@"picture"]]) {
            _picture = [aDecoder decodeObjectForKey:@"picture"];
        }
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
    if ([self nullcheck:[dictionary objectForKey:@"bio"]]) {
        _bio     = [dictionary objectForKey:@"bio"];
    }
    if ([self nullcheck:[dictionary objectForKey:@"picture"]]) {
        _picture     = [dictionary objectForKey:@"picture"];
    }
    // _deviceToken not part of dictionary

    [self save];

    if ([self isLoggedIn] && [self didAskForPush]) {
        [self registerForRemoteNotificationTypes];
    }
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
    _deviceToken = nil;
    _picture = nil;
    _bio = nil;
    [TDFileSystemHelper removeFileAt:[NSHomeDirectory() stringByAppendingString:DATA_LOCATION]];
}

- (void)save {
    NSString *filename = [NSHomeDirectory() stringByAppendingString:DATA_LOCATION];
    [TDFileSystemHelper removeFileAt:filename];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [data writeToFile:filename atomically:YES];
}

- (TDUser *)currentUserObject {
    if (!self.picture) {
        _picture = @"default";
    }

    TDUser *user = [[TDUser alloc] init];
    [user userId:self.userId
        userName:self.username
            name:self.name
         picture:self.picture
             bio:self.bio];
    return user;
}

#pragma mark - push notification device token

- (BOOL)isRegisteredForPush {
    return self.deviceToken != nil;
}

- (BOOL)didAskForPush {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"hasAskedPushNotification"];
}

- (void)didAskForPush:(BOOL)yes {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:yes forKey:@"hasAskedPushNotification"];
    [defaults synchronize];
}

- (void)registerForPushNotifications:(NSString *)message {
    if ([[TDCurrentUser sharedInstance] isLoggedIn] && ![self isRegisteredForPush]) {
        // for some reason we don't have the device token stored, so we'll either ask for it if never asked before or register it
        if ([self didAskForPush]) {
            [self registerForRemoteNotificationTypes];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Turn on Notifications?" message:message delegate:nil cancelButtonTitle:@"Not now" otherButtonTitles:@"YES", nil];
            [alert showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (buttonIndex != alertView.cancelButtonIndex) {
                    [self registerForRemoteNotificationTypes];
                }
            }];
        }
    }
}

- (void)registerDeviceToken:(NSString *)token {
	token = [token stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (![token isEqualToString:self.deviceToken]) {
        _deviceToken = token;
        [self save];
        [[TDAPIClient sharedInstance] registerDeviceToken:token forUserToken:self.authToken];

        // store this for future knowledge
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"approvedPushNotification"];
        [defaults synchronize];
    }
}

- (void)registerForRemoteNotificationTypes {
    [self didAskForPush:YES];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
}

- (BOOL)nullcheck:(id)object {
    return (object && ![object isKindOfClass:[NSNull class]]);
}

@end
