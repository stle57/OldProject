//
//  TDUser.h
//  Throwdown
//
//  Created by Andrew C on 2/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDUser : NSObject

@property (strong, nonatomic, readonly) NSNumber *userId;
@property (strong, nonatomic, readonly) NSString *username;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *picture;
@property (strong, nonatomic, readonly) NSString *bio;

- (id)initWithDictionary:(NSDictionary *)dict;
-(void)userId:(NSNumber *)userId userName:(NSString *)userName name:(NSString *)name picture:(NSString *)picture;

@end
