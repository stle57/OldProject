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
#import "TDConstants.h"

#define kToastTimeOnScreen  3.0
#define kToastHeight        50.0

@interface TDToastView ()

@property (nonatomic) UIButton *button;
@property (nonatomic) BOOL removed;

@end

@implementation TDToastView

@synthesize toastType;

- (void)dealloc {
    self.delegate = nil;
    self.payload = nil;
}

- (void)viewDidLoad {
    debug NSLog(@"inside viewDidLoad");
    CGRect frame = self.frame;
    frame.size.width = SCREEN_WIDTH;
    self.frame = frame;
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

- (void)text:(NSString *)text type:(kToastType)type payload:(NSDictionary *)payload {
    self.userInteractionEnabled = YES;
    self.payload = payload;
    self.toastType = type;
    self.label.font =  [TDConstants fontRegularSized:16];
    self.label.text = text;
    [TDAppDelegate fixWidthOfThisLabel:self.label];

    UIImage *iconImage = nil;
    switch (type) {
        case kToastType_None:
            self.iconImageView.hidden = YES;
            self.closeButton.hidden = YES;
            break;
        case kToastType_Warning:
            iconImage = [UIImage imageNamed:@"td_error_toast_icon"];
            self.backgroundColor = [UIColor colorWithRed:(158./255) green:(11./255) blue:(15./255) alpha:0.85];
            self.label.textColor = [UIColor whiteColor];
            self.closeButton.hidden = YES;
            break;
        case kToastType_Info:
            iconImage = [UIImage imageNamed:@"td_info_toast_icon"];
            self.backgroundColor = [UIColor colorWithRed:(76.0/255.0) green:(76.0/255.0) blue:(76.0/255.0) alpha:0.85];  // 4c4c4c with alpha
            self.label.textColor = [UIColor whiteColor];
            self.closeButton.hidden = YES;
            break;
        case kToastType_RateUs:
            iconImage = [UIImage imageNamed:@"td_rateus_icon"];
            self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.95f];
            self.label.textColor = [TDConstants headerTextColor];
            self.label.font = [TDConstants fontSemiBoldSized:15];
            self.closeButton.hidden = FALSE;
            self.closeButton.enabled = YES;
            [self.closeButton setImage:[UIImage imageNamed:@"nav-close-black.png"] forState:UIControlStateNormal];
            [self.closeButton setImage:[UIImage imageNamed:@"nav-close-black-hit.png"] forState:UIControlStateHighlighted];
            [self.closeButton setImage:[UIImage imageNamed:@"nav-close-black-hit.png"] forState:UIControlStateSelected];
            break;
        case kToastType_InviteSent:
            iconImage = [UIImage imageNamed:@"td_notif_toast_icon"];
            self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.95f];
            self.label.textColor = [TDConstants headerTextColor];
            self.label.font = [TDConstants fontRegularSized:15];
            self.closeButton.hidden = YES;
            break;
        case kToastType_InviteWarning:
            iconImage = [UIImage imageNamed:@"td_error_toast_icon"];
            self.backgroundColor = [UIColor colorWithRed:(158./255) green:(11./255) blue:(15./255) alpha:0.85];
            self.label.textColor = [UIColor whiteColor];
            self.label.text = @"Invites failed.  Tap here to retry";
            [self.closeButton setImage:[UIImage imageNamed:@"nav-close.png"] forState:UIControlStateNormal];
            [self.closeButton setImage:[UIImage imageNamed:@"nav-close-hit.png"] forState:UIControlStateHighlighted];
            [self.closeButton setImage:[UIImage imageNamed:@"nav-close-hit.png"] forState:UIControlStateSelected];
            self.closeButton.hidden = FALSE;
            self.closeButton.enabled = YES;
            break;
        default:
            break;
    }

    if (iconImage) {
        self.iconImageView.hidden = NO;
        self.iconImageView.image = iconImage;

        self.iconImageView.frame = CGRectMake(self.iconImageView.frame.origin.x,
                                              self.iconImageView.frame.origin.y,
                                              iconImage.size.width,
                                              iconImage.size.height);
       
        self.iconImageView.center = CGPointMake(self.iconImageView.center.x,
                                                self.center.y);
        
        self.closeButton.center = CGPointMake(self.closeButton.center.x,
                                              self.center.y);
        
        // Center text and icon
        if(self.toastType == kToastType_RateUs || self.toastType == kToastType_InviteWarning) {
            self.iconImageView.frame = CGRectMake(TD_MARGIN,
                                                  self.iconImageView.frame.origin.y,
                                                  self.iconImageView.frame.size.width,
                                                  self.iconImageView.frame.size.height);
            self.label.frame = CGRectMake(TD_MARGIN + self.iconImageView.frame.origin.x + self.iconImageView.frame.size.width,
                                          self.label.frame.origin.y,
                                          self.label.frame.size.width,
                                          self.label.frame.size.height);
            self.label.textAlignment = NSTextAlignmentCenter;
            [self.label sizeToFit];
            
            CGFloat labelXPosition = SCREEN_WIDTH/2 - self.label.frame.size.width/2;
            CGRect labelFrame = self.label.frame;
            labelFrame.origin.x = labelXPosition;
            labelFrame.origin.y = self.frame.size.height/2 - labelFrame.size.height/2;
            self.label.frame = labelFrame;

            // Reset the icon position so it's next to label
            CGRect iconFrame = self.iconImageView.frame;
            iconFrame.origin.x = labelXPosition - self.iconImageView.frame.size.width - 5;
            self.iconImageView.frame = iconFrame;
            
            self.closeButton.frame = CGRectMake(SCREEN_WIDTH - self.closeButton.frame.size.width -10,
                                                self.closeButton.frame.origin.y,
                                                self.closeButton.frame.size.width,
                                                self.closeButton.frame.size.height);
        } else {
            self.iconImageView.frame = CGRectMake((SCREEN_WIDTH - self.iconImageView.frame.size.width - self.label.frame.size.width) / 2.0,
                                                  self.iconImageView.frame.origin.y,
                                                  self.iconImageView.frame.size.width,
                                                  self.iconImageView.frame.size.height);
            
            self.label.frame = CGRectMake(self.iconImageView.frame.origin.x + self.iconImageView.frame.size.width +5,
                                         self.label.frame.origin.y,
                                         self.label.frame.size.width,
                                         self.label.frame.size.height);
        }
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
    int buttonWidth =[TDAppDelegate appDelegate].window.frame.size.width;
    
    CGRect statusFrame = [UIApplication sharedApplication].statusBarFrame;
    CGFloat toastOffSet = statusFrame.size.height;

    self.frame = CGRectMake(0.0,
                            toastOffSet,
                            [TDAppDelegate appDelegate].window.frame.size.width,
                            0);

    // Have to add a button since tap gestures and touchBegan don't work on an animated view(!)
    if(self.toastType == kToastType_RateUs || self.toastType == kToastType_InviteWarning)
        buttonWidth = buttonWidth-40;
    
    self.button = [[UIButton alloc] initWithFrame:CGRectMake(0.0,
                                                                toastOffSet,
                                                                buttonWidth,
                                                                kToastHeight)];
    self.button.backgroundColor = [UIColor clearColor];
    [self.button addTarget:self
                    action:@selector(tappedButton:)
          forControlEvents:UIControlEventTouchUpInside];
    
    [[TDAppDelegate appDelegate].window addSubview:self.button];

    self.label.alpha = 0.;
    self.iconImageView.alpha = 0.;
    if (self.toastType == kToastType_RateUs || self.toastType == kToastType_InviteWarning ) {
        self.frame = CGRectMake(0, toastOffSet, self.frame.size.width, kToastHeight);
        self.label.alpha = 1.;
        self.iconImageView.alpha = 1.;
    } else {
        [UIView animateWithDuration: 0.2
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.frame = CGRectMake(0, toastOffSet, self.frame.size.width, kToastHeight);
                             self.label.alpha = 1.;
                             self.iconImageView.alpha = 1.;
                         }
                         completion:^(BOOL animDownDone){
                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kToastTimeOnScreen * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                 [self remove];
                             });
                         }];
    }
}

