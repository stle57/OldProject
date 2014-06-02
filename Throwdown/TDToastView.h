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
@end

enum {
    kToastIconType_None,
    kToastIconType_Warning,
    kToastIconType_Info
};
typedef NSUInteger kToastIconType;

@interface TDToastView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id <TDToastViewDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, retain) NSDictionary *payload;

+ (id)toastView;
+ (void)removeOldToasts;
- (void)text:(NSString *)text icon:(kToastIconType)iconType payload:(NSDictionary *)payload;
- (void)showToast;
- (IBAction)tappedButton:(id)sender;

@end
