//
//  Post.m
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPost.h"

@implementation TDPost

- (id)initWithUsername:(NSString *)username userId:(NSNumber *)userId filename:(NSString *)filename
{
    self = [super init];
    if (self)
    {
        _userId = userId;
        _username = username;
        _filename = filename;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    return [self initWithUsername:[dict objectForKey:@"username"] userId:[dict objectForKey:@"user_id"] filename:[dict objectForKey:@"filename"]];
}

- (NSDictionary *)jsonRepresentation
{
    return @{@"post": @{@"user_id": _userId, @"filename": _filename}};
}
@end
