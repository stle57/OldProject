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

@interface TDShareVideoViewController () <UITextViewDelegate, NSLayoutManagerDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationBarItem;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIImageView *previewImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeKeyboardButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (nonatomic) NSString *filename;
@property (nonatomic) NSString *thumbnailPath;

@end

@implementation TDShareVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[TDAnalytics sharedInstance] logEvent:@"camera_share_loaded"];
    UIButton *button = [TDViewControllerHelper navBackButton];
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationBarItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    [self.navigationBar setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontRegularSized:20],
                                       NSForegroundColorAttributeName: [TDConstants headerTextColor] }];

    self.commentTextView.delegate = self;
    self.commentTextView.font = [TDConstants fontRegularSized:17];
    self.commentTextView.layoutManager.delegate = self;
    [self.commentTextView setPlaceholder:kCommentDefaultText];

    [self.previewImage setImage:[UIImage imageWithContentsOfFile:self.thumbnailPath]];

    // Set font for "Done" button and sneacky way to hide the button when keyboard is down (same color as background)
    [self.closeKeyboardButton setTitleTextAttributes:@{ NSFontAttributeName:[TDConstants fontRegularSized:15.0] } forState:UIControlStateNormal];
    [self.closeKeyboardButton setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0] } forState:UIControlStateDisabled];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willShowKeyboard:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willHideKeyboard:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    // For 3.5" screens
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        self.saveButton.center = CGPointMake(self.saveButton.center.x, 455);
    }
}

- (void)dealloc {
    self.commentTextView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)shareVideo:(NSString *)filename withThumbnail:(NSString *)thumbnailPath {
    self.thumbnailPath = thumbnailPath;
    self.filename = filename;
}

- (void)backButtonPressed {
    // TODO: confirm navigation and save any contents
    [self performSegueWithIdentifier:@"UnwindSlideLeftSegue" sender:self];
}

- (void)willShowKeyboard:(NSNotification *)notification {
    self.closeKeyboardButton.enabled = YES;
}

- (IBAction)dismissKeyboard:(id)sender {
    [self.commentTextView resignFirstResponder];
}

- (void)willHideKeyboard:(NSNotification *)notification {
    self.closeKeyboardButton.enabled = NO;
}

- (IBAction)saveButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationUploadComments
                                                        object:nil
                                                      userInfo:@{ @"filename":self.filename,
                                                                  @"comment":self.commentTextView.text }];
    [self performSegueWithIdentifier:@"VideoCloseSegue" sender:self];
    [[TDAnalytics sharedInstance] logEvent:@"camera_shared"];
}

#pragma mark - NSLayoutManagerDelegate

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    return 3;
}

@end
