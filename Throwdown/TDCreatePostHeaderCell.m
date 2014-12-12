//
//  TDCreatePostHeader.m
//  Throwdown
//
//  Created by Stephanie Le on 11/20/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//
#import <AssetsLibrary/AssetsLibrary.h>

#import "TDCreatePostHeaderCell.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDTextViewControllerHelper.h"
#import "UIAlertView+TDBlockAlert.h"
#import "TDDeviceInfo.h"

static int const kTextViewConstraint = 84;
static int const kTextViewHeightWithUserList = 70;
static int const kTextViewMargin = 15;
static int const kMaxLocationStrLength = 14;
static int const kBezierMargin = 18;
static NSString  *newPRStr = @"New PR";
static NSString  *location = @"Location";

@implementation TDCreatePostHeaderCell
@synthesize delegate;

- (void)awakeFromNib {
    // Initialization code
    debug NSLog(@"inside awakeFromNib-");
    self.backgroundColor = [UIColor whiteColor];
    
    self.commentTextView.delegate = self;
    self.commentTextView.font = [TDConstants fontRegularSized:17];
    self.commentTextView.layoutManager.delegate = self;
    [self.commentTextView setPlaceholder:@"What's happening?"];
    CGRect commentFrame = self.commentTextView.frame;
    commentFrame.size.width = SCREEN_WIDTH - kTextViewMargin;
    self.commentTextView.frame = commentFrame;
    
    // preloading images
    self.prOffImage = [UIImage imageNamed:@"trophy_off"];
    self.prOnImage =  [UIImage imageNamed:@"trophy_on"];
    
    NSAttributedString *locationStr = [TDViewControllerHelper makeParagraphedTextWithString:location font:[TDConstants fontRegularSized:14] color:[TDConstants commentTimeTextColor] lineHeight:16. lineHeightMultipler:16/14.];
    [self.locationButton setAttributedTitle:locationStr forState:UIControlStateNormal];
    
    NSAttributedString *prStr = [TDViewControllerHelper makeParagraphedTextWithString:newPRStr font:[TDConstants fontRegularSized:14] color:[TDConstants commentTimeTextColor] lineHeight:16. lineHeightMultipler:16/14.];
    [self.prButton setAttributedTitle:prStr forState:UIControlStateNormal];
    self.prButton.tag = TD_PR_BUTTON_OFF;
    
    // User name filter table view
    if (self.userListView == nil) {
        self.userListView = [[TDUserListView alloc] initWithFrame:CGRectMake(0, kTextViewHeightWithUserList, SCREEN_WIDTH, 0)];
        self.userListView.delegate = self;
        [self addSubview:self.userListView];
    }
    [self adjustFramesForView];
    
    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];

    
    // preloading images
    self.prOffImage = [UIImage imageNamed:@"trophy_off"];
    self.prOnImage =  [UIImage imageNamed:@"trophy_on"];
    
    // User name filter table view
    if (self.userListView == nil) {
        self.userListView = [[TDUserListView alloc] initWithFrame:CGRectMake(0, kTextViewHeightWithUserList, SCREEN_WIDTH, 0)];
        self.userListView.delegate = self;
        [self.optionsView addSubview:self.userListView];
    }

    debug NSLog(@"comment view frame = %@", NSStringFromCGRect(self.commentTextView.frame));
    debug NSLog(@"options view frame = %@", NSStringFromCGRect(self.optionsView.frame));
    debug NSLog(@"locationButton frame = %@", NSStringFromCGRect(self.locationButton.frame));
    debug NSLog(@"prButton frame = %@", NSStringFromCGRect(self.prButton.frame));
    debug NSLog(@"topLine view frame = %@", NSStringFromCGRect(self.topLineView.frame));
    
    [self.keyboardObserver startListening];
    
    CGRect mediaFrame = self.mediaButton.frame;
    mediaFrame.origin.x = SCREEN_WIDTH - 15 - self.mediaButton.frame.size.width - kTextViewMargin;
    mediaFrame.origin.y = 0;
    mediaFrame.size.height = [[UIImage imageNamed:@"media_attach_placeholder"] size].height ;
    mediaFrame.size.width = [[UIImage imageNamed:@"media_attach_placeholder"] size].width ;
    self.mediaButton.frame = mediaFrame;
    
    CGRect removeButtonFrame = CGRectMake(self.mediaButton.frame.origin.x + self.mediaButton.frame.size.width -15,
                                          self.mediaButton.frame.origin.y + self.mediaButton.frame.size.height-15,
                                          [[UIImage imageNamed:@"remove_media_x"] size].width,
                                          [[UIImage imageNamed:@"remove_media_x"] size].height);
    
    self.removeButton.frame = removeButtonFrame;
    self.removeButton.hidden = YES;
    
    [self.commentTextView addSubview:self.mediaButton];
    [self.commentTextView addSubview:self.removeButton];
    
    CGRect bezFrame = CGRectMake(self.mediaButton.frame.origin.x- kBezierMargin,
                                 self.mediaButton.frame.origin.y,
                                 self.mediaButton.frame.size.width + kBezierMargin +kTextViewMargin ,
                                 self.mediaButton.frame.size.height+ kTextViewMargin);
    
    UIBezierPath *rect   = [ UIBezierPath bezierPathWithRect: bezFrame];
    
    self.commentTextView.textContainer.exclusionPaths = @[rect];
    debug NSLog(@"done awakeFromNib");
}

