//
//  TDUserListViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 7/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDUserList.h"

@class TDUserListViewController;
@protocol TDUserListViewDelegate <NSObject>
- (void)addItemViewController:(TDUserListViewController *)controller didFinishEnteringItem:(NSDictionary *)item;
@end

@interface TDUserListViewController : UITableViewController<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) TDUserList *communityInfo;

@property (nonatomic, strong) NSMutableArray *filteredList;
@property (nonatomic) NSMutableArray  *userNames;
@property (nonatomic, weak) id <TDUserListViewDelegate> delegate;

-(void)showTableView:(NSString*)filterString;

@end
