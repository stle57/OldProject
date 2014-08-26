//
//  TDComunnity.h
//  Throwdown
//
//  Created by Stephanie Le on 7/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDUserList : NSObject <NSCoding>

+ (TDUserList *)sharedInstance;
- (void)clearList;
- (id)initWithDictionary:(NSDictionary *)dict;
- (void)getListWithCallback:(void (^)(NSArray *list))callback;

@end
