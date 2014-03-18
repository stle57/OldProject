//
//  TDTypingView.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDTypingView.h"
#import "TDAppDelegate.h"
#import "TDConstants.h"

@implementation TDTypingView

@synthesize delegate;
@synthesize textView;
@synthesize counterLabel;
@synthesize postButton;
@synthesize topLine;
@synthesize bottomLine;
@synthesize keybdUpFrame;
@synthesize hpTextView;
@synthesize isUp;

#define MAX_LENGTH      4000
#define TYPING_HEIGHT   44.0

- (void)dealloc
{
    delegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    self.textView.delegate = nil;
    self.textView = nil;
    self.counterLabel = nil;
    self.postButton = nil;
    self.topLine = nil;
    self.bottomLine = nil;
    self.hpTextView = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        origFrame = frame;
        lastNumberOfLines = 1;

        self.backgroundColor = [UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:1.0];

        self.topLine = [[UIView alloc] initWithFrame:CGRectMake(0.0,
                                                                0.0,
                                                                self.frame.size.width,
                                                                0.5)];
        self.topLine.backgroundColor = [UIColor colorWithRed:(178.0/255.0) green:(178.0/255.0) blue:(178.0/255.0) alpha:1.0];
        [self addSubview:self.topLine];

        self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0,
                                                                   self.frame.size.height-0.5,
                                                                   self.frame.size.width,
                                                                   0.5)];
        self.bottomLine.backgroundColor = [UIColor colorWithRed:(178.0/255.0) green:(178.0/255.0) blue:(178.0/255.0) alpha:1.0];
        [self addSubview:self.bottomLine];

        self.hpTextView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(12.0,
                                                                              4.0,
                                                                              self.frame.size.width-92.0,
                                                                              TYPING_HEIGHT-9.0)];
        self.hpTextView.isScrollable = NO;
        self.hpTextView.backgroundColor = [UIColor whiteColor];
        self.hpTextView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        self.hpTextView.internalTextView.keyboardType = UIKeyboardAppearanceDefault;
        self.hpTextView.internalTextView.keyboardAppearance = UIKeyboardAppearanceDark;

        self.hpTextView.minNumberOfLines = 1;
        self.hpTextView.maxNumberOfLines = 6;
        // you can also set the maximum height in points with maxHeight
        // textView.maxHeight = 200.0f;
        self.hpTextView.returnKeyType = UIReturnKeyDefault;
        self.hpTextView.font = [UIFont fontWithName:@"ProximaNova-Regular" size:18.0];;
        self.hpTextView.delegate = self;
        self.hpTextView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        self.hpTextView.placeholder = @"";
        self.hpTextView.text = @"Write a comment...";
        self.hpTextView.layer.cornerRadius = 4.0;
        self.hpTextView.layer.borderColor = [UIColor colorWithRed:(178.0/255.0) green:(178.0/255.0) blue:(178.0/255.0) alpha:1.0].CGColor;
        self.hpTextView.layer.borderWidth = 0.5;
        self.hpTextView.textColor = [TDConstants commentTimeTextColor];
        [self addSubview:self.hpTextView];
        self.hpTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        self.postButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.postButton setTitle:@"Post" forState:UIControlStateNormal];
        [self.postButton setTitleColor:[TDConstants headerTextColor] forState:UIControlStateNormal];
        [self.postButton setTitleColor:[UIColor colorWithRed:(136.0/255.0) green:(136.0/255.0) blue:(136.0/255.0) alpha:1.0] forState:UIControlStateDisabled];
        [self.postButton setTitleColor:[UIColor colorWithRed:(136.0/255.0) green:(136.0/255.0) blue:(136.0/255.0) alpha:1.0] forState:UIControlStateHighlighted];
        self.postButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Semibold" size:18.0];
        self.postButton.backgroundColor = [UIColor colorWithRed:(237.0/255.0) green:(237.0/255.0) blue:(237.0/255.0) alpha:1.0];
        self.postButton.enabled = NO;
        self.postButton.layer.cornerRadius = 6.0;
        self.postButton.frame = CGRectMake(self.hpTextView.frame.origin.x+self.hpTextView.frame.size.width+6.0,
                                           0.0,
                                           self.frame.size.width-(self.hpTextView.frame.origin.x+self.hpTextView.frame.size.width+12.0),
                                           self.hpTextView.frame.size.height);
        self.postButton.center = CGPointMake(self.postButton.center.x,
                                             self.hpTextView.center.y+1.0);
        [self.postButton addTarget:self
                            action:@selector(postButtonPressed:)
                  forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.postButton];

        self.counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.postButton.frame.origin.x,
                                                                       0.0,
                                                                       self.postButton.frame.size.width,
                                                                       self.postButton.frame.size.height)];
        self.counterLabel.textColor = [UIColor lightGrayColor];
        self.counterLabel.font = [UIFont fontWithName:@"Verdana-Bold" size:10.0];
        self.counterLabel.textAlignment = NSTextAlignmentRight;
        self.counterLabel.text = @"100";
        self.counterLabel.alpha = 1.0;
        self.counterLabel.hidden = YES;
        self.counterLabel.backgroundColor = [UIColor clearColor];
        self.counterLabel.numberOfLines = 1;
        [self addSubview:self.counterLabel];
        [TDAppDelegate fixHeightOfThisLabel:self.counterLabel];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillAppear:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillDisappear:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

