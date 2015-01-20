//
//  TDTagUserFeedViewController.h
//  Throwdown
//
//  Created by Andrew C on 1/19/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDPostsViewController.h"

@interface TDTagUserFeedViewController : TDPostsViewController

- (void)setUserId:(NSNumber *)userId tagName:(NSString *)tagName;

@end
