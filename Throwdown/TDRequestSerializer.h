//
//  TDRequestSerializer.h
//  Throwdown
//
//  Created by Andrew C on 10/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "AFURLRequestSerialization.h"

@interface TDRequestSerializer : AFHTTPRequestSerializer
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
                                     error:(NSError *__autoreleasing *)error;
@end
