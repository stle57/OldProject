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
@property (strong, nonatomic, readonly) NSString *location;
@property (nonatomic, assign) CGFloat bioHeight;
@property (nonatomic, assign) CGFloat locationHeight;
@property (strong, nonatomic, readonly) NSNumber *postCount;
@property (strong, nonatomic, readonly) NSNumber *prCount;
@property (strong, nonatomic) NSNumber *followerCount;
@property (strong, nonatomic) NSNumber *followingCount; 
@property (nonatomic) BOOL following;

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)userId:(NSNumber *)userId userName:(NSString *)userName name:(NSString *)name picture:(NSString *)picture bio:(NSString *)bio location:(NSString *)location;
- (BOOL)hasDefaultPicture;

@end
