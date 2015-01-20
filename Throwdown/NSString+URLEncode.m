//
//  NSString+URLEncode.m
//  Throwdown
//
//  Created by Andrew C on 1/20/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "NSString+URLEncode.h"

@implementation NSString (URLEncode)

- (NSString*)urlencodedString {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
}

@end
