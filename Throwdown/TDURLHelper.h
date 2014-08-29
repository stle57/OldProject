//
//  TDURLHelper.h
//  Throwdown
//
//  Created by Andrew C on 8/28/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const AppLinkDataParameterName = @"al_applink_data";
NSString *const AppLinkTargetKeyName = @"target_url";
NSString *const AppLinkUserAgentKeyName = @"user_agent";
NSString *const AppLinkExtrasKeyName = @"extras";
NSString *const AppLinkRefererAppLink = @"referer_app_link";
NSString *const AppLinkRefererAppName = @"app_name";
NSString *const AppLinkRefererUrl = @"url";
NSString *const AppLinkRefererTargetUrl = @"target_url";
NSString *const AppLinkVersionKeyName = @"version";
NSString *const AppLinkVersion = @"1.0";

@interface TDURLHelper : NSObject

+ (NSDictionary *)queryParametersForURL:(NSURL *)url;
+ (NSString *)decodeURLString:(NSString *)string;
+ (NSDictionary *)decodeAppLinksURL:(NSURL *)url;
+ (NSArray *)parseThrowdownURL:(NSURL *)url;

@end
