//
//  TDReviewAppCell.h
//  Throwdown
//
//  Created by Stephanie Le on 2/19/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDRateAppView.h"
@protocol TDReviewAppCellDelegate<NSObject>
@optional
-(void)reloadTable;
@end

@interface TDReviewAppCell : UITableViewCell<TDRateAppDelegate>

@property (nonatomic, weak) id <TDReviewAppCellDelegate> delegate;
@end
