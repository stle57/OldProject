//
//  TDHomeHeaderView.m
//  Throwdown
//
//  Created by Andrew C on 3/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDHomeHeaderView.h"
#import "TDProgressIndicator.h"
#import "TDHomeHeaderUploadDelegate.h"

@interface TDHomeHeaderView () <TDHomeHeaderUploadDelegate>

@property (weak, nonatomic) UITableView *table;
@property (strong, nonatomic) NSMutableArray *currentUploads;

@end

@implementation TDHomeHeaderView

- (id)initWithTableView:(UITableView *)tableView {
    self = [super initWithFrame:CGRectMake(0.0, 0.0, 320.0, 5.0)];
    if (self) {
        self.table = tableView;
        self.currentUploads = [[NSMutableArray alloc] init];

        UIColor *lightGrayColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];

        UIView *topPadding = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 5.0)];
        topPadding.backgroundColor = lightGrayColor;
        [self addSubview:topPadding];
    }
    return self;
}

- (void)addUpload:(TDPostUpload *)upload {
    TDProgressIndicator *progress = [[TDProgressIndicator alloc] initWithUpload:upload delegate:self];
    [self.currentUploads addObject:progress];
    [self addSubview:progress];
    [self layout];
}

- (void)layout {
    // TODO: Potentially turn this into - (void)layoutSubviews?
    int count = 0;
    for (UIView *progress in self.currentUploads) {
        progress.frame = CGRectMake(0.0, 5.0 + 55.0 * count, 320.0, 55.0);
        count += 1;
    }

    self.frame = CGRectMake(0.0, 0.0, 320.0, 5.0 + 55.0 * count);
    NSLog(@"total progress bars %i", count);

    [self.table setTableHeaderView:([self.currentUploads count] > 0 ? self : nil)];
}

#pragma mark - TDHomeHeaderUploadDelegate method

- (void)uploadDidFinishFor:(TDProgressIndicator *)upload {
    [upload removeFromSuperview];
    [self.currentUploads removeObject:upload];
    [self layout];
}

@end
