//
//  TDComunnity.h
//  Throwdown
//
//  Created by Stephanie Le on 7/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDUserList : NSObject <NSCoding>
@property (strong, nonatomic, readonly) NSArray *userList;
//@property (strong, nonatomic) NSTimer *timer;

+ (TDUserList*) sharedInstance;
- (void) getCommunityUserList;
- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithUser:(NSNumber*)communityId userList:(NSDictionary *)userList;
@end
