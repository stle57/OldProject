//
//  UserAPI.h
//  Throwdown
//
//  Created by Andrew C on 1/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDUserAPI : NSObject
+ (TDUserAPI *)sharedInstance;
- (int)getUserId;
@end
