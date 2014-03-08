//
//  TDComment.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDUser.h"

@interface TDComment : NSObject

@property (strong, nonatomic, readonly) NSNumber *commentId;
@property (strong, nonatomic, readonly) NSString *body;
@property (nonatomic, readonly) NSDate *createdAt;
@property (strong, nonatomic, readonly) TDUser *user;
@property (nonatomic, assign) CGFloat messageHeight;

- (id)initWithDictionary:(NSDictionary *)dict;
-(void)figureOutMessageLabelHeightForThisMessage:(NSString *)text;
@end
