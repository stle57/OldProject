//
//  TDUserPasswordEditViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPostsViewController.h"
#import "TDAppDelegate.h"
#import "TDPostAPI.h"
#import "TDConstants.h"
#import "TDUserAPI.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "TDUserEditCell.h"
#import "TDConstants.h"

@interface TDUserPasswordEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UITextViewDelegate>
{
    TDUser *profileUser;
    NSString *password1;
    NSString *current;
    NSString *password2;
    CGRect origTableViewFrame;
    CGRect statusBarFrame;
    BOOL keybdUp;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionHeaderLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic, retain) NSString *password1;
@property (nonatomic, retain) NSString *current;
@property (nonatomic, retain) NSString *password2;
@property (nonatomic, retain) TDUser *profileUser;

-(IBAction)doneButtonHit:(id)sender;

@end
