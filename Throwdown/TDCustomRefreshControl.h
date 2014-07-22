//
//  TDCustomRefreshControl.h
//  Throwdown
//
//  Created by Andrew C on 7/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDCustomRefreshControl : UIControl

- (void)containingScrollViewDidEndDragging:(UIScrollView *)containingScrollView;
- (void)endRefreshing;

@end
