//
//  ScrollWheel.h
//  ScrollViewPlay
//
//  Created by Andrew C on 11/13/14.
//  Copyright (c) 2014 CA Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScrollWheelDelegate <NSObject>
@required
- (void)scrollWheelDidChange:(float)position;
@optional
- (void)scrollWheelStartedInteraction;
- (void)scrollWheelEndedInteraction;
@end


@interface ScrollWheel : UIView

- (instancetype)initWithRecommendedSizeAtY:(CGFloat)yPosition;
- (void)setPosition:(float)position;

@property (nonatomic, weak) id<ScrollWheelDelegate> delegate;
@property (nonatomic) float minPosition;
@property (nonatomic) float maxPosition;
@property (nonatomic) float modifier;

@end
