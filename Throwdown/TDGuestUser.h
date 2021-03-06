//
//  TDGuestUser.h
//  Throwdown
//
//  Created by Stephanie Le on 1/22/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDGuestUser : NSObject
@property (nonatomic) NSMutableArray *goalsList;
@property (nonatomic) NSMutableArray *interestsList;

+ (TDGuestUser *)sharedInstance;
- (void)updateGuestInfo:goalsList interestsList:(NSArray*)interestsList;
- (void)resetList;
@end
