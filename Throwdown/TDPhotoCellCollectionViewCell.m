//
//  TDPhotoCellCollectionViewCell.m
//  Throwdown
//
//  Created by Stephanie Le on 11/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPhotoCellCollectionViewCell.h"
#import "TDConstants.h"

static CGFloat const kPaddingEachSide = 2.5;
static CGFloat const kCellsPerRow = 3.0;
static int const kVideoImageMargin = 7;
@interface TDPhotoCellCollectionViewCell ()
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIImageView *videoImageView;
@end

@implementation TDPhotoCellCollectionViewCell

- (void)dealloc {
    [self.imageView removeFromSuperview];
    self.imageView = nil;
    self.videoImageView = nil;
    self.asset = nil;
}

- (void)awakeFromNib {
    self.backgroundColor = [TDConstants lightBackgroundColor];
    CGFloat imageWidth = SCREEN_WIDTH / kCellsPerRow - kPaddingEachSide * 2;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kPaddingEachSide, kPaddingEachSide, imageWidth, imageWidth)];
    self.imageView.backgroundColor = [TDConstants darkBackgroundColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.clipsToBounds = YES;
    
    [self addSubview:self.imageView];
}

-(void)prepareForReuse {
    [self.imageView setImage:nil];
    [self.videoImageView setImage:nil];
}

- (NSDate *)date {
    return [self.asset valueForProperty:ALAssetPropertyDate];
}

- (void)setImage:(UIImage *)image {
    [self.imageView setImage:image];
}

- (void)setVideoImage {
    UIImage *videoImage = [UIImage imageNamed:@"icon_video_marker_alt"];
    self.videoImageView = [[UIImageView alloc] initWithImage:videoImage];
    self.videoImageView.frame = CGRectMake(kVideoImageMargin, self.imageView.frame.size.height - kVideoImageMargin - videoImage.size.height, videoImage.size.width, videoImage.size.height);
    [self.imageView addSubview:self.videoImageView];
}
@end

