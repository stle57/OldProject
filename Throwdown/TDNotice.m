//
//  TDNotice.m
//  Throwdown
//
//  Created by Andrew C on 6/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDNotice.h"
#import "TDConstants.h"
#import "TDAppDelegate.h"
#import "TDAPIClient.h"

@interface TDNotice ()

@property (nonatomic, readonly) NSString *action;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSDictionary *col;

@end

@implementation TDNotice

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _message = [dict objectForKey:@"message"];
        if (![self isNull:@"cta" in:dict]) {
            _cta = [dict objectForKey:@"cta"];
        }
        if (![self isNull:@"confirmation" in:dict]) {
            _confirmation = [dict objectForKey:@"confirmation"];
        }
        if (![self isNull:@"dismiss_on_call" in:dict]) {
            _dismissOnCall = [[dict objectForKey:@"dismiss_on_call"] boolValue];
        } else {
            _dismissOnCall = NO;
        }
        if (![self isNull:@"dark_cta_color" in:dict]) {
            _darkCTAColor = [[dict objectForKey:@"dark_cta_color"] boolValue];
        } else {
            _darkCTAColor = NO;
        }
        if (![self isNull:@"dark_text_color" in:dict]) {
            _darkTextColor = [[dict objectForKey:@"dark_text_color"] boolValue];
        } else {
            _darkTextColor = YES;
        }

        if (![self isNull:@"action" in:dict]) {
            _action = [dict objectForKey:@"action"];
        }
        if (![self isNull:@"url" in:dict]) {
            _url = [dict objectForKey:@"url"];
        }
        if (![self isNull:@"color" in:dict]) {
            _col = [dict objectForKey:@"color"];
        }
    }
    return self;
}

- (BOOL)isNull:(NSString *)property in:(NSDictionary *)dict {
    if (![dict objectForKey:property] || [dict objectForKey:property] == [NSNull null]) {
        return YES;
    }
    return NO;
}

- (UIColor *)color {
    // Litmus test (no need to check for all r/g/b)
    if (!self.col || ![self.col objectForKey:@"r"]) {
        return [TDConstants backgroundColor];
    }
    return [UIColor colorWithRed:[[self.col objectForKey:@"r"] floatValue]/255
                           green:[[self.col objectForKey:@"g"] floatValue]/255
                            blue:[[self.col objectForKey:@"b"] floatValue]/255
                           alpha:[[self.col objectForKey:@"a"] floatValue]];
}

- (void)callAction {
    if (self.confirmation && [self.confirmation length] > 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:self.confirmation
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    if ([@"call_url" isEqualToString:self.action]) {
        [[TDAPIClient sharedInstance] callURL:self.url];
    } else if ([@"open_url" isEqualToString:self.action]) {
        NSURL *fullUrl = [NSURL URLWithString:self.url];
        if ([[UIApplication sharedApplication] canOpenURL:fullUrl]) {
            [[UIApplication sharedApplication] openURL:fullUrl];
        }
    }
}

@end
