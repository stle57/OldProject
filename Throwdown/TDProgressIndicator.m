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

@interface TDProgressIndicator () <TDUploadProgressDelegate>

@property (strong, nonatomic) UIView *progressBackgroundView;
@property (strong, nonatomic) UIView *progressBarView;
@property (strong, nonatomic) UIButton *retryButton;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) TDPostUpload *upload;
@property (strong, nonatomic) id<TDHomeHeaderUploadDelegate> delegate;

@end

@implementation TDProgressIndicator

- (id)initWithUpload:(TDPostUpload *)upload delegate:(id<TDHomeHeaderUploadDelegate>)delegate {
    self = [super initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
    if (self) {

        self.upload = upload;
        [self.upload setDelegate:self];

        self.delegate = delegate;

        UIColor *grayColor = [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0];

        self.thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(7.0, 5.0, 40.0, 40.0)];
        self.thumbnailView.contentMode = UIViewContentModeScaleToFill;
        self.thumbnailView.backgroundColor = grayColor;
        self.thumbnailView.clipsToBounds = YES;
        self.thumbnailView.image = [UIImage imageWithContentsOfFile:upload.persistedPhotoPath];
        [self addSubview:self.thumbnailView];

        self.progressBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(63.0, 20.0, 200.0, 10.0)];
        self.progressBackgroundView.backgroundColor = grayColor;
        self.progressBackgroundView.layer.cornerRadius = 5;
        self.progressBackgroundView.layer.masksToBounds = YES;
        [self addSubview:self.progressBackgroundView];

        self.progressBarView = [[UIView alloc] initWithFrame:CGRectMake(63.0, 20.0, 10.0, 10.0)];
        self.progressBarView.backgroundColor = [TDConstants brandingRedColor];
        self.progressBarView.layer.cornerRadius = 5;
        self.progressBarView.layer.masksToBounds = YES;
        [self addSubview:self.progressBarView];

        UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 49.0, 320.0, 1.0)];
        bottomBorder.backgroundColor = grayColor;
        [self addSubview:bottomBorder];
    }
    return self;
}

#pragma mark - TDProgressIndicatorDelegate

- (void)uploadDidUpdate:(CGFloat)progress {
    CGRect frame = self.progressBarView.frame;
    frame.size.width = 10.0 + (190.0 * progress);
    self.progressBarView.frame = frame;
}

- (void)uploadComplete {
    [self.delegate uploadDidFinishFor:self];
    self.upload = nil;
    self.delegate = nil;
}

- (void)uploadFailed {
    self.progressBackgroundView.hidden = YES;
    self.progressBarView.hidden = YES;

    if (!self.errorLabel) {
        CGRect labelFrame = CGRectMake(63.0, 0.0, 200.0, 49.0);

        self.errorLabel = [[UILabel alloc] initWithFrame:labelFrame];
        [self.errorLabel setNumberOfLines:0];
        self.errorLabel.text = @"Upload failed";
        CGFloat fontSize = 0.0f;
        labelFrame.size = [self.errorLabel.text sizeWithFont:self.errorLabel.font
                                         minFontSize:self.errorLabel.minimumScaleFactor
                                      actualFontSize:&fontSize
                                            forWidth:labelFrame.size.width
                                       lineBreakMode:self.errorLabel.lineBreakMode];

        [self addSubview:self.errorLabel];

        self.retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.retryButton.frame = CGRectMake(289.0, 12.0, 24.0, 24.0);
        [self.retryButton setImage:[UIImage imageNamed:@"upload_failed_retry"] forState:UIControlStateNormal];
        [self.retryButton setImage:[UIImage imageNamed:@"upload_failed_retry_hit"] forState:UIControlStateHighlighted];
        [self.retryButton addTarget:self action:@selector(retryUpload) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.retryButton];
    } else {
        self.errorLabel.hidden = NO;
        self.retryButton.hidden = NO;
    }
}

# pragma mark - UI callbacks

- (void)retryUpload {
    self.retryButton.hidden = YES;
    self.errorLabel.hidden = YES;

    self.progressBackgroundView.hidden = NO;
    self.progressBarView.hidden = NO;
    CGRect frame = self.progressBarView.frame;
    frame.size.width = 10.0 + (190.0 * [self.upload totalProgress]);
    self.progressBarView.frame = frame;

    [self.upload retryUpload];
}

@end
