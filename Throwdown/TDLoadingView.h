//
//  TDLoadingView.h
//  Throwdown
//
//  Created by Stephanie Le on 12/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDCustomRefreshControl.h"
#import "TDConstants.h"
#import "TDRefreshImageView.h"

@interface TDLoadingView : UIView

@property (nonatomic) NSMutableArray *animationImages;


@property (nonatomic) kLoadingViewType kLoadingViewType;

+ (id)loadingView:(kLoadingViewType)type;
- (void)setViewType:(kLoadingViewType)type;
@end
