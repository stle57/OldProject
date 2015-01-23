//
//  TDGetStartedViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 12/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDGetStartedViewControllerDelegate <NSObject>
@optional
- (void)loginButtonPressed;
- (void)getStartedButtonPressed;
@end

@interface TDGetStartedViewController : UIViewController
@property (nonatomic, weak) id <TDGetStartedViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *label;

- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)getStartedButtonPressed;
@end
