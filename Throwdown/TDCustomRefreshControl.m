//
//  TDCustomRefreshControl.m
//  Throwdown
//
//  Created by Andrew C on 7/19/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDCustomRefreshControl.h"
#import "TDConstants.h"

@interface TDCustomRefreshControl ()

@property (nonatomic) BOOL isRefreshing;
@property (nonatomic) BOOL minAnimationReached;
@property (nonatomic) NSMutableArray *animationImages;
@property (nonatomic) UIImageView *refreshView;
@property (nonatomic) UIEdgeInsets originalInset;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UILabel *releaseText;
@property (nonatomic) CGFloat originalOffset;

@end

@implementation TDCustomRefreshControl

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0., -100., SCREEN_WIDTH, 100.);
        self.isRefreshing = NO;

        self.animationImages = [[NSMutableArray alloc] init];
        // first add 0008-0029
        for (int i = 8; i < 30; i++) {
            NSString *imageName = [NSString stringWithFormat:@"ptr-00%02d", i];
            [self.animationImages addObject:[UIImage imageNamed:imageName]];
        }
        // then add 0100-0029
        for (int i = 0; i < 30; i++) {
            NSString *imageName = [NSString stringWithFormat:@"ptr-01%02d", i];
            [self.animationImages addObject:[UIImage imageNamed:imageName]];
        }
        // last add 0000-0007
        for (int i = 0; i < 8; i++) {
            NSString *imageName = [NSString stringWithFormat:@"ptr-00%02d", i];
            [self.animationImages addObject:[UIImage imageNamed:imageName]];
        }
        self.refreshView = [[UIImageView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH / 2 - 35), 10, 70, 70)];
        self.refreshView.image = [UIImage imageNamed:@"ptr-0000"];
        self.refreshView.animationImages = self.animationImages;
        self.refreshView.animationDuration = 2;
        self.refreshView.hidden = YES;
        [self addSubview:self.refreshView];

        self.releaseText = [[UILabel alloc] initWithFrame:CGRectMake(0, 82, SCREEN_WIDTH, 15)];
        self.releaseText.textAlignment = NSTextAlignmentCenter;
        self.releaseText.textColor = [TDConstants darkTextColor];
        self.releaseText.font = [TDConstants fontSemiBoldSized:12];
        self.releaseText.hidden = YES;
        self.releaseText.text = @"Release to refresh";
        [self addSubview:self.releaseText];
    }
    return self;
}

- (void)dealloc {
    self.scrollView = nil;
    self.originalInset = UIEdgeInsetsZero;
    self.refreshView = nil;
    self.releaseText = nil;
}

- (void)containingScrollViewDidEndDragging:(UIScrollView *)containingScrollView {
    CGFloat minOffsetToTriggerRefresh = 80 + containingScrollView.contentInset.top;
    if (!self.isRefreshing && !containingScrollView.isDragging && containingScrollView.contentOffset.y <= -minOffsetToTriggerRefresh) {
        [self.refreshView startAnimating];
        self.scrollView = containingScrollView;
        self.isRefreshing = YES;
        self.releaseText.hidden = YES;
        self.minAnimationReached = NO;
        self.originalInset = containingScrollView.contentInset;
        self.refreshView.hidden = NO;
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            containingScrollView.contentInset = UIEdgeInsetsMake(self.frame.size.height + containingScrollView.contentInset.top, self.originalInset.left, self.originalInset.bottom, self.originalInset.right);
        } completion:^(BOOL finished) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
            [NSTimer scheduledTimerWithTimeInterval:.75 target:self selector:@selector(endRefreshing) userInfo:nil repeats:NO];
        }];
    } else if (containingScrollView.contentOffset.y < 0) {
        if (!self.isRefreshing && containingScrollView.contentOffset.y <= -minOffsetToTriggerRefresh) {
            self.releaseText.hidden = NO;
        } else {
            self.releaseText.hidden = YES;
        }
        int pic = (abs(containingScrollView.contentOffset.y) - containingScrollView.contentInset.top - 20) / 10;
        if (!self.isRefreshing) {
            self.refreshView.hidden = pic < 0;
        }
        if (pic > 7) {
            pic = 7;
        }
        NSString *imageNamed = [NSString stringWithFormat:@"ptr-%04d", pic];
        self.refreshView.image = [UIImage imageNamed:imageNamed];
    }
}

- (void)endRefreshing {
    // We only want to end the animation after both the 1.5 second timer and the actual refreshing callback is done.
    // This way the first time we call this method we just set the animation reached second time we stop the animation.
    if (self.minAnimationReached && self.isRefreshing) {
        [UIView animateWithDuration:0.2 delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.scrollView.contentInset = self.originalInset;
        } completion:^(BOOL finished) {
            self.isRefreshing = NO;
            [self.refreshView stopAnimating];
            self.refreshView.image = [UIImage imageNamed:@"ptr-0000"];
            self.scrollView = nil;
            self.refreshView.hidden = YES;
        }];
    } else {
        self.minAnimationReached = YES;
    }
}

@end
