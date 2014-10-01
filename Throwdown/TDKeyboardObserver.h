//
//  TDKeyboardObserver.h
//  Throwdown
//
//  Created by Andrew C on 10/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDKeyboardObserverDelegate <NSObject>
@optional
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)keyboardDidHide:(NSNotification *)notification;
- (void)keyboardFrameChanged:(CGRect)keyboardFrame;


@end


@interface TDKeyboardObserver : NSObject

@property (nonatomic) UIView *keyboardView;
@property (nonatomic, assign) id<TDKeyboardObserverDelegate>delegate;

- (instancetype)initWithDelegate:(id<TDKeyboardObserverDelegate>)delegate;
- (void)stopListening;
- (void)startListening;

@end
