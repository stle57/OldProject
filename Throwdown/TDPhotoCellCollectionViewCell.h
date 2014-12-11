//
//  TDPhotoCellCollectionViewCell.h
//  Throwdown
//
//  Created by Stephanie Le on 11/26/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface TDPhotoCellCollectionViewCell : UICollectionViewCell
@property(nonatomic, strong) ALAsset *asset;

- (void)removeOverlay;
@end
