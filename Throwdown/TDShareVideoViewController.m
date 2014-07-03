//
//  TDShareVideoViewController.m
//  Throwdown
//
//  Created by Andrew C on 3/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDShareVideoViewController.h"
#import "TDViewControllerHelper.h"
#import "UIPlaceHolderTextView.h"
#import "TDConstants.h"
#import "TDAnalytics.h"
#import "TDPostAPI.h"
#import "UIAlertView+TDBlockAlert.h"

@interface TDShareVideoViewController () <UITextViewDelegate, NSLayoutManagerDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
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

//@property (nonatomic) BOOL isOriginal;
@property (nonatomic) BOOL isPR;
@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *thumbnailPath;

@end

@implementation TDShareVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TDAnalytics sharedInstance] logEvent:@"camera_share_loaded"];
    UIButton *button = [TDViewControllerHelper navCloseButton];
    [button addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    [self.navigationBar setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontRegularSized:20],
                                       NSForegroundColorAttributeName: [TDConstants headerTextColor] }];

    self.commentTextView.delegate = self;
    self.commentTextView.font = [TDConstants fontRegularSized:17];
    self.commentTextView.layoutManager.delegate = self;
    [self.commentTextView setPlaceholder:@"What's happening?"];

    self.isPR = false;

    self.labelMedia.font = [TDConstants fontSemiBoldSized:16];
    self.labelMedia.textColor = [TDConstants disabledTextColor];
    self.labelPR.font = [TDConstants fontSemiBoldSized:16];
    self.labelPR.textColor = [TDConstants disabledTextColor];

    // Set font for "Post" button and sneacky way to hide the button when keyboard is down (same color as background)
    [self.postButton setTitleTextAttributes:@{ NSForegroundColorAttributeName:[TDConstants brandingRedColor], NSFontAttributeName:[TDConstants fontSemiBoldSized:18] } forState:UIControlStateNormal];
    [self.postButton setTitleTextAttributes:@{ NSForegroundColorAttributeName:[TDConstants disabledTextColor], NSFontAttributeName:[TDConstants fontSemiBoldSized:18] } forState:UIControlStateDisabled];
    [self updatePostButton:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    // For 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.optionsView.center = CGPointMake(self.optionsView.center.x, 445);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Delaying animation by 0.1s due to a timing bug when unwinding from adding media
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.commentTextView becomeFirstResponder];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.commentTextView resignFirstResponder];
}

- (void)dealloc {
    self.commentTextView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)updatePostButton:(BOOL)enabled {
    self.postButton.enabled = enabled;
}

- (void)cancelUpload {
    if (self.filename) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadCancelled object:nil userInfo:@{ @"filename":[self.filename copy] }];
        self.filename = nil;
    }
}

#pragma mark - segue / vc to vc interface

- (void)shareVideo:(NSString *)filename withThumbnail:(NSString *)thumbnailPath isOriginal:(BOOL)original {
    self.thumbnailPath = thumbnailPath;
    self.filename = filename;
//    self.isOriginal = original;
    [self.previewImage setImage:[UIImage imageWithContentsOfFile:self.thumbnailPath]];
    self.previewImage.hidden = NO;
    [self updatePostButton:YES];
    self.labelMedia.textColor = [TDConstants headerTextColor];
    self.labelMedia.text = @"Remove";
    [self.mediaButton setImage:nil forState:UIControlStateNormal];
    [self.mediaButton setImage:nil forState:UIControlStateHighlighted];
    [self.mediaButton setImage:nil forState:UIControlStateSelected];
}

- (IBAction)unwindToShareView:(UIStoryboardSegue *)sender {
    // Empty on purpose
}


#pragma mark - Keyboard handling

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];

    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];

    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat keyboardHeight = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;

    NSNumber *curveValue = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGPoint center = self.optionsView.center;
    center.y = screenHeight - keyboardHeight - (self.optionsView.layer.frame.size.height / 2);

    // animationCurve << 16 to convert it from a view animation curve to a view animation option
    [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{
        self.optionsView.center = center;
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSNumber *curveValue = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGPoint center = self.optionsView.center;
    center.y = [UIScreen mainScreen].bounds.size.height - (self.optionsView.layer.frame.size.height / 2);

    // animationCurve << 16 to convert it from a view animation curve to a view animation option
    [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{
        self.optionsView.center = center;
    } completion:nil];
}

#pragma mark UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self updatePostButton:(self.filename || [[textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0)];
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
        UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:@"Delete?" message:nil delegate:self cancelButtonTitle:@"Keep" otherButtonTitles:@"Delete", nil];
        [confirm showWithCompletionBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (alertView.cancelButtonIndex != buttonIndex) {
                [self cancelUpload];
                self.thumbnailPath = nil;
                self.filename = nil;
//                self.isOriginal = NO;
                self.previewImage.image = nil;
                self.previewImage.hidden = YES;
                [self updatePostButton:[[self.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0];
                self.labelMedia.textColor = [TDConstants disabledTextColor];
                self.labelMedia.text = @"Add Media";
                [self.mediaButton setImage:[UIImage imageNamed:@"camera_grey_88x55"] forState:UIControlStateNormal];
                [self.mediaButton setImage:[UIImage imageNamed:@"camera_grey_88x55_hit"] forState:UIControlStateHighlighted];
                [self.mediaButton setImage:[UIImage imageNamed:@"camera_grey_88x55_hit"] forState:UIControlStateSelected];
            }
        }];
    } else {
        [self.commentTextView resignFirstResponder];
        [self performSegueWithIdentifier:@"OpenRecordViewSegue" sender:self];
    }
}

- (IBAction)prButtonPressed:(id)sender {
    self.isPR = !self.isPR;
    if (self.isPR) {
        [self.prButton setImage:[UIImage imageNamed:@"pr_star_on_74x74"] forState:UIControlStateNormal];
        [self.prButton setImage:[UIImage imageNamed:@"pr_star_on_74x74_hit"] forState:UIControlStateHighlighted];
        [self.prButton setImage:[UIImage imageNamed:@"pr_star_on_74x74_hit"] forState:UIControlStateSelected];
        self.labelPR.textColor = [TDConstants brandingRedColor];
    } else {
        [self.prButton setImage:[UIImage imageNamed:@"pr_star_off_74x74"] forState:UIControlStateNormal];
        [self.prButton setImage:[UIImage imageNamed:@"pr_star_off_74x74_hit"] forState:UIControlStateHighlighted];
        [self.prButton setImage:[UIImage imageNamed:@"pr_star_off_74x74_hit"] forState:UIControlStateSelected];
        self.labelPR.textColor = [TDConstants disabledTextColor];
    }
}

- (IBAction)postButtonPressed:(id)sender {
    NSString *comment = [self.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (self.filename) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadComments
                                                            object:nil
                                                          userInfo:@{ @"filename":self.filename,
                                                                      @"comment":comment,
                                                                      @"pr": [NSNumber numberWithBool:self.isPR] }];
    } else {
        // Text post only
        [[TDPostAPI sharedInstance] addPost:nil comment:comment isPR:self.isPR kind:@"text" success:nil failure:nil];
    }
    [self performSegueWithIdentifier:@"VideoCloseSegue" sender:self];
    [[TDAnalytics sharedInstance] logEvent:@"camera_shared"];
}

@end
