//
//  TDProgressIndicator.h
//  Throwdown
//
//  Created by Andrew C on 3/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol TDProgressIndicatorDelegate <NSObject>

- (void)uploadDidUpdate:(CGFloat)progress;

@end

@interface TDProgressIndicator : UIView <TDProgressIndicatorDelegate>

- (id)initWithTableView:(UITableView *)tableView thumbnailPath:(NSString *)thumbnailPath;

@end
