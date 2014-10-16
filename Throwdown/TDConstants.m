//
//  TDConstants.m
//  Throwdown
//
//  Created by Andrew C on 2/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDConstants.h"
#import "AVFoundation/AVFoundation.h"

static NSString *const kDevHost = @"http://amber.local:3000";
static NSString *const kStagingHost = @"http://staging.throwdown.us";
static NSString *const kProductionHost = @"https://throwdown.us";
static NSString *const kProductionSharingHost = @"http://tdwn.us";
static NSString *const kCDNStreamingServer = @"http://139bc8fb83b0918931ad-a6f5654f38394ba560d9625746ae5e96.iosr.cf5.rackcdn.com";

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

+ (NSString *)appScheme {
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    return [bundleInfo objectForKey:@"ThrowdownURL"];
}

+ (NSString *)getBaseURL {
    switch ([self environment]) {
        case TDEnvDevelopment:
            return kDevHost;
            break;
        case TDEnvStaging:
            return kStagingHost;
            break;
        case TDEnvProduction:
            return kProductionHost;
            break;
    }
}

+ (NSString *)getShareURL:(NSString *)slug {
    NSString *server;
    switch ([self environment]) {
        case TDEnvDevelopment:
            server = kDevHost;
            break;
        case TDEnvStaging:
            server = kStagingHost;
            break;
        case TDEnvProduction:
            server = kProductionSharingHost;
            break;
    }
    return [NSString stringWithFormat:@"%@/p/%@", server, slug];
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
    NSString *location = [NSString stringWithFormat:@"%@/%@.mp4", kCDNStreamingServer, filename];
    return [NSURL URLWithString:location];
}


#pragma mark - Colors

+ (UIColor *)brandingRedColor {
    return [UIColor colorWithRed:(237./255.) green:(75./255.) blue:(62./255.) alpha:1.0]; // ED4B3E
}

+ (UIColor *)darkBackgroundColor {
    return [UIColor colorWithRed:(230./255.) green:(230./255.) blue:(230./255.) alpha:1.0]; // #e6e6e6, this method previously return d3d3d3 (211/211/211)
}

+ (UIColor *)lightBackgroundColor {
    return [UIColor colorWithRed:(245./255.) green:(245./255.) blue:(245./255.) alpha:1.0]; // #f5f5f5
}

+ (UIColor *)darkTextColor {
    return [UIColor colorWithRed:(27.0/255.0) green:(27.0/255.0) blue:(27.0/255.0) alpha:1.0]; // 1b1b1b
}

+ (UIColor *)disabledTextColor {
    return [UIColor colorWithRed:(189.0/255.0) green:(189.0/255.0) blue:(189.0/255.0) alpha:1.0]; // bdbdbd
}

+ (UIColor *)headerTextColor {
    return [UIColor colorWithRed:(76.0/255.0) green:(76.0/255.0) blue:(76.0/255.0) alpha:1.0]; // 4c4c4c
}

+ (UIColor *)commentTextColor {
    return [self headerTextColor];
}

+ (UIColor *)darkBorderColor {
    return [self commentTimeTextColor];
}

+ (UIColor *)lightBorderColor {
    return [UIColor colorWithRed:(204.0/255.0) green:(204.0/255.0) blue:(204.0/255.0) alpha:1.0]; // cccccc
}

+ (UIColor *)commentTimeTextColor {
    return [UIColor colorWithRed:(162.0/255.0) green:(162.0/255.0) blue:(162.0/255.0) alpha:1.0]; // a2a2a2
}

+ (UIColor *)activityUnseenColor {
    return [UIColor colorWithRed:(255.0/255.0) green:(238.0/255.0) blue:(224.0/255.0) alpha:1.0]; // #fff5ed
}

+ (UIColor *)helpTextColor {
    return [UIColor colorWithRed:(147./255.) green:(147./255.) blue:(147./255.) alpha:1.0]; //#939393
}
// Deprecated: Use light or dark background color
+ (UIColor *)backgroundColor {
    return [UIColor colorWithRed:237./255. green:237./255. blue:237./255. alpha:1.0];  // ededed
}

// Deprecated: Use light or dark border color below.
+ (UIColor *)borderColor {
    return [UIColor colorWithRed:200./255. green:200./255. blue:200./255. alpha:1.0]; // c8c8c8
}

// Deprecated: Use light or dark border color
+ (UIColor *)cellBorderColor {
    return [self lightBorderColor];
}

#pragma mark - Fonts

+ (UIFont *)fontLightSized:(NSUInteger)size {
    return [UIFont fontWithName:@"ProximaNova-Light" size:size];
}

+ (UIFont *)fontRegularSized:(NSUInteger)size {
    return [UIFont fontWithName:@"ProximaNova-Regular" size:size];
}

+ (UIFont *)fontSemiBoldSized:(NSUInteger)size {
    return [UIFont fontWithName:@"ProximaNova-SemiBold" size:size];
}

+ (UIFont *)fontBoldSized:(NSUInteger)size {
    return [UIFont fontWithName:@"ProximaNova-Bold" size:size];
}

#pragma mark - Video Settings

+ (NSDictionary *)defaultVideoCompressionSettings {
    int videoSize = 640;
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    [settings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [settings setObject:[NSNumber numberWithInt:videoSize] forKey:AVVideoWidthKey];
    [settings setObject:[NSNumber numberWithInt:videoSize] forKey:AVVideoHeightKey];

    NSDictionary *videoCleanApertureSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInt:videoSize], AVVideoCleanApertureWidthKey,
                                                [NSNumber numberWithInt:videoSize], AVVideoCleanApertureHeightKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureHorizontalOffsetKey,
                                                [NSNumber numberWithInt:0], AVVideoCleanApertureVerticalOffsetKey,
                                                nil];

    NSDictionary *videoAspectRatioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioHorizontalSpacingKey,
                                              [NSNumber numberWithInt:3], AVVideoPixelAspectRatioVerticalSpacingKey,
                                              nil];

    NSMutableDictionary * compressionProperties = [[NSMutableDictionary alloc] init];
    [compressionProperties setObject:videoCleanApertureSettings forKey:AVVideoCleanApertureKey];
    [compressionProperties setObject:videoAspectRatioSettings forKey:AVVideoPixelAspectRatioKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 1200000] forKey:AVVideoAverageBitRateKey];
    [compressionProperties setObject:[NSNumber numberWithInt: 90] forKey:AVVideoMaxKeyFrameIntervalKey];
    [compressionProperties setObject:AVVideoProfileLevelH264Main31 forKey:AVVideoProfileLevelKey];
    [settings setObject:compressionProperties forKey:AVVideoCompressionPropertiesKey];
    return settings;
}

@end
