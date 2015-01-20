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
@property (nonatomic, readonly) BOOL dismissOnCall;
@property (nonatomic, readonly) BOOL darkTextColor;
@property (nonatomic, readonly) BOOL darkCTAColor;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *image;
@property (nonatomic, readonly) NSString *imageFileName;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (UIColor *)color;
- (void)callAction;

@end
