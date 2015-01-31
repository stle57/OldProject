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
            _sharedInstance.goalsList = [NSMutableArray arrayWithObjects:@{@"name":@"Lose weight",@"selected":@0, @"id":@0},
                                         @{@"name":@"Get back into shape", @"selected":@0, @"id":@0},
                                         @{@"name":@"Tone up", @"selected":@0, @"id":@0},
                                         @{@"name":@"Get stronger", @"selected":@0, @"id":@0},
                                         @{@"name":@"Gain more muscle", @"selected":@0, @"id":@0},
                                         @{@"name":@"Increase endurance", @"selected":@0, @"id":@0},
                                         @{@"name":@"Improve mobility", @"selected":@0, @"id":@0},
                                         @{@"name":@"Become more functionally fit", @"selected":@0, @"id":@0},
                                         @{@"name":@"Develop more self confidence", @"selected":@0, @"id":@0}, nil];

            _sharedInstance.interestsList =             [NSMutableArray arrayWithObjects:
                                                         @{@"name":@"Barre", @"selected":@0, @"id":@0},
                                                         @{@"name":@"Baseball", @"selected":@0, @"id":@0},
                                                         @{@"name":@"Basketball", @"selected":@0, @"id":@0},
                                                         @{@"name":@"Bodybuilding", @"selected":@0, @"id":@0},
                                                         @{@"name":@"Bootcamp",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Boxing",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Cricket",@"selected":@0, @"id":@0},
                                                         @{@"name":@"CrossFit",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Cycling",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Dancing",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Eating Healthy",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Fitness Motivation",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Football (American)",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Golf",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Gymnastics",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Hiking",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Hockey",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Insanity",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Lacrosse",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Martial Arts",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Obstacle Course",@"selected":@0, @"id":@0},
                                                         @{@"name":@"P90X",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Pilates",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Powerlifting",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Rowing",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Rugby",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Running",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Skating",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Skiing",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Snowboarding",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Soccer",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Softball",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Strongman",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Swimming",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Tennis",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Track and Field",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Volleyball",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Weightlifting (Olympic)",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Yoga",@"selected":@0, @"id":@0},
                                                         @{@"name":@"Zumba",@"selected":@0, @"id":@0}, nil];

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
    if (goalsList != nil) {
        _goalsList      =  [goalsList mutableCopy];
    }
    if (interestsList != nil) {
        _interestsList    = [interestsList mutableCopy];
    }
}
@end
