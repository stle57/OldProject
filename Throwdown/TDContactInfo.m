//
//  TDContactInfo.m
//  Throwdown
//
//  Created by Stephanie Le on 9/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDContactInfo.h"

@implementation TDContactInfo

- (id)init
{
    self = [super init];
    if (self) {
        _emailList = [[NSMutableArray alloc] init];
        _phoneList = [[NSMutableArray alloc] init];
    }
    return self;
}


-(id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self)
    {
        _firstName       = [dict objectForKey:@"firstName"];
        _lastName        = [dict objectForKey:@"lastName"];
        _contactPicture  = [dict objectForKey:@"contactPicture"];
        _username        = [dict objectForKey:@"username"];
        _emailList       = [dict objectForKey:@"emailList"];
        _phoneList       = [dict objectForKey:@"phoneList"];
    }
    return self;
}

@end
