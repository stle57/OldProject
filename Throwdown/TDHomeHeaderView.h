//
//  TDHomeHeaderView.h
//  Throwdown
//
//  Created by Andrew C on 3/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPostUpload.h"

@interface TDHomeHeaderView : UIView

- (id)initWithTableView:(UITableView *)tableView;
- (void)addUpload:(TDPostUpload *)upload;

@end
