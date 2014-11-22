//
//  TDCreatePostHeader.m
//  Throwdown
//
//  Created by Stephanie Le on 11/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDCreatePostHeaderCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"

static int const kTextViewConstraint = 84;
static int const kTextViewHeightWithUserList = 70;

@implementation TDCreatePostHeaderCell

- (void)awakeFromNib {
    // Initialization code
    self.commentTextView.delegate = self;
    self.commentTextView.font = [TDConstants fontRegularSized:17];
    self.commentTextView.layoutManager.delegate = self;
    [self.commentTextView setPlaceholder:@"What's happening?"];
    
    // preloading images
    self.prOffImage = [UIImage imageNamed:@"trophy_off"];
    self.prOnImage =  [UIImage imageNamed:@"trophy_on"];

    self.isPR = false;
    
    NSAttributedString *locationStr = [TDViewControllerHelper makeParagraphedTextWithString:@"Location" font:[TDConstants fontRegularSized:14] color:[TDConstants commentTimeTextColor] lineHeight:16. lineHeightMultipler:16/14.];
    [self.locationButton setAttributedTitle:locationStr forState:UIControlStateNormal];
    
    NSAttributedString *prStr = [TDViewControllerHelper makeParagraphedTextWithString:@"New PR" font:[TDConstants fontRegularSized:14] color:[TDConstants commentTimeTextColor] lineHeight:16. lineHeightMultipler:16/14.];
    [self.prButton setAttributedTitle:prStr forState:UIControlStateNormal];
    
    // User name filter table view
    if (self.userListView == nil) {
        self.userListView = [[TDUserListView alloc] initWithFrame:CGRectMake(0, kTextViewHeightWithUserList, SCREEN_WIDTH, 0)];
        self.userListView.delegate = self;
        [self addSubview:self.userListView];
    }
    
    CGRect optionsViewFrame = self.optionsView.frame;
    optionsViewFrame.size.height = 38;
    optionsViewFrame.size.width = SCREEN_WIDTH;
    optionsViewFrame.origin.x = 0;
    optionsViewFrame.origin.y = SCREEN_HEIGHT - self.commentTextView.frame.size.height - 64;
    self.optionsView.frame = optionsViewFrame;
    
    CGRect textViewFrame = self.commentTextView.frame;
    textViewFrame.origin.x = 0;
    textViewFrame.origin.y = 0;
    textViewFrame.size.width = SCREEN_WIDTH;
    textViewFrame.size.height = SCREEN_HEIGHT - 64 - self.optionsView.frame.size.height;
    self.commentTextView.frame = textViewFrame;
    
//    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];
    
}

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
//}
//
//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    [self.keyboardObserver startListening];
//    [self.commentTextView becomeFirstResponder];
//}
//
//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    [self.commentTextView resignFirstResponder];
//    [self.keyboardObserver stopListening];
//}

- (void)dealloc {
    self.commentTextView.delegate = nil;
    [self.userListView removeFromSuperview];
    self.userListView.delegate = nil;
    self.userListView = nil;
    [self.keyboardObserver stopListening];
    self.keyboardObserver = nil;
}


#pragma mark - TDUserListViewDelegate

- (void)selectedUser:(NSDictionary *)user forUserNameFilter:(NSString *)userNameFilter {
    NSString *currentText = self.commentTextView.text;
    NSString *userName = [[user objectForKey:@"username"] stringByAppendingString:@" "];
    NSString *newText = [currentText substringToIndex:(currentText.length - userNameFilter.length)] ;
    
    self.commentTextView.text = [newText stringByAppendingString:userName];
   // [self resetTextViewSize];
}
@end