- (void)dealloc {
    self.delegate = nil;
    self.commentTextView.delegate = nil;
    [self.userListView removeFromSuperview];
    self.userListView.delegate = nil;
    self.userListView = nil;
    [self.keyboardObserver stopListening];
    self.keyboardObserver = nil;
}

- (void)adjustFramesForView {
    CGFloat keyboardHeight;
    
    switch ((int)[UIScreen mainScreen].bounds.size.width) {
        case 320: // iPhone 4S/5/5S
            keyboardHeight = TD_IPHONE_4_KEYBOARD_HEIGHT;
            break;
        case 375: // iPhone 6
            keyboardHeight = TD_IPHONE_6_KEYBOARD_HEIGHT;
            break;
        case 414: // iPhone 6+
            keyboardHeight = TD_IPHONE_6PLUS_KEYBOARD_HEIGHT;
            break;
        default:
            keyboardHeight = 0;
            break;
    }
    debug NSLog(@"keyboardHeight on intial load =%f", keyboardHeight);
    
    CGRect frame = self.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    frame.size.width = SCREEN_WIDTH;
    frame.size.height= SCREEN_HEIGHT - 64 - keyboardHeight;
    self.frame = frame;
    
    CGRect optionsViewFrame = self.optionsView.frame;
    optionsViewFrame.size.height = 38;
    optionsViewFrame.size.width = SCREEN_WIDTH;
    optionsViewFrame.origin.x = 0;
    optionsViewFrame.origin.y = self.frame.size.height - self.optionsView.frame.size.height;
    self.optionsView.frame = optionsViewFrame;
    
    CGRect locationFrame = self.locationButton.frame;
    locationFrame.size.width = self.optionsView.frame.size.width/2;
    locationFrame.origin.x = 0;
    locationFrame.origin.y = 0;
    self.locationButton.frame = locationFrame;
    
    CGRect prButtonFrame = self.prButton.frame;
    prButtonFrame.size.width = self.optionsView.frame.size.width/2;
    prButtonFrame.origin.x = self.optionsView.frame.size.width/2;
    self.prButton.frame = prButtonFrame;
    
    CGRect textViewFrame = self.commentTextView.frame;
    textViewFrame.size.width = SCREEN_WIDTH- kTextViewMargin;
    textViewFrame.size.height = SCREEN_HEIGHT - self.optionsView.frame.size.height - 64 - keyboardHeight - kTextViewMargin;
    self.commentTextView.frame = textViewFrame;
}

#pragma mark - TDUserListViewDelegate

- (void)selectedUser:(NSDictionary *)user forUserNameFilter:(NSString *)userNameFilter {
    NSString *currentText = self.commentTextView.text;
    NSString *userName = [[user objectForKey:@"username"] stringByAppendingString:@" "];
    NSString *newText = [currentText substringToIndex:(currentText.length - userNameFilter.length)] ;
    
    self.commentTextView.text = [newText stringByAppendingString:userName];
    [self resetTextViewSize];
}


