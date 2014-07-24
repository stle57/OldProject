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
        [self addSubview:[nibContents lastObject]];

        // Make bottom line 0.5 pixels
        CGRect bottomLineFrame = self.bottomLine.frame;
        bottomLineFrame.size.height = 0.5;
        bottomLineFrame.origin.x += 0.5;
        self.bottomLine.frame = bottomLineFrame;

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
    
    self.placeholderLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:19.0];
    self.placeholderLabel.text = placeHolder;
    self.placeholderLabel.alpha = 0.8;

    self.textfield.font = [UIFont fontWithName:@"ProximaNova-Regular" size:19.0];
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
    } else {
        // redo frames
        CGRect newFrame = self.placeholderLabel.frame;
        newFrame.origin.x = self.iconImageView.frame.origin.x+4.0;
        newFrame.size.width += (self.placeholderLabel.frame.origin.x+self.iconImageView.frame.origin.x-8.0);
        self.placeholderLabel.frame = newFrame;
        newFrame.origin.x -= 4.0;
        self.textfield.frame = newFrame;
    }

    self.xmarkImageView.hidden = YES;
    self.checkmarkImageView.hidden = YES;
    self.textfield.delegate = self;
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
