//
//  TDToastView.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDToastView.h"
#import "TDAppDelegate.h"
#import "TDNavigationController.h"

#define kToastTimeOnScreen  3.0
#define kToastHeight        50.0

@interface TDToastView ()

@property (nonatomic) UIButton *button;
@property (nonatomic) BOOL removed;

@end

@implementation TDToastView

- (void)dealloc {
    self.delegate = nil;
    self.payload = nil;
}

+ (id)toastView {
    TDToastView *toastView = [[[NSBundle mainBundle] loadNibNamed:@"TDToastView" owner:nil options:nil] lastObject];
    if ([toastView isKindOfClass:[TDToastView class]]) {
        return toastView;
    } else {
        return nil;
    }
}

+ (void)removeOldToasts {
    // Remove old ones
    for (UIView *oldToastView in [NSArray arrayWithArray:[[TDAppDelegate appDelegate].window subviews]]) {
        if (oldToastView.tag == TOAST_TAG) {
            [oldToastView.layer removeAllAnimations];
            [oldToastView removeFromSuperview];
        }
    }
}

- (void)text:(NSString *)text icon:(kToastIconType)iconType payload:(NSDictionary *)payload {
    self.userInteractionEnabled = YES;

    self.payload = payload;

    self.label.font = [UIFont fontWithName:@"ProximaNova-Regular" size:16.5];
    self.label.text = text;
    [TDAppDelegate fixWidthOfThisLabel:self.label];

    UIImage *iconImage = nil;
    switch (iconType) {
        case kToastIconType_None:
            self.iconImageView.hidden = YES;
            break;
        case kToastIconType_Warning:
            iconImage = [UIImage imageNamed:@"td_error_toast_icon"];
            self.backgroundColor = [UIColor colorWithRed:(150/255) green:(50/255) blue:(50/255) alpha:0.8];
            self.label.textColor = [UIColor whiteColor];
            break;
        case kToastIconType_Info:
            iconImage = [UIImage imageNamed:@"td_info_toast_icon"];
            self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
            self.label.textColor =[UIColor darkGrayColor];
            break;

        default:
            break;
    }

    if (iconImage) {
        self.iconImageView.hidden = NO;
        self.iconImageView.image = iconImage;

        if (self.label.frame.size.width > self.frame.size.width) {
            CGRect frame = self.label.frame;
            frame.size.width = self.frame.size.width - self.iconImageView.frame.size.width - 5;
            self.label.frame = frame;
        }

        self.iconImageView.frame = CGRectMake(self.iconImageView.frame.origin.x,
                                              self.iconImageView.frame.origin.y,
                                              iconImage.size.width,
                                              iconImage.size.height);
        self.iconImageView.center = CGPointMake(self.iconImageView.center.x,
                                                self.center.y);

        // Center text and icon
        self.iconImageView.frame = CGRectMake((self.frame.size.width - self.iconImageView.frame.size.width - self.label.frame.size.width) / 2.0,
                                              self.iconImageView.frame.origin.y,
                                              self.iconImageView.frame.size.width,
                                              self.iconImageView.frame.size.height);

        self.label.center = CGPointMake(CGRectGetMaxX(self.iconImageView.frame) + 10.0 + self.label.frame.size.width / 2.0,
                                        self.center.y);
    } else {
        if (self.label.frame.size.width > self.frame.size.width) {
            CGRect frame = self.label.frame;
            frame.size.width = self.frame.size.width;
            self.label.frame = frame;
        }
        self.label.center = self.center;
    }
    iconImage = nil;
}

- (void)showToast {
    self.tag = TOAST_TAG;
    CGRect statusFrame = [UIApplication sharedApplication].statusBarFrame;
    CGFloat toastOffSet = statusFrame.size.height;

    self.frame = CGRectMake(0.0,
                            toastOffSet,
                            [TDAppDelegate appDelegate].window.frame.size.width,
                            0);

    // Have to add a button since tap gestures and touchBegan don't work on an animated view(!)
    self.button = [[UIButton alloc] initWithFrame:CGRectMake(0.0,
                                                                toastOffSet,
                                                                [TDAppDelegate appDelegate].window.frame.size.width,
                                                                kToastHeight)];
    self.button.backgroundColor = [UIColor clearColor];
    [self.button addTarget:self
                    action:@selector(tappedButton:)
          forControlEvents:UIControlEventTouchUpInside];
    [[TDAppDelegate appDelegate].window addSubview:self.button];

    self.label.hidden = YES;
    self.iconImageView.hidden = YES;
    [UIView animateWithDuration: 0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.frame = CGRectMake(0, toastOffSet, self.frame.size.width, kToastHeight);
                     }
                     completion:^(BOOL animDownDone){
                         self.label.hidden = NO;
                         self.iconImageView.hidden = NO;
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kToastTimeOnScreen * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             [self remove];
                         });
                     }];
}

- (void)remove {
    if (!self.removed) {
        self.removed = YES;
        [UIView animateWithDuration: 0.2
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.frame = CGRectMake(0, self.frame.origin.y, self.frame.size.width, 0);
                         }
                         completion:^(BOOL completed){
                             [self.button removeFromSuperview];
                             [self removeFromSuperview];
                             self.delegate = nil;
                             self.payload = nil;
                         }];
    }
}

- (IBAction)tappedButton:(id)sender {
    debug NSLog(@"Toast tapped with payload:%@", self.payload);
    self.button.enabled = NO;
    [self remove];
    if (self.delegate && [self.delegate respondsToSelector:@selector(toastNotificationTappedPayload:)]) {
        [self.delegate performSelector:@selector(toastNotificationTappedPayload:) withObject:self.payload];
        self.delegate = nil;
    }
}

@end