- (void)alignCarretInTextView:(UITextView *)textView {
    [textView scrollRangeToVisible:textView.selectedRange];
}

- (void)resetTextViewSize {
    self.textViewConstraint.constant = kTextViewConstraint;
    [self.contentView layoutIfNeeded];
    [self alignCarretInTextView:self.commentTextView];
}

#pragma mark - NSLayoutManagerDelegate

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    return 3;
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return [TDTextViewControllerHelper textView:textView shouldChangeTextInRange:range replacementText:text];
}

- (void)textViewDidChange:(UITextView *)textView {
    if (delegate && [delegate respondsToSelector:@selector(postButtonEnabled:)]) {
        BOOL enabled = ([[textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0);
        [delegate postButtonEnabled:enabled];
    }
    [self.userListView showUserSuggestions:textView callback:^(BOOL success) {
        if (success) {
            CGFloat height = self.optionsView.frame.origin.y + self.optionsView.frame.size.height - kTextViewHeightWithUserList;
            [self.userListView updateFrame:CGRectMake(0, kTextViewHeightWithUserList, SCREEN_WIDTH, height)];
            self.textViewConstraint.constant = height;
            [self.contentView layoutIfNeeded];
            [self alignCarretInTextView:textView];
        } else {
            [self resetTextViewSize];
        }
    }];
}

- (void)textViewDidBeginEditing:(UITextView *)inView
{
    [self performSelector:@selector(setCursorToBeginning:) withObject:inView afterDelay:0.01];
    if (delegate && [delegate respondsToSelector:@selector(commentTextViewBeginResponder:)]) {
        [delegate commentTextViewBeginResponder:YES];
    }
}

- (void)setCursorToBeginning:(UITextView *)inView
{
    if (self.commentTextView.text.length == 0) {
        self.commentTextView.selectedRange = NSMakeRange(15, 0);
    }
}

#pragma mark - UI buttons

- (IBAction)mediaButtonPressed:(id)sender {
    if (delegate && [delegate respondsToSelector:@selector(mediaButtonPressed)]) {
        [self.commentTextView resignFirstResponder];
        [self.mediaButton setEnabled:NO];
        [delegate mediaButtonPressed];
    }
}

- (IBAction)prButtonPressed:(id)sender {
    if (delegate && [delegate respondsToSelector:@selector(prButtonPressed)]) {
        if (self.prButton.tag == TD_PR_BUTTON_OFF) {
            [self.prButton setImage:self.prOnImage forState:UIControlStateNormal];
            [self.prButton setImage:self.prOnImage forState:UIControlStateHighlighted];
            [self.prButton setImage:self.prOnImage forState:UIControlStateSelected];
            self.prButton.tag = TD_PR_BUTTON_ON;
            NSAttributedString *prStr = [TDViewControllerHelper makeParagraphedTextWithString:newPRStr font:[TDConstants fontRegularSized:14] color:[TDConstants brandingRedColor] lineHeight:16. lineHeightMultipler:16/14.];
            [self.prButton setAttributedTitle:prStr forState:UIControlStateNormal];
            
        } else {
            [self.prButton setImage:self.prOffImage forState:UIControlStateNormal];
            [self.prButton setImage:self.prOffImage forState:UIControlStateHighlighted];
            [self.prButton setImage:self.prOffImage forState:UIControlStateSelected];
            self.prButton.tag = TD_PR_BUTTON_OFF;
            NSAttributedString *prStr = [TDViewControllerHelper makeParagraphedTextWithString:newPRStr font:[TDConstants fontRegularSized:14] color:[TDConstants commentTimeTextColor] lineHeight:16. lineHeightMultipler:16/14.];
            [self.prButton setAttributedTitle:prStr forState:UIControlStateNormal];
        }
        [delegate prButtonPressed];
    }
}



- (IBAction)locationButtonPressed:(id)sender {
    if (self.locationButton.tag == TD_LOCATION_BUTTON_ON) {
        if (delegate && [delegate respondsToSelector:@selector(showLocationActionSheet:)]) {
            [delegate showLocationActionSheet:self.locationButton.titleLabel.attributedText.string];
        }
    } else {
        if (delegate && [delegate respondsToSelector:@selector(locationButtonPressed)]) {
            [delegate locationButtonPressed];
        }
    }
}

#pragma mark - TDKeyboardObserverDelegate

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat keyboardHeight = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
    NSNumber *curveValue = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // animationCurve << 16 to convert it from a view animation curve to a view animation option
    [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{
        CGRect frame = self.frame;
        frame.size.height = SCREEN_HEIGHT - 64 - keyboardHeight;
        self.frame = frame;
        
        CGRect textViewFrame = self.commentTextView.frame;
        textViewFrame.size.height = SCREEN_HEIGHT - self.optionsView.frame.size.height - 64 - keyboardHeight - kTextViewMargin;
        self.commentTextView.frame = textViewFrame;

        CGRect optionsViewFrame = self.optionsView.frame;
        optionsViewFrame.origin.y = self.frame.size.height - self.optionsView.frame.size.height;
        self.optionsView.frame = optionsViewFrame;
        
        self.contentView.frame = self.bounds;
        
    } completion:nil];
    
    self.mediaButton.enabled = YES;
    
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // animationCurve << 16 to convert it from a view animation curve to a view animation option
    NSDictionary *info = [notification userInfo];
    NSNumber *curveValue = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{
        //self.optionsViewConstraint.constant = 0;
        //[self.contentView layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardFrameChanged:(CGRect)keyboardFrame {
    debug NSLog(@"frame changed for keyboard - height-%f", keyboardFrame.size.height);
    if (delegate && [delegate respondsToSelector:@selector(adjustCollectionViewHeight)]) {
        [delegate adjustCollectionViewHeight];
    }
}


- (void)addMedia:(NSString *)filename thumbnail:(NSString *)thumbnailPath isOriginal:(BOOL)original {
    [self.mediaButton setImage:[UIImage imageWithContentsOfFile:thumbnailPath] forState:UIControlStateNormal];
    
    [self.mediaButton setEnabled:NO];
    [self.removeButton setHidden:NO];
    [self.commentTextView becomeFirstResponder];
    
}

- (IBAction)removeButtonPressed:(id)sender {
    if (delegate && [delegate respondsToSelector:@selector(removeButtonPressed)]) {
        [self.mediaButton setImage:[UIImage imageNamed:@"media_attach_placeholder"] forState:UIControlStateNormal];
        [self.mediaButton setImage:[UIImage imageNamed:@"media_attach_placeholder_hit"] forState:UIControlStateHighlighted];
        [self.mediaButton setImage:[UIImage imageNamed:@"media_attach_placeholder_hit"] forState:UIControlStateSelected];
        [self.mediaButton setEnabled:YES];
        [self.removeButton setHidden:YES];
        [delegate removeButtonPressed];
    }
}

- (void)changeLocationButton:(NSString*)locationName locationSet:(BOOL)locationSet {
    if (locationName.length > kMaxLocationStrLength) {
        NSRange range = NSMakeRange (0, kMaxLocationStrLength);
        locationName = [locationName substringWithRange:range];
        locationName = [locationName stringByAppendingString:@"..."];
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:locationName];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:16/14.];
    [paragraphStyle setMinimumLineHeight:16.];
    [paragraphStyle setMaximumLineHeight:16.];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, locationName.length)];
    [attributedString addAttribute:NSFontAttributeName value:[TDConstants fontRegularSized:14] range:NSMakeRange(0, locationName.length)];
    
    if (locationSet) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants brandingRedColor] range:NSMakeRange(0, locationName.length)];
        [self.locationButton setImage:[UIImage imageNamed:@"icon_pindrop_on"] forState:UIControlStateNormal];
        [self.locationButton setAttributedTitle:attributedString forState:UIControlStateNormal];
        self.locationButton.tag = TD_LOCATION_BUTTON_ON;
     } else {
         [attributedString addAttribute:NSForegroundColorAttributeName value:[TDConstants commentTimeTextColor] range:NSMakeRange(0, locationName.length)];
         [self.locationButton setImage:[UIImage imageNamed:@"icon_pindrop_off"] forState:UIControlStateNormal];
         [self.locationButton setAttributedTitle:attributedString forState:UIControlStateNormal];
         self.locationButton.tag = TD_LOCATION_BUTTON_OFF;
    }
}

@end
