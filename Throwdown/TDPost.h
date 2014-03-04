//
//  Post.h
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUser.h"

@interface TDPost : NSObject

@property (strong, nonatomic, readonly) NSNumber *postId;
@property (nonatomic, copy, readonly) NSString *filename;
@property (nonatomic, readonly) TDUser *user;
@property (nonatomic, readonly) NSDate *createdAt;
@property (nonatomic, assign) BOOL liked;
@property (strong, nonatomic, readonly) NSArray *likers;
@property (strong, nonatomic, readonly) NSArray *comments;

- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)jsonRepresentation;

@end
