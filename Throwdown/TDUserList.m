//
//  TDComunnity.m
//  Throwdown
//
//  Created by Stephanie Le on 7/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserList.h"
#import "TDUserAPI.h"
#import "TDFileSystemHelper.h"
#import "TDConstants.h"

static NSString *const DATA_LOCATION = @"/Documents/user_list.bin";

@interface TDUserList ()

@property (nonatomic) NSArray *userList;
@property (nonatomic) NSDate *lastFetched;

@end

@implementation TDUserList

+ (TDUserList *)sharedInstance {
    static TDUserList *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        NSData *data = [NSData dataWithContentsOfFile:[NSHomeDirectory() stringByAppendingString:DATA_LOCATION]];
        _sharedInstance = [NSKeyedUnarchiver unarchiveObjectWithData:data];

        if (_sharedInstance == nil) {
            _sharedInstance = [[TDUserList alloc] init];
        } else {
            // The object already instantiated, retrieve the list
            [_sharedInstance getCommunityUserList];
        }
    });

    if (!_sharedInstance.userList || [_sharedInstance.userList count] == 0) {
        [_sharedInstance getCommunityUserList];
    }

    return _sharedInstance;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.userList forKey:@"users"];
    [aCoder encodeObject:self.lastFetched forKey:@"last_fetched"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.userList = [aDecoder decodeObjectForKey:@"users"];
        self.lastFetched = [aDecoder decodeObjectForKey:@"last_fetched"];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self getCommunityUserList];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.userList = [dict objectForKey:@"userList"];
        if (!self.userList || [self.userList count] == 0) {
            [self getCommunityUserList];
        }
    }
    return self;
}

- (void)getListWithCallback:(void (^)(NSArray *list))callback {
    if (!self.lastFetched || fabs([self.lastFetched timeIntervalSinceNow]) > kReloadUserListTime) {
        [self getCommunityUserListWithCallback:callback];
    } else {
        callback(self.userList);
    }
}

- (void)save {
    NSString *filename = [NSHomeDirectory() stringByAppendingString:DATA_LOCATION];
    [TDFileSystemHelper removeFileAt:filename];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [data writeToFile:filename atomically:YES];
}

- (void)clearList {
    _userList = nil;
    [self save];
}

#pragma Requests to servers

- (void)getCommunityUserList {
    [self getCommunityUserListWithCallback:nil];
}

- (void)getCommunityUserListWithCallback:(void (^)(NSArray *list))callback {
    debug NSLog(@"Fetching user list for mentions");
    [[TDUserAPI sharedInstance] getCommunityUserList:^(BOOL success, NSArray *returnList) {
        if (success && returnList && returnList.count > 0) {
            self.userList = [returnList copy];
            self.lastFetched = [NSDate date];
            [self save];
            if (callback) {
                callback(self.userList);
            }
        } else {
            debug NSLog(@"no list");
            if (callback) {
                callback(@[]);
            }
        }
    }];
}

@end
