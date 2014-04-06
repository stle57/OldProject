//
//  TDConstants.m
//  Throwdown
//
//  Created by Andrew C on 2/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDConstants.h"

//#define CDN_BASE_URL @"http://tdstore2.throwdown.us"

#define CDN_BASE_URL @"http://139bc8fb83b0918931ad-a6f5654f38394ba560d9625746ae5e96.iosr.cf5.rackcdn.com"

#define DEV_SERVER @"http://amber.local:3000"
#define STAGING_SERVER @"http://staging.throwdown.us"
#define PRODUCTION_SERVER @"http://throwdown.us"

@implementation TDConstants

+ (TDEnvironment)environment {
    NSArray *parts = [[[NSBundle mainBundle] bundleIdentifier] componentsSeparatedByString:@"."];
    NSString *lastPart = [parts objectAtIndex:[parts count] - 1];
    if ([@"dev" isEqualToString:lastPart]) {
        return TDEnvDevelopment;
    } else if ([@"staging" isEqualToString:lastPart]) {
        return TDEnvStaging;
    } else {
        return TDEnvProduction;
    }
}

+ (NSString*)getBaseURL {
   // Andrew B return STAGING_SERVER;

    switch ([self environment]) {
        case TDEnvDevelopment:
            return DEV_SERVER;
            break;
        case TDEnvStaging:
            return STAGING_SERVER;
            break;
        case TDEnvProduction:
            return PRODUCTION_SERVER;
            break;
    }
}

+ (NSString *)flurryKey {
    switch ([self environment]) {
        case TDEnvDevelopment:
        case TDEnvStaging:
            return nil;
            break;

        case TDEnvProduction:
            return @"3JFF5PK4XDMTVPQQNZKN";
            break;
    }
}

+ (NSURL *)getStreamingUrlFor:(NSString *)filename {
    NSString *location = [NSString stringWithFormat:@"%@/%@.mp4", CDN_BASE_URL, filename];
    return [NSURL URLWithString:location];
}

+ (UIColor *)brandingRedColor {
    return [UIColor colorWithRed:.929411765 green:.294117647 blue:.243137255 alpha:1.0];
}

+ (UIColor *)backgroundColor {
    return [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];  // ededed
}

+ (UIColor *)borderColor {
    return [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0]; // c8c8c8
}

+ (UIColor *)headerTextColor {
    return [UIColor colorWithRed:(76.0/255.0) green:(76.0/255.0) blue:(76.0/255.0) alpha:1.0];  // 4c4c4c
}

+ (UIColor *)commentTextColor {
    return [UIColor colorWithRed:(76.0/255.0) green:(76.0/255.0) blue:(76.0/255.0) alpha:1.0];  // 4c4c4c
}

+ (UIColor *)commentTimeTextColor {
    return [UIColor colorWithRed:(162.0/255.0) green:(162.0/255.0) blue:(162.0/255.0) alpha:1.0];  // a2a2a2
}


@end
