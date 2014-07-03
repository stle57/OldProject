//
//  TDDetailViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDDetailViewController.h"
#import "TDPostAPI.h"
#import "TDConstants.h"
#import "TDComment.h"
#import "TDViewControllerHelper.h"
#import "AFNetworking.h"
#import "TDUserProfileViewController.h"
#import "TDAnalytics.h"
#import "UIPlaceHolderTextView.h"

static float const kInputLineSpacing = 3;
static float const kMinInputHeight = 33.;
static float const kMaxInputHeight = 100.;

@interface TDDetailViewController () <UITextViewDelegate, NSLayoutManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *commentView;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIView *topLineView;
@property (weak, nonatomic) UIView *currentKeyboardView;

@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) CGFloat minLikeheight;
@property (nonatomic) BOOL liking;
@property (nonatomic) BOOL isEditing;
@property (nonatomic) NSString *cachedText;

@end

@implementation TDDetailViewController

- (void)dealloc {
    self.delegate = nil;
    self.post = nil;
    self.postId = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.textView.delegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    self.titleLabel.font = [TDConstants fontRegularSized:20];
    [self.navigationItem setTitleView:self.titleLabel];

    UIButton *backButton = [TDViewControllerHelper navBackButton];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

    // Delete or report icon - have to use uibutton to give design's hit state correctly
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setFrame:CGRectMake(0.0, 0.0, 20, 21)];
    [rightButton setImage:[UIImage imageNamed:@"nav_dots"] forState:UIControlStateNormal];
    [rightButton setImage:[UIImage imageNamed:@"nav_dots_hit"] forState:UIControlStateHighlighted];
    [rightButton addTarget:self action:@selector(reportButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *deleteBarButton = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = deleteBarButton;

    // Cell heights
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDDetailsLikesCell" owner:self options:nil];
    TDDetailsLikesCell *cell1 = [topLevelObjects objectAtIndex:0];
    self.minLikeheight = cell1.frame.size.height;
    cell1 = nil;

    // Typing Bottom
    self.textView.font = [TDConstants fontRegularSized:17];
    self.textView.delegate = self;
    self.textView.clipsToBounds = YES;
    self.textView.layoutManager.delegate = self;
    self.textView.layer.cornerRadius = 4;
    self.textView.layer.borderWidth = (1.0 / [[UIScreen mainScreen] scale]);
    self.textView.layer.borderColor = [UIColor colorWithRed:178./255. green:178./255. blue:178./255. alpha:1].CGColor;
    self.textView.contentInset = UIEdgeInsetsMake(0, 0, -10, 0);
    self.textView.placeholder = kCommentDefaultText;
    self.sendButton.titleLabel.font = [TDConstants fontSemiBoldSized:18.];
    self.sendButton.enabled = NO;
    self.topLineView.frame = CGRectMake(0, 0, 320, 1.0 / [[UIScreen mainScreen] scale]);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPosts:) name:TDRefreshPostsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullPostReturn:) name:FULL_POST_INFO_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCommentFailed:) name:TDNotificationNewCommentFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:TDNotificationRemovePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChange:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    CGFloat height = [UIScreen mainScreen].bounds.size.height - self.commentView.layer.frame.size.height;
    self.tableView.frame = CGRectMake(0, 0, 320, height);

    // TODO: only when user didn't go downstream
    // Get the full post info
    if (self.post && self.post.postId) {
        self.postId = self.post.postId;
    } else if (!self.post) {
        self.post = [[TDPost alloc] init];
    }
    if (self.postId) {
        [[TDPostAPI sharedInstance] getFullPostInfoForPostId:self.postId];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.isEditing) {
        [self.textView resignFirstResponder];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Delete / Report Post

- (void)reportButtonPressed:(id)sender {
    NSString *reportText;
    if ([self.post.user.userId isEqualToNumber:[[TDCurrentUser sharedInstance] currentUserObject].userId]) {
        reportText = @"Delete";
    } else {
        reportText = @"Report as Inappropriate";
    }

    UIActionSheet *actionSheet;
    if (self.post.slug) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:reportText
                                         otherButtonTitles:@"Copy Share Link", nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:reportText
                                         otherButtonTitles:nil];

    }
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        if ([self.post.user.userId isEqualToNumber:[[TDCurrentUser sharedInstance] currentUserObject].userId]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete?"
                                                            message:@"Are you sure you want to\ndelete this post?"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = 89890;
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report as Inappropriate?"
                                                            message:@"Please confirm you'd like to report this post as inappropriate."
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Report", nil];
            alert.tag = 18890;
            [alert show];
        }
    } else if (buttonIndex != actionSheet.cancelButtonIndex) {
        // index 1 = Copy Share Link
        [[TDAnalytics sharedInstance] logEvent:@"copied_share_url"];
        [[UIPasteboard generalPasteboard] setString:[TDConstants getShareURL:self.post.slug]];
        [[TDAppDelegate appDelegate] showToastWithText:@"Share link copied to clipboard" type:kToastIconType_Info payload:nil delegate:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    // Delete Yes is index 0
    if (alertView.tag == 89890 && buttonIndex != alertView.cancelButtonIndex) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        // Delete from server Server
        [[TDPostAPI sharedInstance] deletePostWithId:self.postId];
    } else if (alertView.tag == 18890 && buttonIndex != alertView.cancelButtonIndex) {
        // Report!
        [[TDPostAPI sharedInstance] reportPostWithId:self.postId];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report Sent"
                                                        message:@"Our moderators will review this post within the next 24 hours. Thank you."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Notifications

- (void)reloadPosts:(NSNotification*)notification {
    if (!self.liking) {
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api getFullPostInfoForPostId:self.postId];
    }
    self.liking = NO;
}

- (void)fullPostReturn:(NSNotification*)notification {
    if ([notification.userInfo isKindOfClass:[NSDictionary class]]) {
        TDPost *newPost = [[TDPost alloc] initWithDictionary:notification.userInfo];
        if ([newPost.postId isEqualToNumber:self.postId]) {
            [self.post loadUpFromDict:notification.userInfo];
            [self.tableView reloadData];
        }
    }
}

- (void)postDeleted:(NSNotification*)notification {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - TableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2 + [self.post.comments count];   // PostView, Like Cell, +Comments.count
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Post View
    if (indexPath.row == 0) {
        TDPostView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_POST_VIEW];
        if (!cell) {
            cell = [[TDPostView alloc] init];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.delegate = self;
        }

        [cell setPost:self.post];
        return cell;
    }

    // Likes
    if (indexPath.row == 1) {
        TDDetailsLikesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDDetailsLikesCell"];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDDetailsLikesCell" owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        [cell setLike:self.post.liked];
        [cell setLikesArray:self.post.likers];

        return cell;
    }

    // Comments
    TDDetailsCommentsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDDetailsCommentsCell"];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDDetailsCommentsCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSInteger commentNumber = (indexPath.row - 2);
    TDComment *comment = [self.post.comments objectAtIndex:commentNumber];
    cell.commentNumber = commentNumber;
    [cell updateWithComment:comment];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Post
    if (indexPath.row == 0) {
        return [TDPostView heightForPost:self.post];
    }

    // Likes row
    if (indexPath.row == 1) {
        if ([self.post.likers count] == 0) {
            return self.minLikeheight;    // at least one row to show 'like' button
        } else {
            NSUInteger textHeight = [TDDetailsLikesCell heightOfLikersLabel:self.post.likers];
            textHeight = (textHeight < self.minLikeheight ? self.minLikeheight : textHeight);
            return textHeight;
        }
    }

    // Comments
    // A comment is at least 40+height for the message text
    TDComment *comment = [self.post.comments objectAtIndex:(indexPath.row-2)];
    // Last one?
    if ((indexPath.row - 2) == ([self.post.comments count] - 1)) {
        return kCommentCellUserHeight + kCommentLastPadding + comment.messageHeight;
    }
    return kCommentCellUserHeight + kCommentPadding + comment.messageHeight;
}