+(CGFloat)typingHeight
{
    return TYPING_HEIGHT;
}

#pragma mark TextView Delegates
- (void)textViewDidChange:(UITextView *)aTextView
{
	self.counterLabel.text = [NSString stringWithFormat:@"%ld", (long)(MAX_LENGTH-[self.textView.text length])];

    // Check for multiple lines
    CGFloat textViewHeight = self.textView.contentSize.height-self.textView.font.lineHeight;
    NSInteger numLines = self.textView.contentSize.height/self.textView.font.lineHeight;
    NSLog(@"Number of lines:%ld %f", (long)numLines, ((numLines-1)*self.textView.font.lineHeight));

    [self.layer removeAllAnimations];
    [self.textView.layer removeAllAnimations];
    [self.postButton.layer removeAllAnimations];
    [self.topLine.layer removeAllAnimations];
    [self.bottomLine.layer removeAllAnimations];

    CGRect newFrame = CGRectMake(self.frame.origin.x,
                                 keybdUpFrame.origin.y-(textViewHeight-origTextViewHeight),
                                 self.frame.size.width,
                                 keybdUpFrame.size.height+(textViewHeight-origTextViewHeight));
    if (numLines == 1) {
        newFrame = keybdUpFrame;
        self.textView.contentInset = UIEdgeInsetsZero;
    }

    [UIView animateWithDuration: 0.1
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{

                         self.frame = newFrame;


                     }
                     completion:^(BOOL animDone){

                         if (animDone)
                         {
                             [UIView animateWithDuration: 0.1
                                                   delay: 0.0
                                                 options: UIViewAnimationOptionCurveLinear
                                              animations:^{

                                                  self.textView.frame = CGRectMake(12.0,
                                                                                   4.0,
                                                                                   self.frame.size.width-92.0,
                                                                                   self.frame.size.height-8.0);
                                                  self.postButton.frame = CGRectMake(self.textView.frame.origin.x+self.textView.frame.size.width+8.0,
                                                                                     0.0,
                                                                                     self.frame.size.width-(self.textView.frame.origin.x+self.textView.frame.size.width+8.0),
                                                                                     self.textView.frame.size.height);
                                                  self.topLine.frame = CGRectMake(0.0,
                                                                                  0.0,
                                                                                  self.frame.size.width,
                                                                                  0.5);
                                                  self.bottomLine.frame = CGRectMake(0.0,
                                                                                     self.frame.size.height-0.5,
                                                                                     self.frame.size.width,
                                                                                     0.5);

                                              }
                                              completion:^(BOOL animDone){

                                                  if (animDone)
                                                  {
                                                      self.postButton.center = CGPointMake(self.postButton.center.x,
                                                                                           self.textView.center.y);
                                                  }
                                              }];
                         }
                     }];

    lastNumberOfLines = numLines;

    if ([self.textView.text length] > 0)
    {
        self.postButton.enabled = YES;
    }
    else
    {
        self.postButton.enabled = NO;
    }

	if ([self.textView.text length] > (MAX_LENGTH-30))
	{
		self.counterLabel.textColor = [UIColor redColor];
	}
	else
	{
		self.counterLabel.textColor = [UIColor lightGrayColor];
	}
}

