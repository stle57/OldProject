//
//  TDRequestSerializer.m
//  Throwdown
//
//  Created by Andrew C on 10/11/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDRequestSerializer.h"

@implementation TDRequestSerializer

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
                                     error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *request = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    [request setTimeoutInterval:20];

    return request;
}

@end
