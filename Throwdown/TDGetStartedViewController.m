//
//  TDGetStartedViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 12/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDGetStartedViewController.h"
#import "TDConstants.h"
#import "TDAnalytics.h"

@interface TDGetStartedViewController ()

@end

@implementation TDGetStartedViewController
static NSString *tdLogoAppStr = @"td_logo_app_cover";
static NSString *getStartedButtonStr = @"btn_get_started";

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TDAnalytics sharedInstance] logEvent:@"welcome_view"];

    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    // Do any additional setup after loading the view from its nib.
    self.imageView.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:tdLogoAppStr].size.width/2,
                                      48,
                                      [UIImage imageNamed:tdLogoAppStr].size.width,
                                      [UIImage imageNamed:tdLogoAppStr].size.height);
    
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
    NSString *loginStr=@"login";
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           [TDConstants fontRegularSized:14.], NSFontAttributeName,
                           [UIColor whiteColor], NSForegroundColorAttributeName, nil];
    NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                              [TDConstants fontSemiBoldSized:14.], NSFontAttributeName, nil];
    const NSRange range = NSMakeRange(text.length - loginStr.length, loginStr.length); // range of " Login ". Ideally this should not be hardcoded
    
    // Create the attributed string (text + attributes)
    NSMutableAttributedString *attributedText =
    [[NSMutableAttributedString alloc] initWithString:text
                                           attributes:attrs];
    [attributedText setAttributes:subAttrs range:range];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init] ;
    [paragraphStyle setAlignment:NSTextAlignmentCenter];

    [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    self.loginButton.titleLabel.attributedText = attributedText;
    [self.loginButton.titleLabel setNumberOfLines:1];
    [self.loginButton sizeToFit];

    CGRect loginFrame = self.loginButton.frame;
    loginFrame.origin.x = SCREEN_WIDTH/2 - self.loginButton.frame.size.width/2;
    loginFrame.origin.y = SCREEN_HEIGHT - 30 - self.loginButton.frame.size.height;
    self.loginButton.frame = loginFrame;
    
    self.getStartedButton.frame = CGRectMake(
                                    SCREEN_WIDTH/2 - [UIImage imageNamed:getStartedButtonStr].size.width/2,
                                    SCREEN_HEIGHT - 30 - self.loginButton.frame.size.height - 14 - [UIImage imageNamed:getStartedButtonStr].size.height,
                                    [UIImage imageNamed:getStartedButtonStr].size.width,
                                    [UIImage imageNamed:getStartedButtonStr].size.height);
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(getStartedButtonPressed)]) {
        [self.delegate getStartedButtonPressed];
    }
}
@end