#pragma mark - TDDetailsLikesCell Delegates

- (void)likeButtonPressedFromLikes {
    if (self.post.postId) {
        self.liking = YES;

        // Add the like for the update
        [self.post addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self updateAllRowsExceptTopOne];

        [[TDPostAPI sharedInstance] likePostWithId:self.post.postId];

        [self tellDelegateToUpdateThisPost];
    }
}

- (void)unLikeButtonPressedFromLikes {
    debug NSLog(@"TDDetailViewController-unLikeButtonPressedLikes");
    if (self.post.postId) {
        self.liking = YES;

        [self.post removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self updateAllRowsExceptTopOne];

        [[TDPostAPI sharedInstance] unLikePostWithId:self.post.postId];

        [self tellDelegateToUpdateThisPost];
    }
}

- (void)updateAllRowsExceptTopOne {
    NSInteger totalRows = [self tableView:nil numberOfRowsInSection:0];
    NSMutableArray *rowArray = [NSMutableArray array];
    for (int i = 1; i < totalRows; i++) {
        [rowArray addObject:[NSIndexPath indexPathForRow:i
                                               inSection:0]];
    }
    [self.tableView reloadRowsAtIndexPaths:rowArray
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)usernamePressedForLiker:(NSNumber *)likerId {
    [self showUserProfile:likerId];
}

- (void)tellDelegateToUpdateThisPost {
    if (self.delegate && [self.delegate respondsToSelector:@selector(replacePostId:withPost:)]) {
        [self.delegate replacePostId:self.postId withPost:self.post];
    }
}

#pragma mark - TDPostViewDelegate

- (void)userButtonPressedFromRow:(NSInteger)row {
    // Because we're on the detail page the only user available is the post's user
    [self showUserProfile:self.post.user.userId];
}

#pragma mark - TDPostViewDelegate and TDDetailsCommentsCellDelegate

- (void)userProfilePressedWithId:(NSNumber *)userId {
    [self showUserProfile:userId];
}

#pragma mark - TDDetailsCommentsCellDelegate

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
    debug NSLog(@"detail-userButtonPressedFromRow:%ld commentNumber:%ld, %@ %@", (long)row, (long)commentNumber, self.post.user.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);

    if (self.post.comments && [self.post.comments count] > row) {
        TDComment *comment = [self.post.comments objectAtIndex:commentNumber];
        [self showUserProfile:comment.user.userId];
    }
}

