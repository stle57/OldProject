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
#import "TDViewControllerHelper.h"
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
        _location       = [dict objectForKey:@"location"];
        _postCount      = [dict objectForKey:@"post_count"];
        _prCount        = [dict objectForKey:@"pr_count"];
        _followerCount  = [dict objectForKey:@"follower_count"];
        _followingCount = [dict objectForKey:@"following_count"];
        _following      = [[dict objectForKey:@"following"] boolValue];
        [self figureOutBioLabelHeightForThisMessage:_bio];
        [self figureOutLocationLabelHeightForThisMessage:_location];
    }
    return self;
}

- (void)userId:(NSNumber *)userId userName:(NSString *)userName name:(NSString *)name picture:(NSString *)picture bio:(NSString *)bio location:(NSString*)location followingCount:(NSNumber*)followingCount followerCount:(NSNumber*)followerCount prCount:(NSNumber*)prCount postCount:(NSNumber*)postCount; {
    _userId = userId;
    _username = userName;
    _name = name;
    if (picture) {
        _picture = picture;
    }
    _bio = bio;
    _location = location;
    _followerCount = followerCount;
    _followingCount = followingCount;
    _prCount = prCount;
    _postCount = postCount;
    
    [self figureOutBioLabelHeightForThisMessage:_bio];
    [self figureOutLocationLabelHeightForThisMessage:_location];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"TDUser-user:%@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %d", _userId, _name, _username, _picture, _bio, _location, _postCount, _prCount, _followerCount, _followingCount, _following];
}

- (void)figureOutBioLabelHeightForThisMessage:(NSString *)text {
    _bioHeight = 0.0;
    if (text && ![text isKindOfClass:[NSNull class]] && [text length] > 0) {
        _bioHeight = [TDViewControllerHelper heightForText:text withMentions:@[] withFont:BIO_FONT inWidth:SCREEN_WIDTH-20];
    }
}

- (void)figureOutLocationLabelHeightForThisMessage:(NSString *)text {
    _locationHeight = 0.0;
    if (text && ![text isKindOfClass:[NSNull class]] && [text length] > 0) {
        _locationHeight = [TDViewControllerHelper heightForText:text withMentions:@[] withFont:BIO_FONT inWidth:SCREEN_WIDTH-20];
    }
}

- (BOOL)hasDefaultPicture {
    return !!(!self.picture || [self.picture isKindOfClass:[NSNull class]] || [self.picture length] == 0 || [self.picture isEqualToString:@"default"]);
}

@end
