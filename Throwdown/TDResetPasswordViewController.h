//
//  TDResetPasswordViewController.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/29/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDTextField.h"

@interface TDResetPasswordViewController : UIViewController <TDTextFieldDelegate, UITextFieldDelegate>
{

}

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet TDTextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progress;

@end
