//
//  TDPhotoCellCollectionViewCell.m
//  Throwdown
//
//  Created by Stephanie Le on 11/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDPhotoCellCollectionViewCell.h"
#import "TDConstants.h"

@interface TDPhotoCellCollectionViewCell ()
@property (nonatomic) UIView *hitStateOverlay;
@end

@implementation TDPhotoCellCollectionViewCell

- (void)dealloc {
}

- (void)awakeFromNib {
    self.layer.borderColor = [[UIColor greenColor] CGColor];
    self.layer.borderWidth = 2.;
}
- (void) setAsset:(ALAsset *)asset
{
    // 2
    _asset = asset;
}

- (void) addOverlay:(CGFloat)length {
    self.hitStateOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, length, length)];
    self.hitStateOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [self addSubview:self.hitStateOverlay];
}

- (void) removeOverlay {
    [self.hitStateOverlay removeFromSuperview];
}
@end

