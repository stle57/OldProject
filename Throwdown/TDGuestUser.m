//
//  TDGuestUser.m
//  Throwdown
//
//  Created by Stephanie Le on 1/22/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDGuestUser.h"

static NSString *const DATA_LOCATION = @"/Documents/guest_user.bin";

@implementation TDGuestUser
+ (TDGuestUser *)sharedInstance
{
    static TDGuestUser *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        NSData *data = [NSData dataWithContentsOfFile:[NSHomeDirectory() stringByAppendingString:DATA_LOCATION]];
        _sharedInstance = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (_sharedInstance == nil) {
            _sharedInstance = [[TDGuestUser alloc] init];
        }
    });
    return _sharedInstance;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.goalsList forKey:@"goalsList"];
    [aCoder encodeObject:self.interestsList forKey:@"interestsList"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _goalsList      = [aDecoder decodeObjectForKey:@"goalsList"];
        _interestsList    = [aDecoder decodeObjectForKey:@"interestsList"];
    }
    return self;
}

- (void)updateGuestInfo:goalsList interestsList:(NSArray*)interestsList {
    _goalsList      =  goalsList;
    _interestsList    = interestsList;
}
@end
