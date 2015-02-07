//
//  TDAppCoverBackgroundView.h
//  Throwdown
//
//  Created by Stephanie Le on 12/23/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDAppCoverBackgroundView : UIImageView
- (void)setBlurredImage:(UIImage *)image editingViewOnly:(BOOL)editViewOnly;
- (void)setBackgroundImage:(BOOL)blurEffect editingViewOnly:(BOOL)editingViewOnly;
@end