- (void)remove {
    if (!self.removed) {
        self.removed = YES;
        self.label.alpha = 1.;
        self.iconImageView.alpha = 1.;
        [UIView animateWithDuration: 0.2
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.frame = CGRectMake(0, self.frame.origin.y, self.frame.size.width, 0);
                             self.label.alpha = 0.;
                             self.iconImageView.alpha = 0.;
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
    self.button.enabled = NO;
    [self remove];

    if (self.delegate && [self.delegate respondsToSelector:@selector(toastNotificationSendInviteRetry:)] && self.toastType == kToastType_InviteWarning) {
        debug NSLog(@"yes...RETRY!");
        [self.delegate performSelector:@selector(toastNotificationSendInviteRetry:) withObject:self.payload];
        self.delegate = nil;
    }
    else if (self.delegate && [self.delegate respondsToSelector:@selector(toastNotificationTappedPayload:)]) {
        if(self.toastType != kToastType_RateUs && self.toastType != kToastType_InviteWarning) {
            [self.delegate performSelector:@selector(toastNotificationTappedPayload:) withObject:self.payload];
            self.delegate = nil;
        }
    } else if (self.delegate && [self.delegate respondsToSelector:@selector(toastNotificationTappedRateUs)] && self.toastType == kToastType_RateUs) {
        [self.delegate performSelector:@selector(toastNotificationTappedRateUs)];
        self.delegate = nil;
    }
}

- (IBAction)closedButtonPressed:(UIButton *)sender {
    self.button.enabled = NO;
    [self remove];
    if (self.delegate && [self.delegate respondsToSelector:@selector(toastNotificationStopInvites)] &&  self.toastType == kToastType_InviteWarning) {
        [self.delegate performSelector:@selector(toastNotificationStopInvites)];
        self.delegate = nil;
    } else if(self.delegate && [self.delegate respondsToSelector:@selector(toastNotificationCloseButton)]) {
        [self.delegate performSelector:@selector(toastNotificationCloseButton)];
        self.delegate = nil;
    }

}
@end
