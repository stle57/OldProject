//
//  TDDetailViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDDetailViewController.h"
#import "TDTextViewControllerHelper.h"
#import "TDPostAPI.h"
#import "TDAPIClient.h"
#import "TDConstants.h"
#import "TDComment.h"
#import "TDViewControllerHelper.h"
#import "AFNetworking.h"
#import "TDUserProfileViewController.h"
#import "TDAnalytics.h"
#import "UIPlaceHolderTextView.h"
#import "TDUserListView.h"
#import "TDActivityIndicator.h"
#import "TDKeyboardObserver.h"
#import "TDLocationFeedViewController.h"
#import "TDTagFeedViewController.h"
#import "TDUserAPI.h"

static float const kInputLineSpacing = 3;
static float const kMinInputHeight = 33.;
static float const kMaxInputHeight = 100.;
static int const kCommentFieldPadding = 14;
static int const kToolbarHeight = 64;

@interface TDDetailViewController () <UITextViewDelegate, NSLayoutManagerDelegate, TDKeyboardObserverDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *commentView;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIView *topLineView;

@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) CGFloat minLikeheight;
@property (nonatomic) BOOL liking;
@property (nonatomic) BOOL allowMuting;  //used for internal purposes if the user goes back and forth before pressing yes
@property (nonatomic) BOOL isEditing;
@property (nonatomic) BOOL loaded;
@property (nonatomic) NSString *cachedText;
@property (nonatomic) TDUserListView *userListView;
@property (nonatomic) TDActivityIndicator *activityIndicator;
@property (nonatomic) TDKeyboardObserver *keyboardObserver;
@property (nonatomic) UIBarButtonItem *dotBarItem;
@end

@implementation TDDetailViewController

