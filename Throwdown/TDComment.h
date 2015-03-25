//
//  TDComment.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUser.h"

@interface TDComment : NSObject

@property (strong, nonatomic, readonly) NSNumber *commentId;
@property (strong, nonatomic) NSString *body;
@property (strong, nonatomic, readonly) NSArray *mentions;
@property (nonatomic, readonly) NSDate *createdAt;
@property (strong, nonatomic, readonly) TDUser *user;
@property (nonatomic, assign) CGFloat messageHeight;
@property (nonatomic) BOOL updated;

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithUser:(TDUser *)user body:(NSString *)body createdAt:(NSDate *)date;
- (void)replaceUser:(TDUser *)newUser;
@end
