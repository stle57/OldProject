//
//  TDAnalytics.h
//  Throwdown
//
//  Created by Andrew C on 4/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDAnalytics : NSObject // <NSCoding>
+ (TDAnalytics *)sharedInstance;
- (void)start;
- (void)logEvent:(NSString *)event;
- (void)logEvent:(NSString *)event withInfo:(NSString *)info source:(NSString *)source;
@end
