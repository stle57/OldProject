//
//  TDTextField.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDTextField.h"
#import "TDAppDelegate.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberUtil.h"
#import "TDConstants.h"

@implementation TDTextField

@synthesize delegate;
@synthesize valid;

- (void)dealloc
{
    delegate = nil;

    [self.textfield removeTarget:self
                          action:@selector(textFieldDidChange:)
                forControlEvents:UIControlEventEditingChanged];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"TDTextField" owner:self options:nil];
        self.backgroundColor = [UIColor clearColor];
        UIView *view = (UIView *)[nibContents lastObject];
        CGRect frame = view.frame;
        frame.size.width = self.frame.size.width;
        view.frame = frame;
        [self addSubview:view];

        // Make bottom line 0.5 pixels
        CGRect bottomLineFrame = self.bottomLine.frame;
        bottomLineFrame.size.height = 0.5;
        bottomLineFrame.origin.y += 0.5;
        bottomLineFrame.size.width = self.frame.size.width;
        self.bottomLine.frame = bottomLineFrame;
        self.bottomLine.backgroundColor = [UIColor blackColor];
        
        [self.textfield addTarget:self
                           action:@selector(textFieldDidChange:)
                 forControlEvents:UIControlEventEditingChanged];
        
    }
    return self;
}

// Pass nil for iconName to give entire width to placeholder and textfield
-(void)setUpWithIconImageNamed:(NSString *)iconName placeHolder:(NSString *)placeHolder keyboardType:(UIKeyboardType)keyboardType type:(kTDTextFieldType)aType delegate:(id)aDelegate
{
    self.delegate = aDelegate;
    type = aType;
    self.spinner.hidden = YES;
    
    self.placeholderLabel.font = [TDConstants fontRegularSized:16];
    self.placeholderLabel.text = placeHolder;
    self.placeholderLabel.textColor = [TDConstants commentTimeTextColor];
    //self.placeholderLabel.alpha = 0.8;

    self.textfield.font = [TDConstants fontRegularSized:16];
    self.textfield.textColor = [TDConstants headerTextColor];
    
    self.textfield.keyboardType = keyboardType;
    if (keyboardType == UIKeyboardTypeEmailAddress || keyboardType == UIKeyboardTypeTwitter) {
        self.textfield.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textfield.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    if (type == kTDTextFieldType_Phone) {
        NBPhoneNumberUtil *numberUtil = [NBPhoneNumberUtil sharedInstance];
        NSString *numberPrefix = [[NSString alloc] initWithFormat:@"+%u", (unsigned int)[numberUtil getCountryCodeForRegion:[numberUtil countryCodeByCarrier]]];
        self.textfield.text = numberPrefix;
        self.placeholderLabel.hidden = YES;
    }

    if (iconName) {
        UIImage *iconImage = [UIImage imageNamed:iconName];
        self.iconImageView.image = iconImage;
        iconImage = nil;
    }

    self.xmarkImageView.hidden = YES;
    self.checkmarkImageView.hidden = YES;
    self.textfield.delegate = self;
    
    CGRect frame = self.iconImageView.frame;
    frame.origin.x = 0;
    frame.origin.y = self.frame.size.height - 8 - self.iconImageView.frame.size.height;
    self.iconImageView.frame = frame;
    
    CGRect placeHolderFrame = self.placeholderLabel.frame;
    placeHolderFrame.origin.x = self.iconImageView.frame.size.width + 10;
    placeHolderFrame.origin.y = self.frame.size.height/2 - self.iconImageView.frame.size.height/2 +2;
    self.placeholderLabel.frame = placeHolderFrame;
    self.textfield.frame = placeHolderFrame;
    
    CGRect checkFrame = self.checkmarkImageView.frame;
    checkFrame.origin.y = self.frame.size.height - 8 - self.checkmarkImageView.frame.size.height;
    self.checkmarkImageView.frame = checkFrame;
    
    self.xmarkImageView.frame = checkFrame;
    
    self.spinner.frame = checkFrame;
}

-(void)secure
{
    self.textfield.secureTextEntry = YES;
}

-(void)textfieldText:(NSString *)text
{
    self.textfield.text = text;

    if ([text length] > 0) {
        self.placeholderLabel.alpha = 0.0;
        self.placeholderLabel.hidden = YES;
    }
}

-(void)status:(BOOL)status
{
    [self stopSpinner];
    if (status) {
        self.xmarkImageView.hidden = YES;
        self.checkmarkImageView.hidden = NO;
    } else {
        self.xmarkImageView.hidden = NO;
        self.checkmarkImageView.hidden = YES;
    }

    self.valid = status;
}

-(void)becomeFirstResponder
{
    [self.textfield becomeFirstResponder];
}

-(void)resignFirst
{
    if ([self.textfield isFirstResponder]) {
        [self.textfield resignFirstResponder];
    }
}

-(void)startSpinner
{
    self.xmarkImageView.hidden = YES;
    self.checkmarkImageView.hidden = YES;
    [self.spinner startAnimating];
}

-(void)stopSpinner
{
    [self.spinner stopAnimating];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (delegate) {
        if ([delegate respondsToSelector:@selector(textFieldDidBeginEditing:type:)]) {
            [delegate textFieldDidBeginEditing:textField
                                          type:type];
        }
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    self.valid = NO;    // Invalidated by change of text
    if ([textField.text length] == 0) {
        [self status:NO];
        self.xmarkImageView.hidden = YES;
        self.checkmarkImageView.hidden = YES;
        self.placeholderLabel.alpha = 0.0;
        self.placeholderLabel.hidden = NO;
        [UIView animateWithDuration: 0.1
                              delay: 0.0
                            options: UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.placeholderLabel.alpha = .8;
                         }
                         completion:nil];
    } else {
        self.placeholderLabel.hidden = YES;
    }

    if (delegate) {
        if ([delegate respondsToSelector:@selector(textFieldDidChange:type:)]) {
            [delegate textFieldDidChange:textField
                                    type:type];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (delegate) {
        if ([delegate respondsToSelector:@selector(textFieldShouldReturn:type:)]) {
            return [delegate textFieldShouldReturn:textField
                                              type:type];
        }
    }

    return NO;
}

@end