- (void)showUserProfile:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;
    vc.fromProfileType = kFromProfileScreenType_OtherUser;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Update Posts After User Change Notification
- (void)updatePostsAfterUserUpdate:(NSNotification *)notification {
    debug NSLog(@"%@ updatePostsAfterUserUpdate:%@", [self class], [[TDCurrentUser sharedInstance] currentUserObject]);

    if ([[[TDCurrentUser sharedInstance] currentUserObject].userId isEqualToNumber:self.post.user.userId]) {
        [self.post replaceUserAndLikesAndCommentsWithUser:[[TDCurrentUser sharedInstance] currentUserObject]];
    }

    [self.tableView reloadData];
}

#pragma mark - support unwinding on push notification

- (void)unwindToRoot {
    debug NSLog(@"unwind from detail view");
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - Keyboard / TextView management

- (void)keyboardDidChange:(NSNotification *)notification {
    if (!self.currentKeyboardView) {
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
            //Because we cant get access to the UIPeripheral throught the SDK we will just use UIView.
            //UIPeripheral is a subclass of UIView anyways
            //Iterate though each view inside of the selected Window
            for(int i = 0; i < [window.subviews count]; i++) {
                //Get a reference of the current view
                UIView *keyboard = [window.subviews objectAtIndex:i];
                //Assuming this is for 4.0+, In 3.0 you would use "<UIKeyboard"
                if([[keyboard description] hasPrefix:@"<UIPeripheral"] == YES) {
                    //Keyboard is now a UIView reference to the UIPeripheral we want
                    self.currentKeyboardView = keyboard;
                    [self.currentKeyboardView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
                }
            }
        }
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self unregisterKeyboardObserver];

    NSDictionary *info = [notification userInfo];

    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];

    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat keyboardHeight = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;

    NSNumber *curveValue = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];


    CGFloat height = MAX(MIN(self.textView.contentSize.height, kMaxInputHeight), kMinInputHeight);
    CGFloat bottom = screenHeight - keyboardHeight;

    CGRect textFrame = self.textView.frame;
    textFrame.size.height = height;

    CGRect commentFrame = self.commentView.frame;
    commentFrame.size.height = textFrame.size.height + 14;
    commentFrame.origin.y = bottom - (height + 14);

    CGRect tableFrame = self.tableView.layer.frame;
    tableFrame.size.height = bottom - height - 14;

    CGRect buttonFrame = self.sendButton.frame;
    buttonFrame.origin.y = (height + 14) - buttonFrame.size.height;

    // animationCurve << 16 to convert it from a view animation curve to a view animation option
    [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{
        self.textView.frame = textFrame;
        self.commentView.frame = commentFrame;
        self.sendButton.frame = buttonFrame;
        self.tableView.frame = tableFrame;
    } completion:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    self.isEditing = YES;
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.tableView addGestureRecognizer:self.tapGesture];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationPauseTapGesture object:nil];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    self.isEditing = NO;
    [self.tableView removeGestureRecognizer:self.tapGesture];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationResumeTapGesture object:nil];
    self.tapGesture = nil;
    [self unregisterKeyboardObserver];
}

