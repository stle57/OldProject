//
//  TDProgressIndicator.m
//  Throwdown
//
//  Created by Andrew C on 3/4/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDProgressIndicator.h"
#import "TDConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "TDUploadProgressDelegate.h"
#import "TTTAttributedLabel.h"
#import "UIImage+Resizing.h"

@interface TDProgressIndicator () <TDUploadProgressDelegate>

@property (nonatomic) UIView *progressBackgroundView;
@property (nonatomic) UIView *progressBarView;
@property (nonatomic) UIActivityIndicatorView *activity;
@property (nonatomic) UIButton *retryButton;
@property (nonatomic) TTTAttributedLabel *titleLabel;
@property (nonatomic, retain) id<TDUploadProgressUIDelegate> item;
@property (nonatomic, retain) id<TDHomeHeaderUploadDelegate> delegate;

@end

@implementation TDProgressIndicator

- (id)initWithItem:(id<TDUploadProgressUIDelegate>)item delegate:(id<TDHomeHeaderUploadDelegate>)delegate {
    self = [super initWithFrame:CGRectMake(0.0, 0.0, SCREEN_WIDTH, 50.0)];
    if (self) {
        self.delegate = delegate;
        self.item = item;
        [self.item setUploadProgressDelegate:self];

        if ([self.item respondsToSelector:@selector(previewImage)]) {
            self.thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5.0, 40.0, 40.0)];
            self.thumbnailView.contentMode = UIViewContentModeScaleToFill;
            self.thumbnailView.backgroundColor = [TDConstants darkBackgroundColor];
            self.thumbnailView.clipsToBounds = YES;
            [self addSubview:self.thumbnailView];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = [self.item previewImage];
                CGFloat width = self.thumbnailView.frame.size.width * [UIScreen mainScreen].nativeScale;
                image = [image scaleToSize:CGSizeMake(width, width)];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.thumbnailView.image = image;
                });
            });
        }

        CGFloat offset = self.thumbnailView ? 40 : 0;

        if ([self.item displayProgressBar]) {
            self.progressBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(offset + 20, 20., SCREEN_WIDTH - 120, 10.)];
            self.progressBackgroundView.backgroundColor = [TDConstants darkBackgroundColor];
            self.progressBackgroundView.layer.cornerRadius = 5;
            self.progressBackgroundView.layer.masksToBounds = YES;
            [self addSubview:self.progressBackgroundView];

            self.progressBarView = [[UIView alloc] initWithFrame:CGRectMake(offset + 20, 20., 10., 10.)];
            self.progressBarView.backgroundColor = [TDConstants brandingRedColor];
            self.progressBarView.layer.cornerRadius = 5;
            self.progressBarView.layer.masksToBounds = YES;
            [self addSubview:self.progressBarView];
        } else {
            self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.activity.frame = CGRectMake(SCREEN_WIDTH - 34, 12., 24., 24.);
            self.activity.tintColor = [TDConstants darkTextColor];
            [self addSubview:self.activity];
            [self.activity startAnimating];
        }

        if ([self.item respondsToSelector:@selector(progressTitle)]) {
            [self setupLabel];
            self.titleLabel.text = [self.item progressTitle];
        }

        UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0., 49. + (1 / [[UIScreen mainScreen] scale]), SCREEN_WIDTH, 1 / [[UIScreen mainScreen] scale])];
        bottomBorder.backgroundColor = [TDConstants darkBorderColor];
        [self addSubview:bottomBorder];
        debug NSLog(@"upload indicator started");
    }
    return self;
}

- (void)dealloc {
    self.item = nil;
    self.delegate = nil;
}

#pragma mark - TDUploadProgressDelegate

- (void)uploadDidUpdate:(CGFloat)progress {
    CGRect frame = self.progressBarView.frame;
    frame.size.width = 10.0 + ((SCREEN_WIDTH - 130) * progress);
    self.progressBarView.frame = frame;
}

- (void)uploadComplete {
    [self.delegate uploadDidFinishFor:self];
    self.item = nil;
    self.delegate = nil;
    if (self.activity) {
        [self.activity stopAnimating];
    }
}

- (void)setupLabel {
    if (!self.titleLabel) {
        CGRect labelFrame = CGRectMake(self.thumbnailView ? 60. : 10., 0., SCREEN_WIDTH - (self.thumbnailView ? 120 : 40), 49.);
        self.titleLabel = [[TTTAttributedLabel alloc] initWithFrame:labelFrame];
        self.titleLabel.font = [TDConstants fontRegularSized:15];
        self.titleLabel.textColor = [TDConstants darkTextColor];
        self.titleLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
        [self addSubview:self.titleLabel];
    }
}

- (void)uploadFailed {
    debug NSLog(@"upload failed");

    if (self.progressBarView) {
        self.progressBackgroundView.hidden = YES;
        self.progressBarView.hidden = YES;
    }

    if (self.activity) {
        [self.activity stopAnimating];
        self.activity.hidden = YES;
    }

    [self setupLabel];
    self.titleLabel.textColor = [TDConstants brandingRedColor];
    self.titleLabel.text = @"Upload failed";
    self.titleLabel.hidden = NO;

    if (!self.retryButton) {
        self.retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.retryButton.frame = CGRectMake(SCREEN_WIDTH - 34, 12.0, 24.0, 24.0);
        [self.retryButton setImage:[UIImage imageNamed:@"upload_failed_retry"] forState:UIControlStateNormal];
        [self.retryButton setImage:[UIImage imageNamed:@"upload_failed_retry_hit"] forState:UIControlStateHighlighted];
        [self.retryButton addTarget:self action:@selector(retryUpload) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.retryButton];
    }
    self.retryButton.hidden = NO;
}

# pragma mark - UI callbacks

- (void)retryUpload {

    if (self.activity) {
        self.activity.hidden = NO;
        [self.activity startAnimating];
    }

    if ([self.item respondsToSelector:@selector(progressTitle)]) {
        self.titleLabel.textColor = [TDConstants darkTextColor];
        self.titleLabel.text = [self.item progressTitle];
    } else {
        self.titleLabel.hidden = YES;
    }
    self.retryButton.hidden = YES;

    if (self.progressBarView) {
        self.progressBackgroundView.hidden = NO;
        self.progressBarView.hidden = NO;
        CGRect frame = self.progressBarView.frame;
        frame.size.width = 10.0 + ((SCREEN_WIDTH - 130) * [self.item totalProgress]);
        self.progressBarView.frame = frame;
    }

    [self.item uploadRetry];
}

@end
