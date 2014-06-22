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
#import "TDDeviceInfo.h"

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
        _sharedInstance = [[TDAnalytics alloc] init];
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

#pragma mark - event handling

- (void)logEvent:(NSString *)event {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[TDAPIClient sharedInstance] logEvent:event sessionId:self.sessionId];
    });
}

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
    // First check if already installed, then register session (for the id) then log installed event if new install
    BOOL hasUUID = [TDDeviceInfo hasUUID];
    [[TDAPIClient sharedInstance] startSession:TDDeviceInfo.metrics callback:^(NSNumber *sessionId) {
        self.sessionId = sessionId;
        if (!hasUUID) {
            [[TDAnalytics sharedInstance] logEvent:@"installed"];
        }
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

