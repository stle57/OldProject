//
//  TDShareVideoViewController.h
//  Throwdown
//
//  Created by Andrew C on 3/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDUserListView.h"

@interface TDShareVideoViewController : UIViewController<UITableViewDelegate, TDUserListViewDelegate>
- (void)addMedia:(NSString *)filename thumbnail:(NSString *)thumbnailPath isOriginal:(BOOL)original;
@end
