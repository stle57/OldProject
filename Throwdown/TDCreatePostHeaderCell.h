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

#define TD_LOCATION_BUTTON_OFF 0
#define TD_LOCATION_BUTTON_ON  1
#define TD_PR_BUTTON_OFF       2
#define TD_PR_BUTTON_ON        3

@protocol TDCreatePostHeaderCellDelegate <NSObject>
@optional
-(void)locationButtonPressed;
-(void)mediaButtonPressed;
-(void)removeButtonPressed;
-(void)showLocationActionSheet:(NSString*)location;
-(void)prButtonPressed;
-(void)postButtonEnabled:(BOOL)enable;
-(void)commentTextViewBeginResponder:(BOOL)yes;
-(void)adjustCollectionViewHeight;
@end

@interface TDCreatePostHeaderCell : UICollectionViewCell<UITextViewDelegate, NSLayoutManagerDelegate, TDUserListViewDelegate, TDKeyboardObserverDelegate>

@property (nonatomic, weak) id <TDCreatePostHeaderCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIButton *prButton;
@property (weak, nonatomic) IBOutlet UIView *topLineView;
@property (weak, nonatomic) IBOutlet UIView *optionsView;
@property (weak, nonatomic) IBOutlet UIButton *mediaButton;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

//@property (nonatomic) BOOL isOriginal;
//@property (nonatomic) NSString *filename;
//@property (nonatomic) NSString *thumbnailPath;
@property (nonatomic) TDUserListView *userListView;
@property (nonatomic) UIImage *prOnImage;
@property (nonatomic) UIImage *prOffImage;
@property (nonatomic) TDKeyboardObserver *keyboardObserver;
@property (nonatomic) NSInteger taggedUsers;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;

- (IBAction)prButtonPressed:(id)sender;
- (IBAction)locationButtonPressed:(id)sender;
- (IBAction)mediaButtonPressed:(id)sender;
- (IBAction)removeButtonPressed:(id)sender;

- (void)addMedia:(NSString *)filename thumbnail:(NSString *)thumbnailPath isOriginal:(BOOL)original;

- (void)changeLocationButton:(NSString*)locationName locationSet:(BOOL)locationSet;
@end
