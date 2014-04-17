//
//  TDToastView.m
//  Throwdown
//
//  Created by Andrew Bennett on 4/16/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDToastView.h"
#import "TDAppDelegate.h"

#define kToastTimeOnScreen  5.0
#define kToastHeight        50.0

@implementation TDToastView

@synthesize delegate;
@synthesize gotoPosition;

- (void)dealloc
{
    delegate = nil;
    self.gotoPosition = nil;
}

+ (id)toastView
{
    TDToastView *toastView = [[[NSBundle mainBundle] loadNibNamed:@"TDToastView" owner:nil options:nil] lastObject];
    if ([toastView isKindOfClass:[TDToastView class]]) {
        return toastView;
    } else {
        return nil;
    }
}

+(void)removeOldToasts
{
    // Remove old ones
    for (UIView *oldToastView in [NSArray arrayWithArray:[[TDAppDelegate appDelegate].window subviews]]) {
        if (oldToastView.tag == TOAST_TAG) {
            [oldToastView.layer removeAllAnimations];
            [oldToastView removeFromSuperview];
        }
    }
}

-(void)text:(NSString *)text icon:(kToastIconType)iconType gotoPosition:(NSNumber *)positionInApp
{
    self.userInteractionEnabled = YES;

    self.gotoPosition = positionInApp;

    self.label.font = [UIFont fontWithName:@"ProximaNova-Regular" size:16.5];
    self.label.text = text;
    [TDAppDelegate fixWidthOfThisLabel:self.label];

    UIImage *iconImage = nil;
    switch (iconType) {
        case kToastIconType_None:
        {
            self.iconImageView.hidden = YES;
        }
        break;
        case kToastIconType_Warning:
        {
            self.iconImageView.hidden = NO;
            iconImage = [UIImage imageNamed:@"td_error_toast_icon"];
            self.iconImageView.image = iconImage;
        }
        break;

        default:
        break;
    }

    if (iconImage) {
        self.iconImageView.frame = CGRectMake(self.iconImageView.frame.origin.x,
                                              self.iconImageView.frame.origin.y,
                                              iconImage.size.width,
                                              iconImage.size.height);
        self.iconImageView.center = CGPointMake(self.iconImageView.center.x,
                                                self.center.y);
    }
    iconImage = nil;


    // Center text and icon
    if (self.iconImageView.hidden) {
        self.label.center = self.center;
    } else {
        self.iconImageView.frame = CGRectMake((self.frame.size.width-self.iconImageView.frame.size.width-self.label.frame.size.width)/2.0,
                                      self.iconImageView.frame.origin.y,
                                      self.iconImageView.frame.size.width,
                                      self.iconImageView.frame.size.height);

        self.label.center = CGPointMake(CGRectGetMaxX(self.iconImageView.frame)+10.0+self.label.frame.size.width/2.0,
                                                self.center.y);
    }
}

-(void)showToast
{
    self.tag = TOAST_TAG;
    CGRect statusFrame = [UIApplication sharedApplication].statusBarFrame;
    CGFloat toastOffSet = statusFrame.size.height;

    self.frame = CGRectMake(0.0,
                            toastOffSet,
                            [TDAppDelegate appDelegate].window.frame.size.width,
                            kToastHeight);

    CGPoint origCenter = self.center;
    self.center = CGPointMake(self.center.x,
                              self.center.y-CGRectGetMaxY(self.frame));

    CGPoint centerUp = self.center;

    // Have to add a button since tap gestures and touchBegan don't work on an animated view(!)
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0,
                                                                toastOffSet,
                                                                [TDAppDelegate appDelegate].window.frame.size.width,
                                                                kToastHeight)];
    button.backgroundColor = [UIColor clearColor];
    [button addTarget:self
               action:@selector(tappedButton:)
     forControlEvents:UIControlEventTouchUpInside];
    [[TDAppDelegate appDelegate].window addSubview:button];

    [UIView animateWithDuration: 0.3
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{

                         self.center = origCenter;

                     }
                     completion:^(BOOL animDownDone){

                         if (animDownDone)
                         {

                             [UIView animateWithDuration: 0.2
                                                   delay: kToastTimeOnScreen
                                                 options: UIViewAnimationOptionCurveEaseInOut
                                              animations:^{

                                                  self.center = centerUp;

                                              }
                                              completion:^(BOOL animUpDone){

                                                  if (animUpDone)
                                                  {
                                                      [button removeFromSuperview];
                                                      [self removeFromSuperview];
                                                  }
                                              }];
                         }
                     }];
}

-(IBAction)tappedButton:(id)sender{

    NSLog(@"tapped with goto:%@", self.gotoPosition);
}

@end
