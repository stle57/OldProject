//
//  TDCreatePostHeader.h
//  Throwdown
//
//  Created by Stephanie Le on 11/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIPlaceHolderTextView.h"
#import "TDUserListView.h"
#import "TDKeyboardObserver.h"

@interface TDCreatePostHeaderCell : UICollectionViewCell<UITextViewDelegate, NSLayoutManagerDelegate, TDUserListViewDelegate, TDKeyboardObserverDelegate>
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIButton *prButton;
@property (weak, nonatomic) IBOutlet UIView *topLineView;
@property (weak, nonatomic) IBOutlet UIView *optionsView;
@property (weak, nonatomic) IBOutlet UIButton *mediaButton;

@property (nonatomic) BOOL isOriginal;
@property (nonatomic) BOOL isPR;
@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *thumbnailPath;
@property (nonatomic) TDUserListView *userListView;
@property (nonatomic) UIImage *prOnImage;
@property (nonatomic) UIImage *prOffImage;
@property (nonatomic) TDKeyboardObserver *keyboardObserver;

@end
