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

@property (nonatomic, strong) NSMutableArray *filteredList;
@property (nonatomic) NSMutableArray  *userNames;
@property (nonatomic, weak) id <TDUserListViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)showUserSuggestions:(UITextView *)textView callback:(void (^)(BOOL success))callback;
- (void)updateFrame:(CGRect)frame;

@end
