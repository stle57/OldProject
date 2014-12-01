//
//  TDFeedbackViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 11/13/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDFeedbackViewController.h"
#import "TDConstants.h"
#import "TDAPIClient.h"
#import "TDCurrentUser.h"
#import "TDRateAppView.h"

@interface TDFeedbackViewController ()
@property (nonatomic) UIGestureRecognizer *tapGesture;
@property (nonatomic) UIGestureRecognizer *emailGesture;
@property (nonatomic) TDKeyboardObserver *keyboardObserver;
@property (nonatomic) CGRect origFrame;
@end

@implementation TDFeedbackViewController
@synthesize sendButton;
@synthesize cancelButton;
@synthesize tapGesture;

-(void)dealloc {
    [self.keyboardObserver stopListening];
    self.keyboardObserver = nil;
    self.textView.delegate = nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UITextField appearance] setTintColor:[UIColor blackColor]];
    [[UITextView appearance] setTintColor:[UIColor blackColor]];
    
    CGRect frame = self.view.frame;
    frame.size.width = 290;
    frame.size.height = 310;
    self.view.frame = frame;

    self.emailField.text = [NSString stringWithFormat:@"Email:  %@", [TDCurrentUser sharedInstance].email ];
    self.emailField.font = [TDConstants fontRegularSized:16];
    
    CGRect emailDividerFrame = self.emailDivider.frame;
    emailDividerFrame.origin.x = 5;
    emailDividerFrame.origin.y = self.emailField.frame.origin.y + self.emailField.frame.size.height;
    emailDividerFrame.size.height = .5;
    emailDividerFrame.size.width = TD_VIEW_WIDTH - 10;
    self.emailDivider.frame = emailDividerFrame;
    self.emailDivider.layer.backgroundColor = [[TDConstants darkBackgroundColor] CGColor];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    self.emailField.leftView = paddingView;
    self.emailField.leftViewMode = UITextFieldViewModeAlways;
    
    self.textView.frame = CGRectMake(0, self.emailField.frame.origin.y + self.emailField.frame.size.height+1, TD_VIEW_WIDTH, self.view.frame.size.height -self.emailField.frame.size.height - (TD_BUTTON_HEIGHT *2));
    self.textView.font = [TDConstants fontRegularSized:16];
    
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsMake(5, 10, 8, 10);
    self.textView.text = @"Please share your feedback with us.\nThanks!";
    self.textView.textColor = [UIColor lightGrayColor];
    
    self.sendButton.frame = CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height, TD_VIEW_WIDTH, TD_BUTTON_HEIGHT);
    NSString *sendButtonStr = @"Send";
    [self.sendButton setTitle:sendButtonStr forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.sendButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateSelected];
    [self.sendButton addTarget:self action: @selector(sendButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.enabled = NO;
    CGRect divider1Frame = self.divider1.frame;
    
    divider1Frame.origin.x = 0;
    divider1Frame.origin.y = self.textView.frame.origin.y + self.textView.frame.size.height ;
    divider1Frame.size.height = .5;
    self.divider1.frame = divider1Frame;
    self.divider1.layer.backgroundColor = [[TDConstants darkBackgroundColor] CGColor];
    
    CGRect divider2Frame = self.divider2.frame;
    divider2Frame.origin.x = 0;
    divider2Frame.origin.y = self.sendButton.frame.origin.y  + self.sendButton.frame.size.height ;
    divider2Frame.size.height = .5;
    self.divider2.frame = divider2Frame;
    self.divider2.layer.backgroundColor = [[TDConstants darkBackgroundColor] CGColor];
    
    self.cancelButton.frame = CGRectMake(0, self.sendButton.frame.origin.y + TD_BUTTON_HEIGHT, TD_VIEW_WIDTH, TD_BUTTON_HEIGHT);
    NSString *cancelButtonStr = @"Cancel";
    [self.cancelButton setTitle:cancelButtonStr forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [TDConstants fontRegularSized:18];
    [self.cancelButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[TDConstants commentTextColor] forState:UIControlStateSelected];
    [self.cancelButton addTarget:self action: @selector(cancelButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    
    self.textView.delegate = self;
    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.origFrame = self.view.frame;

    [self.keyboardObserver startListening];
}

- (void)cancelButtonHit:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDRemoveHomeViewControllerOverlay
                                                        object:self
                                                      userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TDRemoveRateView
                                                        object:self
                                                      userInfo:nil];
    [self.view removeFromSuperview];
}

- (void)sendButtonHit:(id)sender {
    NSArray *myArray = [self.emailField.text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];

    NSString *email = [myArray[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [[TDAPIClient sharedInstance] sendFeedbackEmail:self.textView.text email:email callback:^(BOOL success) {
       if (success) {
           
           [[NSNotificationCenter defaultCenter] postNotificationName:TDRemoveHomeViewControllerOverlay
                                                               object:self
                                                             userInfo:nil];
           [[NSNotificationCenter defaultCenter] postNotificationName:TDRemoveRateView
                                                               object:self
                                                             userInfo:nil];
           [self.view removeFromSuperview];
           
           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Feedback Received"
                                                           message:@"Thank you for your feedback.\nWe will get back to you shortly.\n- The Throwdown Team"
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
           [alert show];

       } else {
           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sending Feedback Error"
                                                           message:@"Error sending feedback to Throwdown.  Please try again."
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
           [alert show];
           
       }
   }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (keybdUp) {
        return;
    }
    NSDictionary *info = [notification userInfo];
    
    CGFloat adjustHeight = self.cancelButton.frame.size.height + self.sendButton.frame.size.height + self.emailField.frame.size.height;
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGFloat yPositionOfView = self.view.frame.origin.x <= 15 ? 20 : self.view.frame.origin.x;
    CGFloat heightOfView = SCREEN_HEIGHT - TD_FEEDBACK_BOTTOM_PADDING - yPositionOfView - keyboardSize.height;

    NSNumber *curveValue = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat textViewHeight = heightOfView - adjustHeight;

    // animationCurve << 16 to convert it from a view animation curve to a view animation option
    [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 8) animations:^{

        CGRect newFrame = self.origFrame;
        newFrame.size.height = heightOfView;
        newFrame.origin.y = yPositionOfView;
        self.view.frame = newFrame;
        
        CGRect textViewFrame = self.textView.frame;
        textViewFrame.size.height = textViewHeight;
        self.textView.frame = textViewFrame;
        
        CGRect divider1Frame = self.divider1.frame;
        divider1Frame.origin.y = self.textView.frame.origin.y + self.textView.frame.size.height ;
        self.divider1.frame = divider1Frame;
        
        CGRect sendButtonFrame = self.sendButton.frame;
        sendButtonFrame.origin.y = self.textView.frame.origin.y + self.textView.frame.size.height;
        self.sendButton.frame = sendButtonFrame;
        
        CGRect divider2Frame = self.divider2.frame;
        divider2Frame.origin.y = self.sendButton.frame.origin.y  + self.sendButton.frame.size.height ;
        self.divider2.frame = divider2Frame;
        
        CGRect cancelButtonFrame = self.cancelButton.frame;
        cancelButtonFrame.origin.y = self.sendButton.frame.origin.y + self.sendButton.frame.size.height;
        self.cancelButton.frame = cancelButtonFrame;

    } completion:^(BOOL done) {
        if (done) {
            keybdUp = YES;
        }
    }];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.textView addGestureRecognizer:self.tapGesture];

    self.emailGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleEmailTapFrom:)];
    [self.emailField addGestureRecognizer:self.emailGesture];
}

- (void)handleTapFrom:(UITapGestureRecognizer *)tap {
    if ([self.textView isFirstResponder]) {
        [self.emailField becomeFirstResponder];
        [self.textView resignFirstResponder];
    } else if ([self.emailField isFirstResponder]) {
        [self.textView becomeFirstResponder];
        [self.emailField resignFirstResponder];
    }
}

- (void)handleEmailTapFrom:(UITapGestureRecognizer *)tap {
    if ([self.textView isFirstResponder]) {
        [self.emailField becomeFirstResponder];
        [self.textView resignFirstResponder];
    } else if ([self.emailField isFirstResponder]) {
        [self.textView becomeFirstResponder];
        [self.emailField resignFirstResponder];
    }

}
- (void)keyboardDidHide:(NSNotification *)notification {
    if (keybdUp == NO) {
        return;
    }
    [self.textView removeGestureRecognizer:self.tapGesture];
    [self.emailField removeGestureRecognizer:self.emailGesture];
    self.tapGesture = nil;
    self.emailGesture = nil;
    [UIView animateWithDuration: 0.3
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         //self.view.frame = self.origFrame;
                     }
                     completion:^(BOOL done) {
                         
                         if (done)
                         {
                             keybdUp = NO;
                         }
                     }];

}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.textView.text = @"";
    self.textView.textColor = [UIColor blackColor];
}

- (void)textViewDidChange:(UITextView *)textView {
    if([self.textView.text length] == 0) {
        self.sendButton.enabled = NO;
    } else {
        self.sendButton.enabled = YES;
    }
}

@end
