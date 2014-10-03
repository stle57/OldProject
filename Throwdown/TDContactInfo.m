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
        _id        = [[NSNumber alloc] init];
        _firstName = [[NSString alloc] init];
        _lastName = [[NSString alloc] init];
        _emailList = [[NSMutableArray alloc] init];
        _phoneList = [[NSMutableArray alloc] init];
        _fullName = [[NSString alloc] init];
        _username = [[NSString alloc] init];
        _selectedData = [[NSString alloc] init];
        _inviteType = kInviteType_None;
        _following = NO;
    }
    return self;
}


-(id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self)
    {
        _id              = [NSNumber numberWithInteger:(long)[dict objectForKey:@"id"]];
        _firstName       = [dict objectForKey:@"firstName"];
        _lastName        = [dict objectForKey:@"lastName"];
        _emailList       = [dict objectForKey:@"emailList"];
        _phoneList       = [dict objectForKey:@"phoneList"];
        _fullName        = [dict objectForKey:@"fullName"];
        _username        = [dict objectForKey:@"username"];
        _selectedData    = [dict objectForKey:@"selectedData"];
        _contactPicture  = [dict objectForKey:@"contactPicture"];

    }
    return self;
}

@end
