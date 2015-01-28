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
@property (nonatomic) BOOL isWaitingForCallback;


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
        }
    });

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
        self.isWaitingForCallback = NO;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.userList = [dict objectForKey:@"userList"];
        if (!self.userList || [self.userList count] == 0) {
            self.isWaitingForCallback = NO;
        }
    }
    return self;
}

- (void)getListWithCallback:(void (^)(NSArray *list))callback {
    if (self.userList) {
        callback(self.userList);
    } else {
        callback(@[]);
    }

    if (!self.lastFetched || fabs([self.lastFetched timeIntervalSinceNow]) > kReloadUserListTime) {
        [self getCommunityUserListWithCallback:callback];
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

- (void)getCommunityUserListWithCallback:(void (^)(NSArray *list))callback {
    if (!self.isWaitingForCallback) {
        self.isWaitingForCallback = YES;
        debug NSLog(@"Fetching user list for mentions");
        [[TDUserAPI sharedInstance] getCommunityUserList:^(BOOL success, NSArray *returnList) {
            self.isWaitingForCallback = NO;
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
}

@end
