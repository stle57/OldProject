//
//  TDCreatePostViewController.m
//  Throwdown
//
//  Created by Andrew C on 3/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDCreatePostViewController.h"
#import "TDSharePostViewController.h"
#import "TDViewControllerHelper.h"
#import "TDTextViewControllerHelper.h"
#import "UIPlaceHolderTextView.h"
#import "TDConstants.h"
#import "TDAnalytics.h"
#import "TDPostAPI.h"
#import "TDSlideUpSegue.h"
#import "TDUnwindSlideLeftSegue.h"
#import "UIAlertView+TDBlockAlert.h"
#import "TDUserAPI.h"
#import "TDAPIClient.h"
#import "TDUserListView.h"
#import "TDKeyboardObserver.h"

static int const kTextViewConstraint = 84;
static int const kUserListHeight = 140;

@interface TDCreatePostViewController () <UITextViewDelegate, NSLayoutManagerDelegate, TDKeyboardObserverDelegate>

@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBarItem;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;
@property (weak, nonatomic) IBOutlet UILabel *labelPR;
@property (weak, nonatomic) IBOutlet UILabel *labelMedia;
@property (weak, nonatomic) IBOutlet UIButton *mediaButton;
@property (weak, nonatomic) IBOutlet UIButton *prButton;
@property (weak, nonatomic) IBOutlet UIView *topLineView;
@property (weak, nonatomic) IBOutlet UIView *optionsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *optionsViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;

@property (nonatomic) BOOL isOriginal;
@property (nonatomic) BOOL isPR;
@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *thumbnailPath;
@property (nonatomic) TDUserListView *userListView;

@property (nonatomic) UIImage *prOnImage;
@property (nonatomic) UIImage *prOffImage;
@property (nonatomic) TDKeyboardObserver *keyboardObserver;

@end

@implementation TDCreatePostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TDAnalytics sharedInstance] logEvent:@"camera_share_loaded"];

    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barStyle = UIBarStyleBlack;
    navigationBar.translucent = NO;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontSemiBoldSized:18],
                                             NSForegroundColorAttributeName: [UIColor whiteColor] }];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

    UIButton *button = [TDViewControllerHelper navCloseButton];
    [button addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    self.commentTextView.delegate = self;
    self.commentTextView.font = [TDConstants fontRegularSized:17];
    self.commentTextView.layoutManager.delegate = self;
    [self.commentTextView setPlaceholder:@"What's happening?"];

    // preloading images
    self.prOffImage = [UIImage imageNamed:@"trophy_off_74x74"];
    self.prOnImage =  [UIImage imageNamed:@"trophy_74x74"];

    self.isPR = false;

    self.labelMedia.font = [TDConstants fontSemiBoldSized:16];
    self.labelMedia.textColor = [TDConstants disabledTextColor];
    self.labelPR.font = [TDConstants fontSemiBoldSized:16];
    self.labelPR.textColor = [TDConstants disabledTextColor];

    [self.postButton setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[TDConstants fontSemiBoldSized:18] } forState:UIControlStateNormal];
    [self.postButton setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor colorWithWhite:1 alpha:0.5], NSFontAttributeName:[TDConstants fontSemiBoldSized:18] } forState:UIControlStateDisabled];
    self.postButton.enabled = NO;

    // User name filter table view
	if (self.userListView == nil) {
		self.userListView = [[TDUserListView alloc] initWithFrame:CGRectMake(0, kUserListHeight, SCREEN_WIDTH, 0)];
        self.userListView.delegate = self;
        [self.view addSubview:self.userListView];
	}

    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.keyboardObserver startListening];
    [self.commentTextView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.commentTextView resignFirstResponder];
    [self.keyboardObserver stopListening];
}

- (void)dealloc {
    self.commentTextView.delegate = nil;
    [self.userListView removeFromSuperview];
    self.userListView.delegate = nil;
    self.userListView = nil;
    [self.keyboardObserver stopListening];
    self.keyboardObserver = nil;
}

- (void)cancelUpload {
    if (self.filename) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadCancelled object:nil userInfo:@{ @"filename":[self.filename copy] }];
        self.filename = nil;
    }
}

#pragma mark - segue / vc to vc interface

- (void)addMedia:(NSString *)filename thumbnail:(NSString *)thumbnailPath isOriginal:(BOOL)original {
    self.thumbnailPath = thumbnailPath;
    self.filename = filename;
    self.isOriginal = original;
    [self.previewImage setImage:[UIImage imageWithContentsOfFile:self.thumbnailPath]];
    self.previewImage.hidden = NO;
    self.postButton.enabled = YES;
    self.labelMedia.textColor = [TDConstants headerTextColor];
    self.labelMedia.text = @"Remove";
    [self.mediaButton setImage:nil forState:UIControlStateNormal];
    [self.mediaButton setImage:nil forState:UIControlStateHighlighted];
    [self.mediaButton setImage:nil forState:UIControlStateSelected];
}
#pragma mark - Keyboard / TextView management