- (void)handleTapFrom:(UITapGestureRecognizer *)tap {
    if (self.isEditing) {
        [self.textView resignFirstResponder];
    }
}

- (void)unregisterKeyboardObserver {
    if (self.currentKeyboardView) {
        [self.currentKeyboardView removeObserver:self forKeyPath:@"frame"];
        self.currentKeyboardView = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.currentKeyboardView && [keyPath isEqualToString:@"frame"]) {
        [self updateTextViewFromFrame:self.currentKeyboardView.frame];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (void)updateTextViewFromFrame:(CGRect)frame {
    CGRect tableFrame = self.tableView.layer.frame;
    tableFrame.size.height = frame.origin.y - self.commentView.layer.frame.size.height;
    self.tableView.frame = tableFrame;

    CGPoint current = self.commentView.center;
    current.y = frame.origin.y - (self.commentView.layer.frame.size.height /2);
    self.commentView.center = current;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat height = MAX(MIN(textView.contentSize.height - kInputLineSpacing, kMaxInputHeight), kMinInputHeight);
    [self updateCommentSize:height];
    debug NSLog(@"H: %f / %f", height, textView.contentSize.height);
}

- (void)updateCommentSize:(CGFloat)height {
    self.sendButton.enabled = ([[self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0);

    CGRect textFrame = self.textView.frame;
    textFrame.size.height = height;
    self.textView.frame = textFrame;

    CGFloat bottom = [UIScreen mainScreen].bounds.size.height;
    if (self.currentKeyboardView) {
        bottom = self.currentKeyboardView.frame.origin.y;
    }

    CGRect commentFrame = self.commentView.frame;
    commentFrame.size.height = textFrame.size.height + 14;
    commentFrame.origin.y = bottom - (height + 14);
    self.commentView.frame = commentFrame;

    CGRect tableFrame = self.tableView.layer.frame;
    tableFrame.size.height = bottom - height - 14;
    self.tableView.frame = tableFrame;

    CGRect buttonFrame = self.sendButton.frame;
    buttonFrame.origin.y = self.commentView.layer.frame.size.height - buttonFrame.size.height;
    self.sendButton.frame = buttonFrame;

    [self.view layoutSubviews];
}

#pragma mark - Commenting

- (IBAction)sendButtonPressed:(id)sender {
    NSString *body = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([body length] > 0 && self.post && self.post.postId) {
        self.cachedText = body;
        self.textView.text = @"";
        [self updateCommentSize:kMinInputHeight];

        TDComment *newComment = [[TDComment alloc] initWithUser:[[TDCurrentUser sharedInstance] currentUserObject]
                                                           body:body
                                                      createdAt:[NSDate date]];
        [self.post addComment:newComment];

        [self.tableView reloadData];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: (2 + [self.post.comments count]) - 1 inSection: 0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:NO];

        [self.textView resignFirstResponder];

        [[TDCurrentUser sharedInstance] registerForPushNotifications:@"Would you like to be notified of future replies?"];

        [self tellDelegateToUpdateThisPost];

        [[TDPostAPI sharedInstance] postNewComment:body forPost:self.post.postId];
    }
}

- (void)newCommentFailed:(NSNotification*)notification {
    [self.post removeLastComment]; // Naive but will work unless commenter goes crazy during outage
    [self.tableView reloadData];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Something went wrong while saving your comment. Please try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    self.textView.text = self.cachedText;
    self.cachedText = nil;
    self.sendButton.enabled = YES;
}

#pragma mark - NSLayoutManagerDelegate

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    return kInputLineSpacing;
}

@end
