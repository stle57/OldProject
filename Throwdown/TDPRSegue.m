//
//  TDPRSegue.m
//  Throwdown
//
//  Created by Andrew C on 7/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPRSegue.h"
#import "TDConstants.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>

static CGFloat const kShowPRTime = 1.5;

@implementation TDPRSegue

- (void)perform {
    debug NSLog(@"PERFORM-PRSegue");

    // sourceViewController is released in popDestination
    UIWindow *window = [self.sourceViewController view].window;

    [super perform];
    [super popDestination];

    UIView *background = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    background.alpha = 0.;
    background.backgroundColor = [UIColor whiteColor];
    [window addSubview:background];
    [window insertSubview:background aboveSubview:self.screenShotDestination];
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         background.alpha = 1.;
                     }
                     completion:^(BOOL finished){
                         [self.screenShotSource removeFromSuperview];
                         [self showImageOn:background];
                         [self showTextOn:background];
                     }];
}

- (void)showImageOn:(UIView *)background {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(62, 71, 195, 190)];

    NSMutableArray *images = [@[] mutableCopy];
    for (int i = 1; i < 37; i++) {
        NSString *imageName = [NSString stringWithFormat:@"trophy-in-%d", i];
        [images addObject:[UIImage imageNamed:imageName]];
    }
    imageView.image = [images lastObject];
    imageView.animationImages = images;
    imageView.animationDuration = (36. / 24.); // 24 fps
    imageView.animationRepeatCount = 1;
    [background addSubview:imageView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(((36. / 24.) + kShowPRTime) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [images removeAllObjects];
        for (int i = 1; i < 9; i++) {
            NSString *imageName = [NSString stringWithFormat:@"trophy-out-%d", i];
            [images addObject:[UIImage imageNamed:imageName]];
        }
        imageView.image = [images lastObject];
        imageView.animationImages = images;
        imageView.animationDuration = 8. / 24.; // 24fps
        imageView.animationRepeatCount = 1;
        [imageView startAnimating];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((8./24.) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            imageView.image = nil;
            [images removeAllObjects];
            [UIView animateWithDuration:0.25
                                  delay:0.208
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 background.alpha = 0.;
                             } completion:^(BOOL finished) {
                                 [imageView removeFromSuperview];
                                 [background removeFromSuperview];
                                 [self.screenShotDestination removeFromSuperview];
                                 [self.destinationViewController view].hidden = NO;
                             }];
        });
    });
    [imageView startAnimating];
}

- (void)showTextOn:(UIView *)background {
    NSArray *texts = @[
                       @"Way to go!\nThat's a great PR!",
                       @"Personal record accomplished!",
                       @"Way to PR! \xF0\x9F\x91\x8A", // fist-bumb emoji
                       @"Boom!\nWay to PR!",
                       @"PR High Five! \xE2\x9C\x8B", // high five emoji
                       @"Way to PR!\nTreat yourself to something special!"
                       ];
    NSUInteger randomIndex = arc4random() % [texts count];

    TTTAttributedLabel *text = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 280, 320, 120)];
    text.font = [TDConstants fontLightSized:24];
    text.textColor = [TDConstants headerTextColor];
    text.textAlignment = NSTextAlignmentCenter;
    text.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    text.minimumLineHeight = 36;
    text.numberOfLines = 3;
    text.text = texts[randomIndex];
    text.alpha = 0.;
    [background addSubview:text];

    [UIView animateWithDuration:0.292
                          delay:0.625
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         text.alpha = 1.;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.208
                                               delay:.3 + kShowPRTime
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              text.alpha = 0.;
                                          } completion:^(BOOL finished) {
                                              [text removeFromSuperview];
                                          }];
                     }];

}

@end
