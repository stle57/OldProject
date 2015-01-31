//
//  TDGuestUserProfileViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 12/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPostsViewController.h"
#import "TDGuestInfoCell.h"

@interface TDGuestUserProfileViewController : TDPostsViewController<TDGuestUserInfoCellDelegate>
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil guestPosts:(NSDictionary*)guestPosts;
@property (nonatomic) NSDictionary *guestGoalsAndInterests;
@property (weak, nonatomic) IBOutlet UIButton *addButton;

- (IBAction)addButtonPressed:(id)sender;
-(void)refreshPosts:(NSDictionary*)response;
@end
