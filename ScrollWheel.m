//
//  ScrollWheel.m
//  ScrollViewPlay
//
//  Created by Andrew C on 11/13/14.
//  Copyright (c) 2014 CA Systems. All rights reserved.
//

#import "ScrollWheel.h"

static float const kFPS = 1/60.0;

@interface ScrollWheel () <UIGestureRecognizerDelegate>

@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int tickInterval;
@property (nonatomic) int tickWidth;
@property (nonatomic) int tickHeight1;
@property (nonatomic) int tickHeight2;
@property (nonatomic) int tickY1;
@property (nonatomic) int tickY2;
@property (nonatomic) int tickCount;
@property (nonatomic) float increment;
@property (nonatomic) float step;
@property (nonatomic) float theta;
@property (nonatomic) float phi;
@property (nonatomic) float deltaPhi;
@property (nonatomic) float radius;
@property (nonatomic) float offset;
@property (nonatomic) float currentStep;
@property (nonatomic) float currentPosition;
@property (nonatomic) float currentOffset;
@property (nonatomic) float lastStep;
@property (nonatomic) BOOL animating;
@property (nonatomic) NSArray *ticks;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UILongPressGestureRecognizer *longPressGesture;

@property (nonatomic) NSTimer *animationTimer;
@property (nonatomic) float animationToPoint;
@property (nonatomic) float animationFromPoint;
@property (nonatomic) NSTimeInterval animationDuration;
@property (nonatomic) NSTimeInterval animationOffset;

@end

@implementation ScrollWheel

- (void)dealloc {
    NSLog(@"dealloc scroll");
    [self removeFromSuperview];
}

- (void)removeFromSuperview {
    if (self.panGesture) {
        [self removeGestureRecognizer:self.panGesture];
        self.panGesture.delegate = nil;
        self.panGesture = nil;
    }
    if (self.longPressGesture) {
        [self removeGestureRecognizer:self.longPressGesture];
        self.longPressGesture.delegate = nil;
        self.longPressGesture = nil;
    }

    for (int i = 0; i < [self.ticks count]; i++) {
        UIView *tick = (UIView *)self.ticks[i];
        [tick removeFromSuperview];
    }
    self.delegate = nil;
    [super removeFromSuperview];
}

- (instancetype)initWithRecommendedSizeAtY:(CGFloat)yPosition {
    int height = 0;
    switch ((int)[UIScreen mainScreen].bounds.size.width) {
        case 320:
            height = 44;
            break;
        case 375:
            height = 50;
            break;
        case 414:
            height = 58;
            break;
    }
    self = [self initWithFrame:CGRectMake(0, yPosition, [UIScreen mainScreen].bounds.size.width, height)];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        self.userInteractionEnabled = YES;

        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        self.panGesture.delegate = self;
        [self addGestureRecognizer:self.panGesture];
        self.longPressGesture = [[UILongPressGestureRecognizer alloc] init]; // target handled manually
        self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        self.longPressGesture.minimumPressDuration = 0.01;
        self.longPressGesture.delegate = self;
        [self addGestureRecognizer:self.longPressGesture];

        self.width = frame.size.width;
        self.height = frame.size.height;
        switch (self.width) {
            case 320: // iPhone 4S/5/5S
                self.tickWidth = 1.5;
                self.tickCount = 32;
                self.theta = 2.727599;
                self.radius = 158.381;
                break;
            case 375: // iPhone 6
                self.tickWidth = 2;
                self.tickCount = 32;
                self.theta = 2.752576;
                self.radius = 186.008;
                break;
            case 414: // iPhone 6+
                self.tickWidth = 2;
                self.tickCount = 36;
                self.theta = 2.813112;
                self.radius = 204.755;
                break;

            default:
                break;
        }
        self.tickInterval = 4;
        self.tickHeight1 = self.height - 10;
        self.tickHeight2 = self.height - 20;
        self.tickY1 = 5;
        self.tickY2 = 10;
        self.increment = 0.006;
        self.step = 0;
        self.phi = (M_PI - self.theta) / 2;
        self.deltaPhi = self.theta / self.tickCount;
        self.offset = self.width / 2;
        self.animating = NO;
        self.modifier = 1.0;

        NSMutableArray *tmpTicks = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.tickCount; i++) {
            UIView *tick = [[UIView alloc] init];
            tick.frame = CGRectMake(0, (i % self.tickInterval == 0 ? self.tickY1 : self.tickY2), self.tickWidth, (i % self.tickInterval == 0 ? self.tickHeight1 : self.tickHeight2));
            tick.backgroundColor = [UIColor whiteColor];
            [self addSubview:tick];
            [tmpTicks addObject:tick];
        }
        self.ticks = tmpTicks;
        [self updateTicks:0];
    }
    return self;
}

