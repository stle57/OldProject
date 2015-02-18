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
@property (nonatomic) NSNumber* lastFetched;
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
    [aCoder encodeObject:self.lastFetched forKey:@"last_fetched_number"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        id existingList = [aDecoder decodeObjectForKey:@"users"];
        if ([existingList isKindOfClass:[NSArray class]]) {
            self.userList = (NSArray *)existingList;
        }
        self.lastFetched = [aDecoder decodeObjectForKey:@"last_fetched_number"];
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
    NSDate *lastFetchedDate = [NSDate dateWithTimeIntervalSince1970:[self.lastFetched doubleValue]];

    if (self.userList != nil && fabs([lastFetchedDate timeIntervalSinceNow]) > kReloadUserListTime) {
        [self getCommunityUserListWithCallback:self.lastFetched callback:callback];
    } else if (self.userList == nil){
        [self getCommunityUserListWithCallback:0 callback:callback];
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

- (void)getCommunityUserListWithCallback:(NSNumber*)lastFetched callback:(void (^)(NSArray *list))callback {
    if (!self.isWaitingForCallback) {
        self.isWaitingForCallback = YES;
        [[TDUserAPI sharedInstance] getCommunityUserList:lastFetched callback:^(BOOL success, NSArray *returnList) {
            self.isWaitingForCallback = NO;
            if (success && returnList) {
                if (lastFetched == 0) {
                    self.userList = [NSArray arrayWithArray:returnList];
                    [[NSNotificationCenter defaultCenter] postNotificationName:TDUserListLoadedFromBackground object:self];
                } else {
                    [self mergeUserList:returnList];
                }
                self.lastFetched =[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
                [self save];
                if (callback) {
                    callback(self.userList);
                }
            } else {
                if (callback) {
                    callback(@[]);
                }
            }
        }];
    }
}

- (void)mergeUserList:(NSArray*)newUserList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.userList) {
            NSMutableArray *newList = [self.userList mutableCopy];
            for (id tempObject in newUserList) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username MATCHES %@", [tempObject valueForKey:@"username"]];
                NSArray *results = [newList filteredArrayUsingPredicate:predicate];
                if (results.count == 1) {
                    NSDictionary *result = results[0];
                    [newList removeObject:result];
                }
            }
            [newList addObjectsFromArray:newUserList];
            self.userList = [NSArray arrayWithArray:newList];
        }
    });

}
@end
