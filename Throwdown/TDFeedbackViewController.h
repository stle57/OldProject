//
//  TDFeedbackViewController.h
//  Throwdown
//
//  Created by Stephanie Le on 11/13/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TD_BUTTON_HEIGHT 49
#define TD_VIEW_WIDTH 290
@interface TDFeedbackViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIView *view;
@property (nonatomic, retain) IBOutlet UIButton *sendButton;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
//
//- (IBAction)sendButtonHit:(id)sender;
//- (IBAction)cancelButtonHit:(id)sender;

@end
