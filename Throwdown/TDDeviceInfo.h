//
//  TDDeviceInfo.h
//  Throwdown
//
//  Created by Andrew C on 4/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDDeviceInfo : NSObject

+ (NSString *)uuid;
+ (NSString *)device;
+ (NSString *)osName;
+ (NSString *)osVersion;
+ (NSString *)carrier;
+ (NSString *)resolution;
+ (NSString *)locale;
+ (NSString *)appVersion;
+ (NSString *)bundleVersion;

+ (NSDictionary *)metrics;

@end
