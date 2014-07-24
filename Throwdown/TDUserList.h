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

+ (TDUserList *)sharedInstance;
- (void)getCommunityUserList;
- (void)clearList;
- (id)initWithDictionary:(NSDictionary *)dict;

@end
