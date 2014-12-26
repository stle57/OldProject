//
//  TDGetStartedViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 12/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDGetStartedViewController.h"
#import "TDConstants.h"

@interface TDGetStartedViewController ()

@end

@implementation TDGetStartedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
//    self.view.layer.borderColor = [[UIColor blueColor] CGColor];
//    self.view.layer.borderWidth = 2.0;
    // Do any additional setup after loading the view from its nib.
    self.imageView.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"td_logo_app_cover"].size.width/2,
                                      48,
                                      [UIImage imageNamed:@"td_logo_app_cover"].size.width,
                                      [UIImage imageNamed:@"td_logo_app_cover"].size.height);
    
    self.label.frame = CGRectMake(SCREEN_WIDTH/2 - self.label.frame.size.width/2,
                                  self.imageView.frame.origin.y + self.imageView.frame.size.height + 10,
                                  self.label.frame.size.width,
                                  self.label.frame.size.height);
    self.label.textColor = [TDConstants headerTextColor];
    self.label.font = [TDConstants fontRegularSized:17];
    
    self.loginButton.frame = CGRectMake(SCREEN_WIDTH/2 - self.loginButton.frame.size.width/2,
                                        SCREEN_HEIGHT - 30 - self.loginButton.frame.size.height,
                                        self.loginButton.frame.size.width,
                                        self.loginButton.frame.size.height);
    // Create the attributes
    NSString *text = @"Already have an account? Login";
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [TDConstants fontRegularSized:14.], NSFontAttributeName,
                           [UIColor whiteColor], NSForegroundColorAttributeName, nil];
    NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                              [TDConstants fontBoldSized:14.], NSFontAttributeName, nil];
    const NSRange range = NSMakeRange(text.length - 5,5); // range of " Login ". Ideally this should not be hardcoded
    
    // Create the attributed string (text + attributes)
    NSMutableAttributedString *attributedText =
    [[NSMutableAttributedString alloc] initWithString:text
                                           attributes:attrs];
    [attributedText setAttributes:subAttrs range:range];

    self.loginButton.titleLabel.attributedText = attributedText;
    self.getStartedButton.frame = CGRectMake(
                                    SCREEN_WIDTH/2 - [UIImage imageNamed:@"btn_get_started"].size.width/2,
                                    SCREEN_HEIGHT - 30 - self.loginButton.frame.size.height - 14 - [UIImage imageNamed:@"btn_get_started"].size.height,
                                    [UIImage imageNamed:@"btn_get_started"].size.width,
                                    [UIImage imageNamed:@"btn_get_started"].size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(loginButtonPressed)]) {
        [self.delegate loginButtonPressed];
    }
}

- (IBAction)getStartedButtonPressed {
    debug NSLog(@"get started button pressed");
    if (self.delegate && [self.delegate respondsToSelector:@selector(getStartedButtonPressed)]) {
        [self.delegate getStartedButtonPressed];
    }
}
@end
