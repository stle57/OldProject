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
@end

enum {
    kToastIconType_None,
    kToastIconType_Warning
};
typedef NSUInteger kToastIconType;

@interface TDToastView : UIView <UIGestureRecognizerDelegate>
{
    id <TDToastViewDelegate> __unsafe_unretained delegate;

    NSNumber *gotoPosition;
}

@property (nonatomic, assign) id <TDToastViewDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UIView *coloredBackground;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, retain) NSNumber *gotoPosition;

+ (id)toastView;
+(void)removeOldToasts;
-(void)text:(NSString *)text icon:(kToastIconType)iconType gotoPosition:(NSNumber *)positionInApp;
-(void)showToast;
-(IBAction)tappedButton:(id)sender;

@end