- (BOOL)textView:(UITextView *)aTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	return range.location >= MAX_LENGTH ? NO : YES;
}

#pragma mark - Growing Text View
- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (growingTextView.text.length + (text.length - range.length) <= MAX_LENGTH)
    {
        return YES;
    }
    return NO;
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    self.counterLabel.text = [NSString stringWithFormat:@"%ld", (long)(MAX_LENGTH-[self.hpTextView.text length])];

    NSInteger numLines = growingTextView.internalTextView.contentSize.height/self.hpTextView.font.lineHeight;
    NSLog(@"TDTypingView-growingTextViewDidChange-Number of lines:%ld %f", (long)numLines, ((numLines-1)*self.textView.font.lineHeight));

    lastNumberOfLines = numLines;

    if ([self.hpTextView.text length] > 0)
    {
        self.postButton.enabled = YES;
    }
    else
    {
        self.postButton.enabled = NO;
    }

	if ([self.hpTextView.text length] > (MAX_LENGTH-30))
	{
        self.counterLabel.hidden = NO;
		self.counterLabel.textColor = [UIColor redColor];
	}
	else
	{
        self.counterLabel.hidden = YES;
		self.counterLabel.textColor = [UIColor lightGrayColor];
	}

    [UIView animateWithDuration: 0.1
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{

                         self.postButton.center = CGPointMake(self.postButton.center.x,
                                                              self.hpTextView.center.y);
                         self.counterLabel.center = CGPointMake(self.counterLabel.center.x,
                                                                4.0+self.counterLabel.frame.size.height/2.0);
                         self.bottomLine.frame = CGRectMake(0.0,
                                                            self.frame.size.height-0.5,
                                                            self.frame.size.width,
                                                            0.5);

                     }
                     completion:^(BOOL animDone){

                         if (animDone)
                         {
                         }
                     }];
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);

	CGRect r = self.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	self.frame = r;
}

#pragma mark keyboard
-(BOOL)showingKeyboard
{
    return [self.hpTextView isFirstResponder];
}

-(void)removeKeyboard
{
    NSLog(@"TDTyping-hideKeyboard");

    self.hpTextView.text = @"";

    if ([self.hpTextView isFirstResponder]) {
        [self.hpTextView resignFirstResponder];
    }
}

-(void)keyboardWillAppear:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];

    NSLog(@"KEYBD INFO:%@", info);

    CGFloat keybdHeight = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;

    debug NSLog(@"Keyboard Appearing:%@ HEIGHT:%f", info, keybdHeight);

    if (delegate ) {
        if ([delegate respondsToSelector:@selector(keyboardAppeared:curve:)]) {
            [delegate keyboardAppeared:keybdHeight curve:[[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue]];
        }
    }
}

-(void)keyboardWillDisappear:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];

    NSValue* aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
    CGFloat keybdHeight = keyboardSize.height;

    debug NSLog(@"Keyboard Disappearing:%@ HEIGHT:%f", info, keybdHeight);

    if (delegate ) {
        if ([delegate respondsToSelector:@selector(keyboardDisappeared:)]) {
            [delegate keyboardDisappeared:keybdHeight];
        }
    }
}

#pragma mark buttons

-(void)postButtonPressed:(id)selector
{
    NSLog(@"post button:%@", self.hpTextView.text);

    self.postButton.enabled = NO;

    if (delegate ) {
        if ([delegate respondsToSelector:@selector(typingViewMessage:)]) {
            [delegate typingViewMessage:self.hpTextView.text];
        }
    }
}

@end