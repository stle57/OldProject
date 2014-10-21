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
#import <SDWebImageManager.h>
#import <UIImage+Resizing.h>

@interface TDUserListView ()

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSString *userNameFilter;
@property (nonatomic) BOOL isWaitingForCallback;
@property (nonatomic) UITextView *currentTextView;

@end

@implementation TDUserListView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 1, SCREEN_WIDTH, frame.size.height)];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.separatorColor = [UIColor clearColor];
        [self addSubview:self.tableView];

        CGFloat scale = [[UIScreen mainScreen] scale];
        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, scale > 1 ? 0.5 : 0, SCREEN_WIDTH, 1.0 / scale)];
        topLine.backgroundColor = [TDConstants lightBorderColor];
        [self addSubview:topLine];

        self.userList = [TDUserList sharedInstance];
        self.hidden = YES;
        self.isWaitingForCallback = NO;
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
        cell = [[TDUserListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSDictionary* user = [self.filteredList objectAtIndex:indexPath.row];

    // Don't need to update if it's the same name/username, avoids UI flashing
    NSString *username = [@"@" stringByAppendingString:[user objectForKey:@"username"]];
    if (![cell.name.text isEqualToString:[user objectForKey:@"name"]] || ![cell.username.text isEqualToString:username]) {
        cell.name.text = [user objectForKey:@"name"];
        cell.username.text = username;
        cell.profileImage.image = nil;
        if ([user objectForKey:@"picture"] != [NSNull null] && ![[user objectForKey:@"picture"] isEqualToString:@"default"]) {
            [self downloadUserImage:[user objectForKey:@"picture"] cell:cell];
        } else {
            cell.profileImage.image = [UIImage imageNamed:@"prof_pic_default"];
        }
        cell.userId = [[user objectForKey:@"id"] integerValue];
    }
    return cell;
}

- (void)downloadUserImage:(NSString *)profileImage cell:(TDUserListCell *)cell {
    cell.userImageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", RSHost, profileImage]];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:cell.userImageURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress bar here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        CGFloat width = cell.profileImage.frame.size.width * [UIScreen mainScreen].scale;
        image = [image scaleToSize:CGSizeMake(width, width)];
        if (![finalURL isEqual:cell.userImageURL]) {
            return;
        }
        if (!error && image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cell.profileImage) {
                    cell.profileImage.image = image;
                }
            });
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *selectedUser = [self.filteredList objectAtIndex:indexPath.row];
    debug NSLog(@"selectedUser=%@", selectedUser);

    // Pass data back to controller
    [self.delegate selectedUser:selectedUser forUserNameFilter:self.userNameFilter];

    [self hideView];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (void)showUserSuggestions:(UITextView *)textView callback:(void (^)(BOOL success))callback {
    // TODO: there's a small jumping effect when user types @aaaaaaaaa (example of missing username)
    // We should just remove the autocorrection anytime we see an @-sign, now it requires a character and is therefore reset all the time
    self.userNameFilter = [TDTextViewControllerHelper findUsernameInText:textView.text];
    if (self.userNameFilter != nil && [self.userNameFilter length] > 0) {
        if (self.hidden) {
            self.currentTextView = textView;
            if (textView.autocorrectionType != UITextAutocorrectionTypeNo) {
                [textView resignFirstResponder];
                textView.autocorrectionType = UITextAutocorrectionTypeNo;
                textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
                [textView becomeFirstResponder];
            }
        }
        if (!self.isWaitingForCallback) {
            self.isWaitingForCallback = YES;
            [self.userList getListWithCallback:^(NSArray *list) {
                self.isWaitingForCallback = NO;
                [self.filteredList removeAllObjects];
                NSString *regexString = [NSString stringWithFormat:@".*\\B%@.*", self.userNameFilter];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF.username matches[c] %@) OR (SELF.name matches[c] %@)", regexString, regexString];
                self.filteredList = [NSMutableArray arrayWithArray:[list filteredArrayUsingPredicate:predicate]];
                if ([self.filteredList count] != 0) {
                    [self.tableView reloadData];
                    self.hidden = NO;
                    if (callback) {
                        callback(YES);
                    }
                } else {
                    [self hideView];
                    if (callback) {
                        callback(NO);
                    }
                }
            }];
        }
    } else if (!self.hidden) {
        [self hideView];
        if (callback) {
            callback(NO);
        }
    }
}

- (void)hideView {
    if (self.currentTextView) {
        [self.currentTextView resignFirstResponder];
        self.currentTextView.autocorrectionType = UITextAutocorrectionTypeYes;
        self.currentTextView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [self.currentTextView becomeFirstResponder];
        self.currentTextView = nil;
    }
    self.hidden = YES;
}

- (void)updateFrame:(CGRect)frame {
    self.frame = frame;
    self.tableView.frame = CGRectMake(0, 0, SCREEN_WIDTH, frame.size.height);
}

@end
