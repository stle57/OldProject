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

@interface TDProgressIndicator ()

@property (weak, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIImageView *thumbnailView;
@property (strong, nonatomic) UIView *progressBackgroundView;
@property (strong, nonatomic) UIView *progressBarView;
@property (strong, nonatomic) UIButton *cancelButton;

@end

@implementation TDProgressIndicator

- (id)initWithTableView:(UITableView *)tableView thumbnailPath:(NSString *)thumbnailPath {
    self = [super initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
    if (self) {
        self.tableView = tableView;

//        UIColor *lightGrayColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
        UIColor *grayColor = [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0];

        self.thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(7.0, 5.0, 40.0, 40.0)];
        self.thumbnailView.contentMode = UIViewContentModeScaleToFill;
        self.thumbnailView.backgroundColor = grayColor;
        self.thumbnailView.clipsToBounds = YES;
        self.thumbnailView.image = [UIImage imageWithContentsOfFile:thumbnailPath];
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

//        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        self.cancelButton.frame = CGRectMake(289.0, 12.0, 24.0, 24.0);
//        [self.cancelButton setImage:[UIImage imageNamed:@"upload_xbutton"] forState:UIControlStateNormal];
//        [self.cancelButton setImage:[UIImage imageNamed:@"upload_xbutton_hit"] forState:UIControlStateHighlighted];
//        [self.cancelButton addTarget:self action:@selector(canceledUpload) forControlEvents:UIControlEventTouchUpInside];
//        [self addSubview:self.cancelButton];

        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0.0, 49.0, 320.0, 0.5)];
        line.backgroundColor = grayColor;
        [self addSubview:line];

        [self.tableView setTableHeaderView:self];
    }
    return self;
}

#pragma mark - TDProgressIndicatorDelegate

- (void)uploadDidUpdate:(CGFloat)progress {
    self.progressBarView.frame = CGRectMake(63.0, 20.0, 10.0 + (190.0 * progress), 10.0);
    if (progress == 1.0) {
        [self.tableView setTableHeaderView:nil];
    }
}

@end
