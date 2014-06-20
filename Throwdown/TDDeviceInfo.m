//
//  TDDeviceInfo.m
//  Throwdown
//
//  Created by Andrew C on 4/27/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDDeviceInfo.h"
#import "TDConstants.h"
#include <sys/types.h>
#include <sys/sysctl.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

@implementation TDDeviceInfo

+ (BOOL)hasUUID {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUUIDKey]) {
        return NO;
    }
    return YES;
}

+ (NSString *)uuid {
    NSString *UUID = [[NSUserDefaults standardUserDefaults] objectForKey:kApplicationUUIDKey];
    if (!UUID) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        UUID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);

        [[NSUserDefaults standardUserDefaults] setObject:UUID forKey:kApplicationUUIDKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return UUID;
}

+ (NSString *)device {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    char *modelKey = "hw.machine";
#else
    char *modelKey = "hw.model";
#endif
    size_t size;
    sysctlbyname(modelKey, NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname(modelKey, model, &size, NULL, 0);
    NSString *modelString = [NSString stringWithUTF8String:model];
    free(model);
    return modelString;
}

+ (NSString *)osName {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	return @"iOS";
#else
	return @"OS X";
#endif
}

+ (NSString *)osVersion {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	return [[UIDevice currentDevice] systemVersion];
#else
    return [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"][@"ProductVersion"];
#endif
}

+ (NSString *)carrier {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	if (NSClassFromString(@"CTTelephonyNetworkInfo"))
	{
		CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
		CTCarrier *carrier = [netinfo subscriberCellularProvider];
		return [carrier carrierName];
	}
#endif
	return nil;
}

+ (NSString *)resolution {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	CGRect bounds = UIScreen.mainScreen.bounds;
	CGFloat scale = [UIScreen.mainScreen respondsToSelector:@selector(scale)] ? [UIScreen.mainScreen scale] : 1.f;
    return [NSString stringWithFormat:@"%gx%g", bounds.size.width * scale, bounds.size.height * scale];
#else
    NSRect screenRect = NSScreen.mainScreen.frame;
    CGFloat scale = [NSScreen.mainScreen backingScaleFactor];
    return [NSString stringWithFormat:@"%gx%g", screenRect.size.width * scale, screenRect.size.height * scale];
#endif
}

+ (NSString *)locale {
	return [[NSLocale currentLocale] localeIdentifier];
}

+ (NSString *)appVersion {
    NSString *result = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if ([result length] == 0) {
        result = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    }

    return result;
}

+ (NSString *)bundleVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

+ (NSDictionary *)metrics {
    NSMutableDictionary* metricsDictionary = [NSMutableDictionary dictionary];
	[metricsDictionary setObject:TDDeviceInfo.device forKey:@"device"];
	[metricsDictionary setObject:TDDeviceInfo.osName forKey:@"os"];
	[metricsDictionary setObject:TDDeviceInfo.osVersion forKey:@"os_version"];

	NSString *carrier = TDDeviceInfo.carrier;
	if (carrier) {
        [metricsDictionary setObject:carrier forKey:@"carrier"];
    }

	[metricsDictionary setObject:TDDeviceInfo.resolution forKey:@"resolution"];
	[metricsDictionary setObject:TDDeviceInfo.locale forKey:@"locale"];
	[metricsDictionary setObject:TDDeviceInfo.appVersion forKey:@"app_version"];
	[metricsDictionary setObject:TDDeviceInfo.bundleVersion forKey:@"bundle_version"];
	[metricsDictionary setObject:TDDeviceInfo.uuid forKey:@"uuid"];

	return [metricsDictionary copy];
}

@end



