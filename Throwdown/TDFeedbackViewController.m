//
//  TDFeedbackViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 11/13/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDFeedbackViewController.h"
#import "TDConstants.h"

@interface TDFeedbackViewController ()

@end

@implementation TDFeedbackViewController
@synthesize sendButton;
@synthesize cancelButton;

- (void)viewDidLoad {
    debug NSLog(@"inside viewDidLoad");
    [super viewDidLoad];
    CGRect frame = self.view.frame;
    frame.size.width = 290;
    frame.size.height = 310;
    self.view.frame = frame;
    self.view.layer.borderColor = [[UIColor redColor] CGColor];
    self.view.layer.borderWidth = 2.;

    self.textView.frame = CGRectMake(0, 0, TD_VIEW_WIDTH, self.view.frame.size.height - (TD_BUTTON_HEIGHT *2));
    self.cancelButton.frame = CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height, TD_VIEW_WIDTH, TD_BUTTON_HEIGHT);
    
    self.textView.layer.borderWidth = 2.;
    self.textView.layer.borderColor = [[UIColor blueColor] CGColor];
    
    NSString *cancelButtonStr = @"Cancel";
    [self.cancelButton setTitle:cancelButtonStr forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.cancelButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateSelected];
    [self.cancelButton addTarget:self action: @selector(cancelButtonHit:) forControlEvents:UIControlEventTouchUpInside];

    self.cancelButton.layer.borderColor = [[UIColor magentaColor] CGColor];
    self.cancelButton.layer.borderWidth = 2.;
    self.sendButton.frame = CGRectMake(0, self.cancelButton.frame.origin.y + TD_BUTTON_HEIGHT, TD_VIEW_WIDTH, TD_BUTTON_HEIGHT);
    NSString *sendButtonStr = @"Send";
    [self.sendButton setTitle:sendButtonStr forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.sendButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateSelected];
    [self.sendButton addTarget:self action: @selector(sendButtonHit:) forControlEvents:UIControlEventTouchUpInside];

    self.sendButton.layer.borderColor = [[UIColor grayColor] CGColor];
    self.sendButton.layer.borderWidth = 2.;
    
    debug NSLog(@"textVie frame = %@", NSStringFromCGRect( self.textView.frame));
    debug NSLog(@"sendButton frame = %@", NSStringFromCGRect(self.sendButton.frame));
    debug NSLog(@"cancelButton frame = %@", NSStringFromCGRect(self.cancelButton.frame));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)cancelButtonHit:(id)sender {
    debug NSLog(@"inside cancelbutton hit");

    [[NSNotificationCenter defaultCenter] postNotificationName:TDRemoveRateView
                                                        object:self
                                                      userInfo:nil];
}

- (void)sendButtonHit:(id)sender {
    debug NSLog (@"inside sendButtonHit");
}
@end
