//
//  TDUserProfileEditViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/9/14.
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
#include "TDUserEditCell.h"
#import "TDConstants.h"

@interface TDUserProfileEditViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate>
{
    TDUser *profileUser;
    NSString *name;
    NSString *username;
    NSString *phone;
    NSString *email;
    NSString *password;
    NSString *bio;
    NSString *pictureFileName;
    CGRect origTableViewFrame;
    CGRect statusBarFrame;
    BOOL keybdUp;
    kFromProfileScreenType fromFrofileType;
    UIImage *editedProfileImage90x90;
    UIImageView *tempFlyInImageView;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionHeaderLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *bio;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *pictureFileName;
@property (nonatomic, retain) TDUser *profileUser;
@property (nonatomic, assign) kFromProfileScreenType fromFrofileType;
@property (nonatomic, retain) UIImage *editedProfileImage90x90;
@property (nonatomic, retain) UIImageView *tempFlyInImageView;

//-(IBAction)closeButtonHit:(id)sender;
//-(IBAction)saveButtonHit:(id)sender;
-(IBAction)doneButtonHit:(id)sender;

@end
