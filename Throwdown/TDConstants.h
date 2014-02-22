//
//  TDConstants.h
//  Throwdown
//
//  Created by Andrew C on 2/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDConstants : NSObject

+ (NSString *)getBaseURL;
+ (NSURL *)getStreamingUrlFor:(NSString *)filename;
+ (UIColor *)brandingRedColor;

@end
