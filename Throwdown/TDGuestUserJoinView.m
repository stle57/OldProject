//
//  TDGuestUserJoinView.m
//  Throwdown
//
//  Created by Stephanie Le on 1/2/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDGuestUserJoinView.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"

@interface TDGuestUserJoinView()

@property (nonatomic) NSString *labelString;
@property (nonatomic) UILabel *label;
@property (nonatomic) UIButton *joinButton;
@property (nonatomic) UIButton *closeButton;
@end

static int const width = 290;

@implementation TDGuestUserJoinView

+ (id)guestUserJoinView:(kLabelType)labelType username:(NSString *)username{
    TDGuestUserJoinView *view = [[TDGuestUserJoinView alloc] init];
    if ([view isKindOfClass:[TDGuestUserJoinView class]]) {
        [view setup:labelType username:username];
        return view;
    } else {
        return nil;
    }
    return view;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setup:(kLabelType)labelType username:(NSString*)username{
    self.backgroundColor = [UIColor whiteColor];
    
    NSString *prefixString = [[NSString alloc] init];
    switch(labelType) {
        case kLike_LabelType:
            prefixString = @"To like this post";
            break;
        case kPost_LabelType:
            prefixString = @"To add a post";
            break;
        case kFollow_LabelType:
            prefixString = @"To follow people";
            break;
        case kComment_LabelType:
            prefixString = @"To comment";
            break;
        case kUserProfile_LabelType:
            prefixString = [NSString stringWithFormat:@"%@%@%@", @"To see ", username, @"'s profile"];
            break;
        default:
            break;
    }
    
    if (prefixString.length) {
        self.labelString = [NSString stringWithFormat:@"%@%@", prefixString, @", please join us by creating an account.\n\nWe'd love to have you!"];
        debug NSLog(@"labelString=%@", self.labelString);
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 240, 100)];
        NSAttributedString *attStr = [TDViewControllerHelper makeParagraphedTextWithString:self.labelString font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:19 lineHeightMultipler:19/16];
        self.label.attributedText = attStr;
        [self.label setNumberOfLines:0];
        [self.label sizeToFit];
        CGRect labelFrame = self.label.frame;
        labelFrame.origin.x = width/2 - self.label.frame.size.width/2;
        labelFrame.origin.y = 35;
        self.label.frame = labelFrame;
        debug NSLog(@"self.label.frame = %@", NSStringFromCGRect(self.label.frame));

        [self addSubview:self.label];
        
    }
    
    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(width - 6 - [UIImage imageNamed:@"btn_x_small"].size.width, 6, [UIImage imageNamed:@"btn_x_small"].size.width, [UIImage imageNamed:@"btn_x_small"].size.height)];
    [self.closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.closeButton setImage:[UIImage imageNamed:@"btn_x_small"] forState:UIControlStateNormal];
    [self.closeButton setImage:[UIImage imageNamed:@"btn_x_small"] forState:UIControlStateHighlighted];
    [self.closeButton setImage:[UIImage imageNamed:@"btn_x_small"] forState:UIControlStateSelected];
    
    //- Adjust the size of the button to have a larger tap area
    self.closeButton.frame = CGRectMake(self.closeButton.frame.origin.x -10,
                                       self.closeButton.frame.origin.y -10,
                                       self.closeButton.frame.size.width + 20,
                                       self.closeButton.frame.size.height + 20);

    [self addSubview:self.closeButton];
    
    self.joinButton = [[UIButton alloc] initWithFrame:CGRectMake(width/2 - [UIImage imageNamed:@"btn_join_throwdown"].size.width/2, self.label.frame.origin.y + self.label.frame.size.height + 25, [UIImage imageNamed:@"btn_join_throwdown"].size.width, [UIImage imageNamed:@"btn_join_throwdown"].size.height)];
    [self.joinButton addTarget:self action:@selector(joinButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.joinButton setImage:[UIImage imageNamed:@"btn_join_throwdown"] forState:UIControlStateNormal];
    [self.joinButton setImage:[UIImage imageNamed:@"btn_join_throwdown_hit"] forState:UIControlStateHighlighted];
    [self.joinButton setImage:[UIImage imageNamed:@"btn_join_throwdown_hit"] forState:UIControlStateSelected];
    [self addSubview:self.joinButton];

    CGFloat frameHeight =  35 + self.label.frame.size.height + 25 + self.joinButton.frame.size.height + 20;
    self.frame = CGRectMake(SCREEN_WIDTH/2 - width/2, 120, width, frameHeight);
    
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    self.layer.shadowColor = [[UIColor whiteColor] CGColor];
    self.layer.shadowOpacity = .5;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animateHide) name:TDRemoveGuestJoinView object:nil];
}

- (void)joinButtonPressed {
    debug NSLog(@"join button pressed");

    [[NSNotificationCenter defaultCenter] postNotificationName:TDGuestViewControllerSignUp
                                                        object:self
                                                      userInfo:nil];
    [self animateHide];

}

- (void)closeButtonPressed {
    debug NSLog(@"close button pressed");
    [self animateHide];
}

- (void)showInView {
    if ([self isKindOfClass:[UIView class]])
    {
        [self animateShow];
    }
}

- (void)animateShow
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                      animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
    CATransform3D scale2 = CATransform3DMakeScale(1.2, 1.2, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
    CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:
                            [NSValue valueWithCATransform3D:scale1],
                            [NSValue valueWithCATransform3D:scale2],
                            [NSValue valueWithCATransform3D:scale3],
                            [NSValue valueWithCATransform3D:scale4],
                            nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.5],
                           [NSNumber numberWithFloat:0.9],
                           [NSNumber numberWithFloat:1.0],
                           nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = 0.2;
    
    [AlertView.layer addAnimation:animation forKey:@"show"];
}

- (void)animateHide
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TDRemoveGuestViewControllerOverlay
                                                        object:self
                                                      userInfo:nil];
    
    [self removeFromSuperview];
}
@end
