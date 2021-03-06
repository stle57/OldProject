//
//  TDUserProfileViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/7/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDPostsViewController.h"
#import "TDUserProfileEditViewController.h"
#import "TDConstants.h"

@interface TDUserProfileViewController : TDPostsViewController

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic) BOOL noProfileHeader;


- (IBAction)settingsButtonHit:(id)sender;
- (IBAction)closeButtonHit:(id)sender;
- (void)unwindToRoot;

@end
