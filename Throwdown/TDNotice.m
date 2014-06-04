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
        _cta = [dict objectForKey:@"cta"];
        _confirmation = [dict objectForKey:@"confirmation"];

        _action = [dict objectForKey:@"action"];
        _url = [dict objectForKey:@"url"];
        _col = [dict objectForKey:@"color"];
    }
    return self;
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
