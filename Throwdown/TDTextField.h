//
//  TDTextField.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    kTDTextFieldType_Phone,
    kTDTextFieldType_Email,
    kTDTextFieldType_FirstLast,
    kTDTextFieldType_UserName,
    kTDTextFieldType_Password
};
typedef NSUInteger kTDTextFieldType;

@protocol TDTextFieldDelegate <NSObject>

@optional
-(void)textFieldDidChange:(UITextField *)textField type:(kTDTextFieldType)type;
-(BOOL)textFieldShouldReturn:(UITextField *)textField type:(kTDTextFieldType)type;
-(void)textFieldDidBeginEditing:(UITextField *)textField type:(kTDTextFieldType)type;
@end

@interface TDTextField : UIView <UITextFieldDelegate>
{
    id <TDTextFieldDelegate> __unsafe_unretained delegate;
    kTDTextFieldType type;
    BOOL valid;
}

@property (nonatomic, assign) id <TDTextFieldDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UITextField *textfield;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *xmarkImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, assign) BOOL valid;

-(void)setUpWithIconImageNamed:(NSString *)iconName placeHolder:(NSString *)placeHolder keyboardType:(UIKeyboardType)keyboardType type:(kTDTextFieldType)aType delegate:(id)aDelegate;
-(void)secure;
-(void)textfieldText:(NSString *)text;
-(void)status:(BOOL)status;
-(void)becomeFirstResponder;
-(void)resignFirst;
-(void)startSpinner;
-(void)stopSpinner;

@end
