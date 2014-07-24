//
//  TDUserListView.h
//  Throwdown
//
//  Created by Stephanie Le on 7/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDUserList.h"

@class TDUserListView;

@protocol TDUserListViewDelegate <NSObject>
- (void)selectedUser:(NSDictionary *)user forUserNameFilter:(NSString *)userNameFilter;
@end

@interface TDUserListView : UIView<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) TDUserList *communityInfo;
@property (nonatomic, strong) NSMutableArray *filteredList;
@property (nonatomic) NSMutableArray  *userNames;
@property (nonatomic, weak) id <TDUserListViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;
- (BOOL)shouldShowUserSuggestions:(NSString *)text;
- (void)updateFrame:(CGRect)frame;

@end
