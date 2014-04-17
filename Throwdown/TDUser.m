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
        _picture  = [dict objectForKey:@"picture"];
        _bio  = [dict objectForKey:@"bio"];
    }
    return self;
}

-(void)userId:(NSNumber *)userId userName:(NSString *)userName name:(NSString *)name picture:(NSString *)picture
{
    _userId = userId;
    _username = userName;
    _name = name;
    if (picture) {
        _picture = picture;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"TDUser-user:%@ %@ %@ %@ %@", _userId, _name, _username, _picture, _bio];
}

@end
