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
@end
