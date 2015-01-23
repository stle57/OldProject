//
//  TDLoginViewController.h
//  Throwdown
//
//  Created by Andrew C on 2/10/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDTextField.h"
#import "TDAppCoverBackgroundView.h"

@interface TDLoginViewController : UIViewController <TDTextFieldDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet TDTextField *userNameTextField;
@property (weak, nonatomic) IBOutlet TDTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progress;

- (IBAction)resetButtonPressed:(id)sender;
@end
