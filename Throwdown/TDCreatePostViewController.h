//
//  TDCreatePostViewController.h
//  Throwdown
//
//  Created by Andrew C on 3/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "TDUserListView.h"
#import "TDCreatePostHeaderCell.h"
#import "TDLocationViewController.h"

@interface TDCreatePostViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TDCreatePostHeaderCellDelegate, UIScrollViewAccessibilityDelegate, UIScrollViewDelegate, TDLocationViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
- (void)addMedia:(NSString *)filename thumbnail:(NSString *)thumbnailPath isOriginal:(BOOL)original;
@end
