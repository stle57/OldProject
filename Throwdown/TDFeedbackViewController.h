//
//  TDFeedbackViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 11/13/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDKeyboardObserver.h"

#define TD_BUTTON_HEIGHT 49
#define TD_VIEW_WIDTH 290
@interface TDFeedbackViewController : UIViewController<UITextViewDelegate, TDKeyboardObserverDelegate>

@property (nonatomic, retain) IBOutlet UIView *view;
@property (nonatomic, retain) IBOutlet UIButton *sendButton;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIView *divider1;
@property (weak, nonatomic) IBOutlet UIView *divider2;
//
//- (IBAction)sendButtonHit:(id)sender;
//- (IBAction)cancelButtonHit:(id)sender;

@end
