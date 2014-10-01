//
//  TDKeyboardObserver.m
//  Throwdown
//
//  Created by Andrew C on 10/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDKeyboardObserver.h"

static NSString *const kKeyboardKeyPath = @"position";

@implementation TDKeyboardObserver

- (void)dealloc {
    [self stopListening];
}

- (instancetype)initWithDelegate:(id<TDKeyboardObserverDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void)stopListening {
    [self unregisterKeyboardObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)startListening {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChange:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)keyboardDidChange:(NSNotification *)notification {
    if (!self.keyboardView) {
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
            // Because we cant get access to the UIPeripheral throught the SDK we will just use its UIView.
            // UIPeripheral is a subclass of UIView anyway
            // For iOS 8 we have to look a level deeper
            // UIPeripheral should work for 4.0+. In 3.0 you would use "<UIKeyboard"
            // Keyboard will end up as a UIView reference to the UIPeripheral / UIInput we want
            // Iterate though each view inside of the selected Window
            for (UIView *keyboard in window.subviews) {
                if ([[keyboard description] hasPrefix:@"<UIPeripheral"]) {
                    // iOS4 - iOS7
                    [self registerKeyboardObserver:keyboard];
                    return;
                } else if ([[keyboard description] hasPrefix:@"<UIInput"]) {
                    // iOS8
                    for (UIView *view in keyboard.subviews) {
                        if ([view.description hasPrefix:@"<UIInputSetHostView"]) {
                            [self registerKeyboardObserver:view];
                            return;
                        }
                    }
                }
            }
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(keyboardWillHide:)]) {
        [self.delegate keyboardWillHide:notification];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    [self unregisterKeyboardObserver];
    if ([self.delegate respondsToSelector:@selector(keyboardDidHide:)]) {
        [self.delegate keyboardDidHide:notification];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self unregisterKeyboardObserver];
    if ([self.delegate respondsToSelector:@selector(keyboardWillShow:)]) {
        [self.delegate keyboardWillShow:notification];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(keyboardDidShow:)]) {
        [self.delegate keyboardDidShow:notification];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.keyboardView.layer && [keyPath isEqualToString:kKeyboardKeyPath]) {
        if ([self.delegate respondsToSelector:@selector(keyboardFrameChanged:)]) {
            [self.delegate keyboardFrameChanged:self.keyboardView.layer.frame];
        }
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (void)registerKeyboardObserver:(UIView *)view {
    if (self.keyboardView) {
        [self unregisterKeyboardObserver];
    }
    self.keyboardView = view;
    [self.keyboardView.layer addObserver:self forKeyPath:kKeyboardKeyPath options:NSKeyValueObservingOptionInitial context:nil];
}

- (void)unregisterKeyboardObserver {
    if (self.keyboardView) {
        [self.keyboardView.layer removeObserver:self forKeyPath:kKeyboardKeyPath];
        self.keyboardView = nil;
    }
}

@end
