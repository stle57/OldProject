//
//  TDAppCoverBackgroundView.h
//  Throwdown
//
//  Created by Stephanie Le on 12/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDAppCoverBackgroundView : UIImageView

- (void)setBackgroundImage:(BOOL)blurEffect;
- (void)applyBlurOnImage;
- (void)unBlurImage;
- (void)applyBlurOnImage1:(CGRect)frame;
- (void)blurImage:(CGFloat)xPosition;
@end
