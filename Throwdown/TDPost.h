//
//  Post.h
//  Throwdown
//
//  Created by Andrew C on 1/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDPost : NSObject

@property (nonatomic, copy, readonly) NSString *filename, *username;
@property (nonatomic, copy, readonly) NSNumber *userId;

- (id)initWithUsername:(NSString *)username userId:(NSNumber *)userId filename:(NSString *)filename;
- (id)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)jsonRepresentation;
@end
