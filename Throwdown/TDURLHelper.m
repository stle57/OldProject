//
//  TDURLHelper.m
//  Throwdown
//  Most of these functions borrowed/modifed from https://github.com/BoltsFramework/Bolts-iOS/blob/master/Bolts/iOS/BFURL.m (BSD license)
//
//  Created by Andrew C on 8/28/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDURLHelper.h"
#import "TDConstants.h"

@implementation TDURLHelper

+ (NSString *)decodeURLString:(NSString *)string {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL,
                                                                                    (CFStringRef)string,
                                                                                    CFSTR("")));
}

+ (NSDictionary *)queryParametersForURL:(NSURL *)url {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSString *query = url.query;
    if ([query isEqualToString:@""]) {
        return @{};
    }
    NSArray *queryComponents = [query componentsSeparatedByString:@"&"];
    for (NSString *component in queryComponents) {
        NSRange equalsLocation = [component rangeOfString:@"="];
        if (equalsLocation.location == NSNotFound) {
            // There's no equals, so associate the key with NSNull
            parameters[[self decodeURLString:component]] = [NSNull null];
        } else {
            NSString *key = [self decodeURLString:[component substringToIndex:equalsLocation.location]];
            NSString *value = [self decodeURLString:[component substringFromIndex:equalsLocation.location + 1]];
            parameters[key] = value;
        }
    }
    return [NSDictionary dictionaryWithDictionary:parameters];
}

+ (NSDictionary *)decodeAppLinksURL:(NSURL *)url {
    // Parse the query string parameters for the base URL
    NSDictionary *baseQuery = [self queryParametersForURL:url];

    // Check for applink_data
    NSString *appLinkDataString = baseQuery[AppLinkDataParameterName];
    if (appLinkDataString) {
        // Try to parse the JSON
        NSError *error = nil;
        NSDictionary *applinkData = [NSJSONSerialization JSONObjectWithData:[appLinkDataString dataUsingEncoding:NSUTF8StringEncoding]
                                                                    options:0
                                                                      error:&error];
        if (!error && [applinkData isKindOfClass:[NSDictionary class]]) {
            // If the version is not specified, assume it is 1.
            NSString *version = applinkData[AppLinkVersionKeyName] ?: @"1.0";
            NSString *target = applinkData[AppLinkTargetKeyName];
            if ([version isKindOfClass:[NSString class]] && [version isEqual:AppLinkVersion]) {
                // There's applink data!  The target should actually be the applink target.
                NSURL *targetURL = target ? [NSURL URLWithString:target] : url;
                NSMutableDictionary  *data = [applinkData mutableCopy];
                [data setObject:targetURL forKey:AppLinkTargetKeyName];
                return data;
            }
        }
    }
    return nil;
}

+ (NSArray *)parseThrowdownURL:(NSURL *)url {
    NSString *model;
    NSString *modelId;

    NSURL *baseURL = [NSURL URLWithString:[TDConstants getBaseURL]];
    if ([[baseURL scheme] isEqualToString:[url scheme]] && [[baseURL host] isEqualToString:[url host]]) {
        // regular URL, eg: http://throwdown.us/p/00srEnUbTA9wuw
        model   = [[url pathComponents] objectAtIndex:1]; // 0 is the first slash
        modelId = [[url pathComponents] objectAtIndex:3]; // 0 is the first slash
    }

    if ([[TDConstants appScheme] isEqualToString:[url scheme]]) {
        // direct URL, eg: throwdown://post/00srEnUbTA9wuw or throwdown://user/acr
        model = [url host];
        modelId = [[url pathComponents] objectAtIndex:1]; // 0 is the first slash
    }

    if (model && [model isEqualToString:@"p"]) {
        model = @"post";
    } else if (model && [model isEqualToString:@"u"]) {
        model = @"user";
    }

    if (model && modelId) {
        return @[model, modelId];
    } else {
        return nil;
    }
}

@end
