//
//  TDURLHelper.h
//  Throwdown
//
//  Created by Andrew C on 8/28/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const AppLinkDataParameterName = @"al_applink_data";
static NSString *const AppLinkTargetKeyName = @"target_url";
static NSString *const AppLinkUserAgentKeyName = @"user_agent";
static NSString *const AppLinkExtrasKeyName = @"extras";
static NSString *const AppLinkRefererAppLink = @"referer_app_link";
static NSString *const AppLinkRefererAppName = @"app_name";
static NSString *const AppLinkRefererUrl = @"url";
static NSString *const AppLinkRefererTargetUrl = @"target_url";
static NSString *const AppLinkVersionKeyName = @"version";
static NSString *const AppLinkVersion = @"1.0";

@interface TDURLHelper : NSObject

+ (NSDictionary *)queryParametersForURL:(NSURL *)url;
+ (NSString *)decodeURLString:(NSString *)string;
+ (NSDictionary *)decodeAppLinksURL:(NSURL *)url;
+ (NSArray *)parseThrowdownURL:(NSURL *)url;

@end
