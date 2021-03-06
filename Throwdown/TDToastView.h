//
//  TDToastView.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDToastViewDelegate <NSObject>
@optional
- (void)toastNotificationTappedPayload:(NSDictionary *)payload;
- (void)toastNotificationCloseButton;
- (void)toastNotificationTappedRateUs;
- (void)toastNotificationSendInviteRetry:(NSDictionary *)payload;
- (void)toastNotificationStopInvites;
@end


typedef enum {
    kToastType_None,
    kToastType_Warning,
    kToastType_Info,
    kToastType_RateUs,
    kToastType_InviteSent,
    kToastType_InviteWarning
} kToastType;

@interface TDToastView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <TDToastViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, retain) NSDictionary *payload;
@property (nonatomic) kToastType toastType;

+ (id)toastView;
+ (void)removeOldToasts;
- (void)text:(NSString *)text type:(kToastType)type payload:(NSDictionary *)payload;
- (void)showToast;
- (IBAction)tappedButton:(id)sender;
- (IBAction)closedButtonPressed:(UIButton *)sender;

@end
