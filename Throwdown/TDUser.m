//
//  TDUser.m
//  Throwdown
//
//  Created by Andrew C on 2/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUser.h"

@implementation TDUser

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self)
    {
        _userId   = [dict objectForKey:@"id"];
        _username = [dict objectForKey:@"username"];
        _name     = [dict objectForKey:@"name"];
    }
    return self;
}

@end
