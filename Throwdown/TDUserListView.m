 //
//  TDUserListView.m
//  Throwdown
//
//  Created by Stephanie Le on 7/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserListView.h"
#import "TDConstants.h"
#import "TDAPIClient.h"
#include "TDUserAPI.h"
#import "TDUser.h"
#import "TDUserListCell.h"
#import "TDTextViewControllerHelper.h"

@interface TDUserListView ()

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSString *userNameFilter;

@end

@implementation TDUserListView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 1, 320, frame.size.height)];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.separatorColor = [UIColor clearColor];
        [self addSubview:self.tableView];

        CGFloat scale = [[UIScreen mainScreen] scale];
        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, scale > 1 ? 0.5 : 0, 320, 1.0 / scale)];
        topLine.backgroundColor = [TDConstants borderColor];
        [self addSubview:topLine];

        self.communityInfo = [TDUserList sharedInstance];
        self.hidden = YES;
    }
    return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TDUserListCell";

    TDUserListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TDUserListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSDictionary* user = [self.filteredList objectAtIndex:indexPath.row];

    // Don't need to update if it's the same user, avoids UI flashing
    if (cell.userId != [[user objectForKey:@"id"] integerValue]) {
        cell.textLabel.text = [user objectForKey:@"username"];
        cell.detailTextLabel.text = [user objectForKey:@"name"];
        if ([user objectForKey:@"picture"] != [NSNull null] && ![[user objectForKey:@"picture"] isEqualToString:@"default"]) {
            cell.profileImage.image = nil;
            [[TDAPIClient sharedInstance] setImage:@{@"imageView":cell.profileImage,
                                                     @"filename":[user objectForKey:@"picture"],
                                                     @"width":[NSNumber numberWithInt:cell.imageView.frame.size.width],
                                                     @"height":[NSNumber numberWithInt:cell.imageView.frame.size.height]}];

        } else {
            cell.profileImage.image = [UIImage imageNamed:@"prof_pic_default"];
        }
        cell.userId = [[user objectForKey:@"id"] integerValue];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *selectedUser = [self.filteredList objectAtIndex:indexPath.row];
    debug NSLog(@"selectedUser=%@", selectedUser);

    // Pass data back to controller
    [self.delegate selectedUser:selectedUser forUserNameFilter:self.userNameFilter];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (BOOL)shouldShowUserSuggestions:(NSString *)text {
    self.userNameFilter = [TDTextViewControllerHelper findUsernameInText:text];
    if (self.userNameFilter != nil && [self.userNameFilter length] > 0) {
        [self.filteredList removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF.username like[c] %@) OR (SELF.name like[c] %@)",
                                  [NSString stringWithFormat:@"%@*", self.userNameFilter],
                                  [NSString stringWithFormat:@"*%@*", self.userNameFilter]];
        self.filteredList = [NSMutableArray arrayWithArray:[self.communityInfo.userList filteredArrayUsingPredicate:predicate]];
        if ([self.filteredList count] != 0){
            [self.tableView reloadData];
            self.hidden = NO;
            return YES;
        }
    }
    self.hidden = YES;
    return NO;
}

- (void)updateFrame:(CGRect)frame {
    self.frame = frame;
    self.tableView.frame = CGRectMake(0, 0, 320, frame.size.height);
}

@end
