//
//  TDHomeHeaderView.m
//  Throwdown
//
//  Created by Andrew C on 3/8/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDHomeHeaderView.h"
#import "TDConstants.h"
#import "TDProgressIndicator.h"
#import "TDHomeHeaderUploadDelegate.h"

@interface TDHomeHeaderView () <TDHomeHeaderUploadDelegate>

@property (weak, nonatomic) UITableView *table;
@property (strong, nonatomic) NSMutableArray *currentUploads;
@property (strong, nonatomic) UIView *bottomPadding;

@end

@implementation TDHomeHeaderView

- (id)initWithTableView:(UITableView *)tableView {
    self = [super initWithFrame:CGRectMake(0.0, 0.0, 320.0, 5.0)];
    if (self) {
        self.table = tableView;
        self.currentUploads = [[NSMutableArray alloc] init];

        self.backgroundColor = [UIColor whiteColor];

        UIView *topPadding = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 5.0)];
        topPadding.backgroundColor = [TDConstants backgroundColor];
        [self addSubview:topPadding];

        UIView *topBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 5.0, 320.0, 1 / [[UIScreen mainScreen] scale])];
        topBorder.backgroundColor = [TDConstants borderColor];
        [self addSubview:topBorder];

        self.bottomPadding = [[UIView alloc] initWithFrame:CGRectMake(0.0, 50.0, 320.0, 5.0)];
        self.bottomPadding.backgroundColor = [TDConstants backgroundColor];
        [self addSubview:self.bottomPadding];

    }
    return self;
}

- (void)addUpload:(id<TDUploadProgressUIDelegate>)upload {
    TDProgressIndicator *progress = [[TDProgressIndicator alloc] initWithItem:upload delegate:self];

    [self.currentUploads addObject:progress];
    [self addSubview:progress];
    [self layout];
}

- (void)layout {
    // TODO: Potentially turn this into - (void)layoutSubviews?
    int count = 0;
    for (UIView *progress in self.currentUploads) {
        progress.frame = CGRectMake(0.0, 6.0 + 50.0 * count, 320.0, 50.0);
        count += 1;
    }

    self.bottomPadding.frame = CGRectMake(0.0, 6.0 + 50.0 * count, 320.0, 5);
    self.frame = CGRectMake(0.0, 0.0, 320.0, 11.0 + 50.0 * count);
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