- (void)dealloc {
    self.post = nil;
    self.postId = nil;
    self.slug = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.textView.delegate = nil;
    self.userListView = nil;
    [self.keyboardObserver stopListening];
    self.keyboardObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Title
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [TDConstants fontSemiBoldSized:18];
    [self.navigationItem setTitleView:self.titleLabel];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;

    UIButton *backButton = [TDViewControllerHelper navBackButton];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

    // Delete or report icon - have to use uibutton to give design's hit state correctly
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setFrame:CGRectMake(0.0, 0.0, 20, 21)];
    [rightButton setImage:[UIImage imageNamed:@"dots"] forState:UIControlStateNormal];
    [rightButton setImage:[UIImage imageNamed:@"dots-hit"] forState:UIControlStateHighlighted];
    [rightButton addTarget:self action:@selector(reportButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *deleteBarButton = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = deleteBarButton;

    // Cell heights
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDDetailsLikesCell" owner:self options:nil];
    TDDetailsLikesCell *cell1 = [topLevelObjects objectAtIndex:0];
    self.minLikeheight = cell1.frame.size.height;
    cell1 = nil;

    // Typing Bottom
    CGRect textFrame = self.textView.frame;
    textFrame.size.width = SCREEN_WIDTH - 10 - 60;
    self.textView.font = [TDConstants fontRegularSized:17];
    self.textView.frame = textFrame;
    self.textView.delegate = self;
    self.textView.clipsToBounds = YES;
    self.textView.layoutManager.delegate = self;
    self.textView.layer.cornerRadius = 4;
    self.textView.layer.borderWidth = (1.0 / [[UIScreen mainScreen] scale]);
    self.textView.layer.borderColor = [UIColor colorWithRed:178./255. green:178./255. blue:178./255. alpha:1].CGColor;
    self.textView.contentInset = UIEdgeInsetsMake(0, 0, -10, 0);
    self.textView.placeholder = kCommentDefaultText;
    self.textView.scrollsToTop = NO;

    self.tableView.scrollsToTop = YES;

    self.sendButton.center = CGPointMake(SCREEN_WIDTH - self.sendButton.frame.size.width / 2.0, self.sendButton.center.y);
    self.sendButton.titleLabel.font = [TDConstants fontSemiBoldSized:18.];
    self.sendButton.enabled = NO;
    self.topLineView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 1.0 / [[UIScreen mainScreen] scale]);

    CGRect commentFrame = self.commentView.frame;
    commentFrame.size.width = SCREEN_WIDTH;
    self.commentView.frame = commentFrame;

    // User name filter table view
    if (self.userListView == nil) {
        self.userListView = [[TDUserListView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, self.commentView.frame.origin.y)];
        // Set this delegate so that data comes back to this controller.
        self.userListView.delegate = self;
        [self.view addSubview:self.userListView];
    }

    self.loaded = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePost:) name:TDNotificationUpdatePost object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCommentFailed:) name:TDNotificationNewCommentFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];

    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.keyboardObserver startListening];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    CGFloat height = [UIScreen mainScreen].bounds.size.height - self.commentView.layer.frame.size.height;
    self.tableView.frame = CGRectMake(0, 0, SCREEN_WIDTH, height - kToolbarHeight);

    if (!self.loaded) {
        if (self.post && self.post.postId) {
            self.postId = self.post.postId;
        } else if (!self.post) {
            self.post = [[TDPost alloc] init];
        }
        NSString *identifier = self.postId ? [self.postId stringValue] : self.slug;
        [[TDPostAPI sharedInstance] getFullPostInfoForPost:identifier success:^(NSDictionary *response) {
            [self fullPostReturn:response];
        } error:^{
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.isEditing) {
        [self.textView resignFirstResponder];
    }
    [self.keyboardObserver stopListening];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
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

    NSString *muteUserText;
    if (self.post.visibility == TDPostSemiPrivate) {
        if (self.post.mutedUser) {
            muteUserText = [NSString stringWithFormat:@"%@%@", @"Unmute @", self.post.user.username];
        } else {
            muteUserText = [NSString stringWithFormat:@"%@%@", @"Mute @", self.post.user.username];
        }
    }

    NSString *unfollowText;
    if (self.allowMuting || self.post.unfollowed) {
        if (self.post.unfollowed) {
            unfollowText = @"Unmute this post";
        } else {
            unfollowText = @"Mute this post";
        }
    }

    UIActionSheet *actionSheet;
    if (self.post.slug) {
        if (self.post.visibility == TDPostSemiPrivate) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:@"Cancel"
                                        destructiveButtonTitle:reportText
                                             otherButtonTitles:muteUserText, @"Copy Share Link", nil];

        } else if (self.post.unfollowed || self.allowMuting) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:@"Cancel"
                                        destructiveButtonTitle:reportText
                                             otherButtonTitles:unfollowText, @"Copy Share Link", nil];
        } else {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:@"Cancel"
                                        destructiveButtonTitle:reportText
                                             otherButtonTitles:@"Copy Share Link", nil];
        }
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
    } else if (buttonIndex == 1) {
        if (self.post.visibility == TDPostSemiPrivate) {
            if (self.post.mutedUser) {
                //unmute
                // Send unfollow user to server
                [[TDUserAPI sharedInstance] unmuteUser:self.post.user.userId callback:^(BOOL success) {
                    if (success) {
                        debug NSLog(@"Successfully unfollwed user=%@", self.post.user.userId);
                    } else {
                        debug NSLog(@"could not unmute user=%@", self.post.user.userId);
                        [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
                        debug NSLog(@"could not unmute user=%@", self.post.user.userId);
                    }
                }];
            } else {
                //mute
                // Send follow user to server
                [[TDUserAPI sharedInstance] muteUser:self.post.user.userId callback:^(BOOL success) {
                    if (success) {
                    } else {
                        [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
                    }
                }];
            }
        } else {
            debug NSLog(@"unfollow button hit");
            if (self.post.unfollowed) {
                [[TDPostAPI sharedInstance] followPostWithId:self.post.postId];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"You will now receive notifications for this post, including any mentions."
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                [alert show];
                self.allowMuting = YES;
                [self.post removeUnfollowUser:[[TDCurrentUser sharedInstance] currentUserObject]];
            } else {
                [[TDPostAPI sharedInstance] unfollowPostWithId:self.post.postId];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                message:@"You will no longer receive any notifications for this post, including any mentions.  To turn on notifications, please follow this post again."
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                alert.tag = 18891;
                [alert show];
                self.allowMuting = YES;
                [self.post addUnfollowUser:[[TDCurrentUser sharedInstance] currentUserObject]];
            }
        }

    }else if (buttonIndex != actionSheet.cancelButtonIndex) {
        // index 1 = Copy Share Link
        [[TDAnalytics sharedInstance] logEvent:@"copied_share_url"];
        [[UIPasteboard generalPasteboard] setString:[TDConstants getShareURL:self.post.slug]];
        [[TDAppDelegate appDelegate] showToastWithText:@"Share link copied to clipboard" type:kToastType_Info payload:nil delegate:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    // Delete Yes is index 0
    if (alertView.tag == 89890 && buttonIndex != alertView.cancelButtonIndex) {
        self.navigationItem.rightBarButtonItem.enabled = NO;

        // Delete from server Server
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:TDNotificationRemovePost object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleteFailed:) name:TDNotificationRemovePostFailed object:nil];

        self.activityIndicator = [[TDActivityIndicator alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.activityIndicator.center = [TDViewControllerHelper centerPosition];
        
        CGPoint centerFrame = self.activityIndicator.center;
        centerFrame.y = self.activityIndicator.center.y - self.activityIndicator.backgroundView.frame.size.height/2;
        self.activityIndicator.center = centerFrame;
        
        self.activityIndicator.hidden = NO;
        self.activityIndicator.text.text = @"Removing post";
        [self.view addSubview:self.activityIndicator];
        [self.view bringSubviewToFront:self.activityIndicator];
        [self.activityIndicator startSpinner];

        self.navigationItem.rightBarButtonItem.enabled = NO;
        [[TDPostAPI sharedInstance] deletePostWithId:self.postId isPR:self.post.personalRecord];
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

- (void)reloadPosts {
    if (!self.liking) {
        [[TDPostAPI sharedInstance] getFullPostInfoForPost:[self.postId stringValue] success:^(NSDictionary *response) {
            [self fullPostReturn:response];
        } error:^{
            [[TDAppDelegate appDelegate] showToastWithText:@"Network Connection Error" type:kToastType_Warning payload:@{} delegate:nil];
        }];
    }
    self.liking = NO;
}

- (void)fullPostReturn:(NSDictionary *)post {
    self.loaded = YES;
    TDPost *newPost = [[TDPost alloc] initWithDictionary:post];
    if ((self.postId && [newPost.postId isEqualToNumber:self.postId]) || (self.slug && ([newPost.slug isEqualToString:self.slug] || [[newPost.postId stringValue] isEqualToString:self.slug]))) {
        [self.post loadUpFromDict:post];
        self.postId = self.post.postId;
        [self.tableView reloadData];
    }
}

- (void)postDeleted:(NSNotification*)notification {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];
    [self back];
}

- (void)postDeleteFailed:(NSNotification*)notification {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.activityIndicator.hidden = YES;
    [[[UIAlertView alloc] initWithTitle:@"Delete failed" message:@"Sorry, there was a problem communicating with the server. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - TableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.loaded ? (2 + [self.post.commentsTotalCount intValue]) : 0;   // PostView, Like Cell, + Comments.count
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
        [cell setPost:self.post showDate:YES];
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
        if (self.post.liked) {
            // The user liked this
            self.allowMuting = YES;
        } else {
            self.allowMuting = NO;
        }

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

    NSUInteger commentNumber = (indexPath.row - 2);
    TDComment *comment = [self.post commentAtIndex:commentNumber];
    if (comment) {
        if (comment.user.userId == [TDCurrentUser sharedInstance].userId) {
            self.allowMuting = YES;
        } else {
            self.allowMuting = NO;
        }

        cell.commentNumber = commentNumber;
        [cell updateWithComment:comment showIcon:(commentNumber == 0) showDate:YES];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loaded) {
        return 0;
    }

    // Post
    if (indexPath.row == 0) {
        // Adding 5 for margin between like button, if there are no comments (if there are comments 5 is already added in the method)
        CGFloat height = [TDPostView heightForPost:self.post];
        height += (self.loaded && [self.post.commentsTotalCount intValue]) > 0 ? 0 : 5;
        return height;
    }

    // Likes row
    if (indexPath.row == 1) {
        if ([self.post.likers count] == 0) {
            return self.minLikeheight;    // at least one row to show the like button
        } else {
            CGFloat textHeight = [TDDetailsLikesCell heightOfLikersLabel:self.post.likers];
            // 1 row ~= 19, 2 rows ~= 38 (38 < 49 (min height) so it wouldn't add the proper amount of padding.
            textHeight = (textHeight < 25 ? self.minLikeheight : textHeight + 25);
            return textHeight;
        }
    }

    // Comments
    // A comment is at least 40+height for the message text
    TDComment *comment = [self.post commentAtIndex:(indexPath.row - 2)];
    if (comment) {
        // Last one?
        if ((indexPath.row - 2) == ([self.post.commentsTotalCount intValue] - 1)) {
            return kCommentCellUserHeight + kCommentLastPaddingDetail + comment.messageHeight;
        }
        return kCommentCellUserHeight + kCommentPadding + comment.messageHeight;
    } else {
        return 0;
    }
}

#pragma mark - TDDetailsLikesCell Delegates

- (void)likeButtonPressedFromLikes {
    if (self.post.postId) {
        self.liking = YES;
        [self.post addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self updateAllRowsExceptTopOne];
        [[TDPostAPI sharedInstance] likePostWithId:self.post.postId];
    }
}

- (void)unLikeButtonPressedFromLikes {
    debug NSLog(@"TDDetailViewController-unLikeButtonPressedLikes");
    if (self.post.postId) {
        self.liking = YES;
        [self.post removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self updateAllRowsExceptTopOne];

        [[TDPostAPI sharedInstance] unLikePostWithId:self.post.postId];
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

#pragma mark - TDPostViewDelegate

- (void)userButtonPressedFromRow:(NSInteger)row {
    // Because we're on the detail page the only user available is the post's user
    [self showUserProfile:self.post.user.userId];
}

- (void)locationButtonPressedFromRow:(NSInteger)row {
    if (self.post && self.post.locationId) {
        TDLocationFeedViewController *vc = [[TDLocationFeedViewController alloc] initWithNibName:@"TDLocationFeedViewController" bundle:nil];
        vc.locationId = self.post.locationId;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)horizontalScrollingStarted {
    self.tableView.scrollEnabled = NO;
}

- (void)horizontalScrollingEnded {
    self.tableView.scrollEnabled = YES;
}

#pragma mark - TDPostViewDelegate and TDDetailsCommentsCellDelegate

- (void)userTappedURL:(NSURL *)url {
    if ([[url host] isEqualToString:@"user"]) {
        [self showUserProfile:[NSNumber numberWithInteger:[[[url path] lastPathComponent] integerValue]]];
    } else if ([[url host] isEqualToString:@"tag"]) {
        TDTagFeedViewController *vc = [[TDTagFeedViewController alloc] initWithNibName:@"TDTagFeedViewController" bundle:nil ];
        vc.tagName = [[url path] lastPathComponent];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - TDDetailsCommentsCellDelegate

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
    debug NSLog(@"detail-userButtonPressedFromRow:%ld commentNumber:%ld, %@ %@", (long)row, (long)commentNumber, self.post.user.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);

    if ([self.post.commentsTotalCount intValue] > row) {
        TDComment *comment = [self.post commentAtIndex:commentNumber];
        if (comment) {
            [self showUserProfile:comment.user.userId];
        }
    }
}

- (void)showUserProfile:(NSNumber *)userId {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.userId = userId;
    vc.profileType = kFeedProfileTypeOther;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Update Posts After User Change Notification
- (void)updatePostsAfterUserUpdate:(NSNotification *)notification {
    [self.post updateUserInfoFor:[[TDCurrentUser sharedInstance] currentUserObject]];
    [self.tableView reloadData];
}

#pragma mark - support unwinding on push notification

- (void)unwindToRoot {
    debug NSLog(@"unwind from detail view");
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - Keyboard / TextView management

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


    CGFloat height = MAX(MIN(self.textView.contentSize.height, kMaxInputHeight), kMinInputHeight);
    CGFloat bottom = screenHeight - keyboardHeight;

    CGRect textFrame = self.textView.frame;
    textFrame.size.height = height;

    CGRect commentFrame = self.commentView.frame;
    commentFrame.size.height = textFrame.size.height + kCommentFieldPadding;
    commentFrame.origin.y = bottom - height - kCommentFieldPadding;

    CGRect tableFrame = self.tableView.layer.frame;
    tableFrame.size.height = bottom - height - kCommentFieldPadding - kToolbarHeight;

    CGRect buttonFrame = self.sendButton.frame;
    buttonFrame.origin.y = (height + kCommentFieldPadding) - buttonFrame.size.height;

    // animationCurve << 16 to convert it from a view animation curve to a view animation option
    [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{
        self.textView.frame = textFrame;
        self.commentView.frame = commentFrame;
        self.sendButton.frame = buttonFrame;
        self.tableView.frame = tableFrame;
    } completion:nil];
}


#pragma mark - TDKeyboardObserverDelegate

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
}

- (void)keyboardFrameChanged:(CGRect)keyboardFrame {
    CGRect tableFrame = self.tableView.layer.frame;
    tableFrame.size.height = keyboardFrame.origin.y - self.commentView.layer.frame.size.height - kToolbarHeight;
    self.tableView.frame = tableFrame;

    CGPoint current = self.commentView.center;
    current.y = keyboardFrame.origin.y - (self.commentView.layer.frame.size.height / 2) - kToolbarHeight;
    self.commentView.center = current;
}

- (void)handleTapFrom:(UITapGestureRecognizer *)tap {
    if (self.isEditing) {
        [self.textView resignFirstResponder];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return [TDTextViewControllerHelper textView:textView shouldChangeTextInRange:range replacementText:text];
}

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat height = MAX(MIN(textView.contentSize.height - kInputLineSpacing, kMaxInputHeight), kMinInputHeight);
    [self updateCommentSize:height];
    debug NSLog(@"H: %f / %f", height, textView.contentSize.height);

    [self.userListView showUserSuggestions:textView callback:^(BOOL success) {
        if (success) {
            // Make sure we do this after updateCommentSize
            [self.userListView updateFrame:CGRectMake(0, 64, SCREEN_WIDTH, self.commentView.frame.origin.y - kToolbarHeight)];
        }
    }];
}

- (void)updateCommentSize:(CGFloat)height {
    self.sendButton.enabled = ([[self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0);

    CGRect textFrame = self.textView.frame;
    textFrame.size.height = height;
    self.textView.frame = textFrame;

    CGFloat bottom = [UIScreen mainScreen].bounds.size.height - kToolbarHeight;
    if (self.keyboardObserver.keyboardView) {
        bottom = self.keyboardObserver.keyboardView.layer.frame.origin.y - kToolbarHeight;
    }

    CGRect commentFrame = self.commentView.frame;
    commentFrame.size.height = textFrame.size.height + kCommentFieldPadding;
    commentFrame.origin.y = bottom - height - kCommentFieldPadding;
    self.commentView.frame = commentFrame;

    CGRect tableFrame = self.tableView.layer.frame;
    tableFrame.size.height = bottom - height - kCommentFieldPadding;
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
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: (2 + [self.post.commentsTotalCount intValue]) - 1 inSection: 0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:NO];

        [self.textView resignFirstResponder];

        BOOL asked = [[TDCurrentUser sharedInstance] registerForPushNotifications:@"Thanks for making a comment!\nWe'd like to notify you when someone replies. But, we'd like to ask you first. On the next\nscreen, please tap \"OK\" to give\n us permission."];
        if (!asked && [[iRate sharedInstance] shouldPromptForRating]) {
            [[iRate sharedInstance] promptIfNetworkAvailable];
        }

        [[TDPostAPI sharedInstance] postNewComment:body forPost:self.post.postId];
    }
}

- (void)updatePost:(NSNotification *)n {
    if (self.liking) {
        self.liking = NO;
        return;
    }
    NSNumber *postId = (NSNumber *)[n.userInfo objectForKey:@"postId"];
    if ([self.post.postId isEqualToNumber:postId]) {
        [self.post updateFromNotification:n];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadPosts];
        });
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

#pragma mark - TDUserListViewControllerDelegate

- (void)selectedUser:(NSDictionary *)user forUserNameFilter:(NSString *)userNameFilter {
    NSString *currentText = self.textView.text;
    NSString *userName = [[user objectForKey:@"username"] stringByAppendingString:@" "];
    debug NSLog(@"concatenate with %@", userName);
    NSString *newText = [currentText substringToIndex:(currentText.length-userNameFilter.length)];

    self.textView.text = [newText stringByAppendingString:userName];
}

@end
