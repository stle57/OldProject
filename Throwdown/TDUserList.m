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

@implementation TDUserList

+ (TDUserList*) sharedInstance
{
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
    return _sharedInstance;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.userList forKey:@"users"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
       _userList   = [aDecoder decodeObjectForKey:@"users"];
    }
    return self;
}

-(id)init {
    self = [super init];

    if (self) {
        [self getCommunityUserList];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        [self loadFromDict:dict];
    }
    return self;
}

- (id)initWithUser:(NSNumber*)communityId userList:(NSDictionary *)userList {
    self = [super init];
    if (self) {
        _userList = [userList copy];
    }
    return self;
}

- (void)loadFromDict:(NSDictionary *)dict {
    _userList = [dict objectForKey:@"userList"];
}

- (void)save {
    NSString *filename = [NSHomeDirectory() stringByAppendingString:DATA_LOCATION];
    [TDFileSystemHelper removeFileAt:filename];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [data writeToFile:filename atomically:YES];
}

#pragma Requests to servers

- (void) getCommunityUserList {
    [[TDUserAPI sharedInstance] getCommunityUserList:^(BOOL success, NSDictionary *returnList) {
        if (success && returnList && returnList.count > 0) {
            _userList = [returnList copy];
            [self save];
        } else {
            debug NSLog(@"no list");
        }
        // Fire off timer to retrieve data again
//        _timer = [NSTimer scheduledTimerWithTimeInterval:kReloadUserListTime target:self selector:@selector(getCommunityUserList) userInfo:nil repeats:NO];

    }];
}

@end
