//
//  TDSignupViewController.h
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDTextField.h"

@interface TDSignupStepOneViewController : UIViewController <TDTextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *friendsLabel;
@property (weak, nonatomic) IBOutlet TDTextField *phoneNumberTextField;
@property (weak, nonatomic) IBOutlet TDTextField *emailTextField;
@property (weak, nonatomic) IBOutlet TDTextField *firstLastNameTextField;

@end
