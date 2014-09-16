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
        _userId         = [dict objectForKey:@"id"];
        _username       = [dict objectForKey:@"username"];
        _name           = [dict objectForKey:@"name"];
        _picture        = [dict objectForKey:@"picture"];
        _bio            = [dict objectForKey:@"bio"];
        _postCount      = [dict objectForKey:@"post_count"];
        _prCount        = [dict objectForKey:@"pr_count"];
        _followerCount  = [dict objectForKey:@"follower_count"];
        _followingCount = [dict objectForKey:@"following_count"];
        _following      = [dict objectForKey:@"following"];
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
    return [NSString stringWithFormat:@"TDUser-user:%@ %@ %@ %@ %@ %@ %@ %@ %@ %d", _userId, _name, _username, _picture, _bio, _postCount, _prCount, _followerCount, _followingCount, _following];
}

- (void)figureOutBioLabelHeightForThisMessage:(NSString *)text {
    _bioHeight = 0.0;
    if (text && ![text isKindOfClass:[NSNull class]] && [text length] > 0) {
        _bioHeight = [TDAppDelegate heightOfTextForString:text
                                                  andFont:BIO_FONT
                                                  maxSize:CGSizeMake(COMMENT_MESSAGE_WIDTH, MAXFLOAT)];
    }
}

- (BOOL)hasDefaultPicture {
    return !!(!self.picture || [self.picture isKindOfClass:[NSNull class]] || [self.picture length] == 0 || [self.picture isEqualToString:@"default"]);
}

@end
