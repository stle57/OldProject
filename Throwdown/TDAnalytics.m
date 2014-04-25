//
//  TDAnalytics.m
//  Throwdown
//
//  Created by Andrew C on 4/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDAnalytics.h"
#import "TDConstants.h"
#import "TDFileSystemHelper.h"
#import "TDAPIClient.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

#include <sys/types.h>
#include <sys/sysctl.h>



#pragma mark - Helper Functions

NSString *TDJSONFromObject(id object);
NSString *TDURLEscapedString(NSString *string);
NSString *TDURLUnescapedString(NSString *string);

NSString* TDJSONFromObject(id object) {
	NSError *error = nil;
	NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];

	if (error)
        NSLog(@"%@", [error description]);

	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

NSString* TDURLEscapedString(NSString *string) {
	// Encode all the reserved characters, per RFC 3986
	// (<http://www.ietf.org/rfc/rfc3986.txt>)
	CFStringRef escaped =
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            (CFStringRef)string,
                                            NULL,
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                            kCFStringEncodingUTF8);
	return (NSString *)CFBridgingRelease(escaped);
}

NSString *TDURLUnescapedString(NSString *string) {
	NSMutableString *resultString = [NSMutableString stringWithString:string];
	[resultString replaceOccurrencesOfString:@"+"
								  withString:@" "
									 options:NSLiteralSearch
									   range:NSMakeRange(0, [resultString length])];
	return [resultString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


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

@implementation TDDeviceInfo

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





@interface TDAnalytics ()

@property (nonatomic) NSNumber *sessionId;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) BOOL isSuspended;
@property (nonatomic) double lastTime;
@property (nonatomic) double sessionLength;

@end

@implementation TDAnalytics

+ (TDAnalytics *)sharedInstance {
    static TDAnalytics *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
//        NSData *data = [NSData dataWithContentsOfFile:[NSHomeDirectory() stringByAppendingString:kAnalyticsLogfile]];
//        _sharedInstance = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//        if (_sharedInstance == nil) {
            _sharedInstance = [[TDAnalytics alloc] init];
//        }
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timer = nil;
        self.lastTime = CFAbsoluteTimeGetCurrent();
        self.sessionLength = 0;
		self.isSuspended = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(didEnterBackgroundCallback:)
													 name:UIApplicationDidEnterBackgroundNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willEnterForegroundCallback:)
													 name:UIApplicationWillEnterForegroundNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willTerminateCallback:)
													 name:UIApplicationWillTerminateNotification
												   object:nil];

    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.timer) {
        [self.timer invalidate];
    }
}
//
//#pragma mark - save and load data to disk
//
//- (id)initWithCoder:(NSCoder *)decoder {
//    self = [self init];
//    if (self) {
//        _sessionId = [decoder decodeObjectForKey:@"sessionId"];
//        _events   = [decoder decodeObjectForKey:@"events"];
//    }
//    return self;
//}
//
//- (void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeObject:self.sessionId forKey:@"sessionId"];
//    [coder encodeObject:self.events forKey:@"events"];
//}
//
//- (void)save {
//    NSString *filename = [NSHomeDirectory() stringByAppendingString:kAnalyticsLogfile];
//    [TDFileSystemHelper removeFileAt:filename];
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
//    [data writeToFile:filename atomically:YES];
//}

#pragma mark - session handling

- (void)start {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60
                                                  target:self
                                                selector:@selector(onTimer:)
                                                userInfo:nil
                                                 repeats:YES];
    [self newSession];
}

- (void)newSession {
    [[TDAPIClient sharedInstance] startSession:TDDeviceInfo.metrics callback:^(NSNumber *sessionId) {
        self.sessionId = sessionId;
//        [self save];
    }];
}

- (void)updateDuration {
	double currTime = CFAbsoluteTimeGetCurrent();
	self.sessionLength += currTime - self.lastTime;
	self.lastTime = currTime;

    if (self.sessionId) {
        [[TDAPIClient sharedInstance] updateSession:self.sessionId duration:self.sessionLength];
    } else {
        [self newSession];
    }
}

- (void)onTimer:(NSTimer *)timer {
	if (self.isSuspended == YES) {
		return;
    }
    [self updateDuration];
}

- (void)suspend {
	self.isSuspended = YES;
    [self updateDuration];
}

- (void)resume {
	double currTime = CFAbsoluteTimeGetCurrent();
    if (self.lastTime && currTime - self.lastTime > kMaxSessionLength) {
        [self newSession];
    }
    self.lastTime = currTime;
	self.isSuspended = NO;
}

- (void)exit {
    [self suspend];
    self.sessionId = nil;
//    [self save];
}

#pragma mark - Notification callbacks

- (void)didEnterBackgroundCallback:(NSNotification *)notification {
	debug NSLog(@"TDApp didEnterBackground");
	[self suspend];
}

- (void)willEnterForegroundCallback:(NSNotification *)notification {
	debug NSLog(@"TDApp willEnterForeground");
	[self resume];
}

- (void)willTerminateCallback:(NSNotification *)notification {
	debug NSLog(@"TDApp willTerminate");
	[self exit];
}


@end

