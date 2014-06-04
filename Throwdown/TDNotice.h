//
//  TDNotice.h
//  Throwdown
//
//  Created by Andrew C on 6/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDNotice : NSObject

@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly) NSString *cta;
@property (nonatomic, readonly) NSString *confirmation;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (UIColor *)color;
- (void)callAction;

@end