#pragma mark - Update / animate the UI

- (void)setPosition:(float)position {
    [self stopAnimation];
    self.currentOffset = 0;
    self.lastStep = (position / self.modifier);
    self.currentStep = self.lastStep;
}

- (void)updateTicks:(NSInteger)step {
    self.currentStep = self.lastStep + (float)step;
    float position = (self.currentStep - self.currentOffset) * self.modifier;

    if (position < self.minPosition) {
        self.currentOffset = self.currentStep;
    } else if (position > self.maxPosition) {
        self.currentOffset = self.currentStep - self.maxPosition / self.modifier;
    }

    if (self.delegate) {
        if (position < 0) {
            position = 0;
        } else if (position > self.maxPosition) {
            position = self.maxPosition;
        }
        [self.delegate scrollWheelDidChange:position];
    }

    for (int i = 0; i < [self.ticks count]; i++) {
        UIView *tick = (UIView *)self.ticks[i];

        float c = (i * self.deltaPhi - self.currentStep * self.increment);

        if (c == 0.0) {
            c = self.theta;
        } else {
            c = fmod(c, self.theta);
            if (c < 0) {
                c += self.theta;
            }
        }
        float angle = self.phi + c;
        float x = self.radius * cos(angle);

        float alpha = (1 - 2 * (abs(x) / (float)self.width));
        tick.alpha = alpha;
        tick.frame = CGRectMake(x + self.offset, tick.frame.origin.y, self.tickWidth, tick.frame.size.height);
    }
}

- (void)animationStep:(NSTimer *)timer {
    self.animating = YES;
    self.animationOffset = MIN(self.animationOffset + kFPS, self.animationDuration);
    float time = self.animationOffset / self.animationDuration;
    float position = easeOutCubic(time, self.animationFromPoint, self.animationToPoint - self.animationFromPoint, self.animationDuration);

    [self updateTicks:position];
    if (self.animationOffset >= self.animationDuration) {
        [self stopAnimation];
    }
}

- (void)stopAnimation {
    if (self.delegate && [self.delegate respondsToSelector:@selector(scrollWheelEndedInteraction)]) {
        [self.delegate scrollWheelEndedInteraction];
    }

    [self.animationTimer invalidate];
    self.animationTimer = nil;
    self.animating = NO;
}

#pragma mark - Gesture handling

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self stopAnimation];
        self.lastStep = self.currentStep;
        if (self.delegate && [self.delegate respondsToSelector:@selector(scrollWheelStartedInteraction)]) {
            [self.delegate scrollWheelStartedInteraction];
        }
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translate = [gesture translationInView:self];
        self.animating = NO;
        [self updateTicks:translate.x];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity  = [gesture velocityInView:self];
        CGPoint translate = [gesture translationInView:self];

        self.animationDuration = 1.4;
        self.animationOffset = 0.0;
        self.animationFromPoint = translate.x;
        self.animationToPoint = self.animationFromPoint + velocity.x * self.animationDuration * 0.2;

        // Just don't animate if the difference is too small
        if (ABS(self.animationFromPoint - self.animationToPoint) > 30) {
            [self stopAnimation];
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:kFPS target:self selector:@selector(animationStep:) userInfo:nil repeats:YES];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(scrollWheelEndedInteraction)]) {
            [self.delegate scrollWheelEndedInteraction];
        }
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gesture {
    if (self.animating) {
        [self stopAnimation];
    }
}

#pragma mark - UIGestureRecognizerDelegate

// This allow both pan and tap gestures to always fire. We control stopping the animation manually.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

#pragma mark - Animation curves

// t = current time
// b = start value
// c = change in value
// d = duration

// exponential easing out
float easeOutExpo(float t, float b, float c, float d) {
    return c * ( -powf( 2, -10 * t/d ) + 1 ) + b;
}

// sinusoidal easing out
float easeOutSine(float t, float b, float c, float d) {
    return c * sinf(t/d * (M_PI/2)) + b;
}

// quadratic easing out
float easeOutQuad(float t, float b, float c, float d) {
    t /= d;
    return -c * t*(t-2) + b;
};

// cubic easing out
float easeOutCubic(float t, float b, float c, float d) {
    t /= d;
    t--;
    return c*(t*t*t + 1) + b;
}

@end