- (void)removeMedia {
    [self cancelUpload];
    self.thumbnailPath = nil;
    self.filename = nil;
    self.isOriginal = NO;
    self.previewImage.image = nil;
    self.previewImage.hidden = YES;
    self.postButton.enabled = [[self.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;
    self.labelMedia.textColor = [TDConstants disabledTextColor];
    self.labelMedia.text = @"Add Media";
    [self.mediaButton setImage:[UIImage imageNamed:@"camera_grey_88x55"] forState:UIControlStateNormal];
    [self.mediaButton setImage:[UIImage imageNamed:@"camera_grey_88x55_hit"] forState:UIControlStateHighlighted];
    [self.mediaButton setImage:[UIImage imageNamed:@"camera_grey_88x55_hit"] forState:UIControlStateSelected];
}

- (IBAction)unwindToShareView:(UIStoryboardSegue *)sender {
    // Empty on purpose
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    debug NSLog(@"share video unwind segue: %@", identifier);

    if ([@"MediaCloseSegue" isEqualToString:identifier]) {
        return [[TDSlideUpSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else if ([@"ReturnToComposeView" isEqualToString:identifier]) {
        return [[TDUnwindSlideLeftSegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
    } else {
        return [super segueForUnwindingToViewController:toViewController
                                     fromViewController:fromViewController
                                             identifier:identifier];
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
        self.optionsViewConstraint.constant = keyboardHeight;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // animationCurve << 16 to convert it from a view animation curve to a view animation option
    NSDictionary *info = [notification userInfo];
    NSNumber *curveValue = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{
        self.optionsViewConstraint.constant = 0;
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return [TDTextViewControllerHelper textView:textView shouldChangeTextInRange:range replacementText:text];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.postButton.enabled = (self.filename || [[textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0);
    [self.userListView showUserSuggestions:textView callback:^(BOOL success) {
        if (success) {
            [self.userListView updateFrame:CGRectMake(0, self.optionsView.frame.origin.y - kUserListHeight, SCREEN_WIDTH, kUserListHeight)];
            self.textViewConstraint.constant = kTextViewConstraint + kUserListHeight;
            [self.view layoutIfNeeded];
            [self alignCarretInTextView:textView];
        } else {
            [self resetTextViewSize];
        }
    }];
}

- (void)alignCarretInTextView:(UITextView *)textView {
    [textView scrollRangeToVisible:textView.selectedRange];
}

- (void)resetTextViewSize {
    self.textViewConstraint.constant = kTextViewConstraint;
    [self.view layoutIfNeeded];
    [self alignCarretInTextView:self.commentTextView];
}


#pragma mark - NSLayoutManagerDelegate

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    return 3;
}

#pragma mark - UI buttons

- (void)closeButtonPressed {
    [self cancelUpload];
    [self performSegueWithIdentifier:@"VideoCloseSegue" sender:self];
}

- (IBAction)mediaButtonPressed:(id)sender {
    if (self.filename) {
        if (self.isOriginal) {
            UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:@"Delete?" message:nil delegate:self cancelButtonTitle:@"Keep" otherButtonTitles:@"Delete", nil];
            [confirm showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                if (alertView.cancelButtonIndex != buttonIndex) {
                    [self removeMedia];
                }
            }];
        } else {
            [self removeMedia];
        }
    } else {
        [self.commentTextView resignFirstResponder];
        [self performSegueWithIdentifier:@"OpenRecordViewSegue" sender:self];
    }
}

- (IBAction)prButtonPressed:(id)sender {
    self.isPR = !self.isPR;
    if (self.isPR) {
        [self.prButton setImage:self.prOnImage forState:UIControlStateNormal];
        [self.prButton setImage:self.prOnImage forState:UIControlStateHighlighted];
        [self.prButton setImage:self.prOnImage forState:UIControlStateSelected];
        self.labelPR.textColor = [TDConstants brandingRedColor];
    } else {
        [self.prButton setImage:self.prOffImage forState:UIControlStateNormal];
        [self.prButton setImage:self.prOffImage forState:UIControlStateHighlighted];
        [self.prButton setImage:self.prOffImage forState:UIControlStateSelected];
        self.labelPR.textColor = [TDConstants disabledTextColor];
    }
}

- (IBAction)postButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"OpenShareWithViewSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"OpenShareWithViewSegue" isEqualToString:segue.identifier]) {
        NSString *comment = [self.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        TDSharePostViewController *vc = [segue destinationViewController];
        [vc setValuesForSharing:self.filename withComment:comment isPR:self.isPR userGenerated:self.isOriginal];
    }
}

#pragma mark - TDUserListViewDelegate

- (void)selectedUser:(NSDictionary *)user forUserNameFilter:(NSString *)userNameFilter {
    NSString *currentText = self.commentTextView.text;
    NSString *userName = [[user objectForKey:@"username"] stringByAppendingString:@" "];
    NSString *newText = [currentText substringToIndex:(currentText.length - userNameFilter.length)] ;

    self.commentTextView.text = [newText stringByAppendingString:userName];
    [self resetTextViewSize];
}

@end
