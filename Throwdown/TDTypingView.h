//
//  TDTypingView.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"

@protocol TDTypingViewViewDelegate <NSObject>
@optional
-(void)keyboardAppeared:(CGFloat)height notification:(NSNotification *)notification;
-(void)keyboardDisappeared:(CGFloat)height notification:(NSNotification *)notification;
-(void)typingViewMessage:(NSString *)message;
-(void)adjustFrostedView;
@end

@interface TDTypingView : UIView <UITextViewDelegate, HPGrowingTextViewDelegate>
{
    id <TDTypingViewViewDelegate> __unsafe_unretained delegate;

    UITextView *textView;
    UILabel *counterLabel;
    UIButton *postButton;
    UIView *topLine;
    UIView *bottomLine;

    CGRect origFrame;
    CGRect keybdUpFrame;
    NSInteger lastNumberOfLines;
    CGFloat origTextViewHeight;
    HPGrowingTextView *hpTextView;

    BOOL isUp;
    NSString *rememberText;
}

@property (nonatomic,assign) id <TDTypingViewViewDelegate> __unsafe_unretained delegate;
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UILabel *counterLabel;
@property (nonatomic, retain) UIButton *postButton;
@property (nonatomic, retain) UIView *topLine;
@property (nonatomic, retain) UIView *bottomLine;
@property (nonatomic, assign) CGRect keybdUpFrame;
@property (nonatomic, retain) HPGrowingTextView *hpTextView;
@property (nonatomic, assign) BOOL isUp;
@property (nonatomic, retain) NSString *rememberText;

+(CGFloat)typingHeight;
-(void)removeKeyboard;
-(BOOL)showingKeyboard;
-(void)postButtonPressed:(id)selector;
-(void)reset;
@end
