//
//  TDUser.m
//  Throwdown
//
//  Created by Andrew C on 2/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUser.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"

@implementation TDUser

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self)
    {
        _userId   = [dict objectForKey:@"id"];
        _username = [dict objectForKey:@"username"];
        _name     = [dict objectForKey:@"name"];
        _picture  = [dict objectForKey:@"picture"];
        _bio      = [dict objectForKey:@"bio"];
        [self figureOutBioLabelHeightForThisMessage:_bio];
    }
    return self;
}

- (void)userId:(NSNumber *)userId userName:(NSString *)userName name:(NSString *)name picture:(NSString *)picture bio:(NSString *)bio; {
    _userId = userId;
    _username = userName;
    _name = name;
    if (picture) {
        _picture = picture;
    }
    _bio = bio;
    [self figureOutBioLabelHeightForThisMessage:_bio];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"TDUser-user:%@ %@ %@ %@ %@", _userId, _name, _username, _picture, _bio];
}

- (void)figureOutBioLabelHeightForThisMessage:(NSString *)text {
    _bioHeight = 0.0;
    if (text && ![text isKindOfClass:[NSNull class]] && [text length] > 0) {
        _bioHeight = [TDAppDelegate heightOfTextForString:text
                                                  andFont:BIO_FONT
                                                  maxSize:CGSizeMake(COMMENT_MESSAGE_WIDTH, MAXFLOAT)];
    }
}

@end
