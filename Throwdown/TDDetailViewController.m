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
#import "TDCreatePostViewController.h"
#import "TDHomeViewController.h"

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
@property (weak, nonatomic) IBOutlet UIView *editingView;
@property (weak, nonatomic) IBOutlet UIPlaceHolderTextView *editingTextView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIView *editingTopLineView;

@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) CGFloat minLikeheight;
@property (nonatomic) BOOL liking;
@property (nonatomic) BOOL allowMuting;  //used for internal purposes if the user goes back and forth before pressing yes
@property (nonatomic) BOOL isEditing;
@property (nonatomic) BOOL isEditingOriginalPost;
@property (nonatomic) BOOL loaded;
@property (nonatomic) NSString *cachedText;
@property (nonatomic) TDUserListView *userListView;
@property (nonatomic) TDActivityIndicator *activityIndicator;
@property (nonatomic) TDKeyboardObserver *keyboardObserver;
@property (nonatomic) UIBarButtonItem *dotBarItem;
@property (nonatomic) NSInteger editingCommentNumber;
@property (nonatomic) NSInteger actionSheetIdx;
@property (nonatomic) NSMutableDictionary *actionSheetKey;
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

    // Typing Bottom
    CGRect editingTextFrame = self.editingTextView.frame;
    editingTextFrame.size.width = SCREEN_WIDTH - 10 - 10;
    self.editingTextView.font = [TDConstants fontRegularSized:17];
    self.editingTextView.frame = editingTextFrame;
    self.editingTextView.delegate = self;
    self.editingTextView.clipsToBounds = YES;
    self.editingTextView.layoutManager.delegate = self;
    self.editingTextView.layer.cornerRadius = 4;
    self.editingTextView.layer.borderWidth = (1.0 / [[UIScreen mainScreen] scale]);
    self.editingTextView.layer.borderColor = [UIColor colorWithRed:178./255. green:178./255. blue:178./255. alpha:1].CGColor;
    self.editingTextView.contentInset = UIEdgeInsetsMake(0, 0, -10, 0);
    self.editingTextView.placeholder = kCommentDefaultText;
    self.editingTextView.scrollsToTop = NO;

    //self.saveButton.center = CGPointMake(SCREEN_WIDTH - self.sendButton.frame.size.width / 2.0, self.sendButton.center.y);
    self.cancelButton.titleLabel.font = [TDConstants fontRegularSized:17.];
    self.cancelButton.enabled = NO;
    [self.cancelButton sizeToFit];

    //self.saveButton.center = CGPointMake(SCREEN_WIDTH - self.sendButton.frame.size.width / 2.0, self.sendButton.center.y);
    self.saveButton.titleLabel.font = [TDConstants fontSemiBoldSized:17.];
    self.saveButton.enabled = NO;
    [self.saveButton sizeToFit];

    self.editingTopLineView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 1.0 / [[UIScreen mainScreen] scale]);

    CGRect editingFrame = self.editingView.frame;
    editingFrame.size.width = SCREEN_WIDTH;
    self.editingView.frame = editingFrame;
    self.editingView.layer.borderColor = [[UIColor purpleColor] CGColor];
    self.editingView.layer.borderWidth = 2.0;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCommentFailed:) name:TDNotificationUpdateCommentFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostCommentFailed:) name:TDNotificationUpdatePostCommentFailed object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];

    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];

    self.actionSheetIdx = 0;
    self.actionSheetKey = [[NSMutableDictionary alloc] init];
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
    if (self.isEditingOriginalPost) {
        [self.editingView resignFirstResponder];
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
        self.actionSheetIdx = 0;
        reportText = @"Delete";
        [self.actionSheetKey setValue:[NSNumber numberWithInt:TDDeletePost] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];

    } else {
        self.actionSheetIdx = 0;
        reportText = @"Report as Inappropriate";
        [self.actionSheetKey setValue:[NSNumber numberWithInt:TDReportInappropriate] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];
    }


    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:nil /* don't set Cancel title here! */
                                                destructiveButtonTitle:reportText
                                                     otherButtonTitles:nil];

    if ([self.post.user.userId isEqualToNumber:[[TDCurrentUser sharedInstance] currentUserObject].userId]) {
        self.actionSheetIdx++;
        NSString *editPost = @"Edit";
        [self.actionSheetKey setValue:[NSNumber numberWithInt:TDEditPost] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];

        [actionSheet addButtonWithTitle:editPost];
    }

    NSString *muteUserText;
    if (self.post.visibility == TDPostSemiPrivate) {
        if (![[TDCurrentUser sharedInstance].userId isEqual:self.post.user.userId]) {
            self.actionSheetIdx++;
            if (self.post.mutedUser) {
                muteUserText = [NSString stringWithFormat:@"%@%@", @"Unmute @", self.post.user.username];
                [self.actionSheetKey setValue:[NSNumber numberWithInt:TDUnmuteUser] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];
            } else {
                muteUserText = [NSString stringWithFormat:@"%@%@", @"Mute @", self.post.user.username];
                [self.actionSheetKey setValue:[NSNumber numberWithInt:TDMuteUser] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];
            }
            [actionSheet addButtonWithTitle:muteUserText];
        }
    }

    NSString *unfollowText;
    if (self.allowMuting || self.post.unfollowed) {
        self.actionSheetIdx++;
        if (self.post.unfollowed) {
            unfollowText = @"Unmute this post";
            [self.actionSheetKey setValue:[NSNumber numberWithInt:TDUnmutePost] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];
        } else {
            unfollowText = @"Mute this post";
            [self.actionSheetKey setValue:[NSNumber numberWithInt:TDMutePost] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];
        }

        [actionSheet addButtonWithTitle:unfollowText];
    }

    self.actionSheetIdx++;
    [actionSheet addButtonWithTitle:@"Copy Share Link"];
    [self.actionSheetKey setValue:[NSNumber numberWithInt:TDCopyShareLink] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];

    self.actionSheetIdx++;
    // after all other buttons have been added, include Cancel
    [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet setCancelButtonIndex:self.actionSheetIdx];
    [self.actionSheetKey setValue:[NSNumber numberWithInt:TDCancel] forKey:[NSString stringWithFormat:@"%ld", (long)self.actionSheetIdx]];


    if (self.post.slug) {
//        for (NSString *title in actionNames) {
//            debug NSLog(@"adding title =%@", title);
//            [actionSheet addButtonWithTitle:title];
//        }
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
    debug NSLog(@"button index = %ld", (long)buttonIndex);
    NSString *inStr = [NSString stringWithFormat:@"%@",
                       [NSNumber numberWithInteger:buttonIndex]];


    NSNumber *type = [self.actionSheetKey valueForKey:inStr] ;
    debug NSLog(@"type - %@", type);
    switch ([type intValue]) {
        case TDReportInappropriate:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report as Inappropriate?"
                                                  message:@"Please confirm you'd like to report this post as inappropriate."
                                                 delegate:self
                                        cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:@"Report", nil];
            alert.tag = 18890;
            [alert show];
        }
            break;
        case TDDeletePost:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete?"
                                                            message:@"Are you sure you want to\ndelete this post?"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
            alert.tag = 89890;
            [alert show];
        }
        break;
        case TDEditPost:
        {
            debug NSLog(@"NEED TO OPEN CREATEPOSTVIEWCONTROLLER");
            //[self openEditPostView];
        }
        break;
        case TDUnmuteUser:
        {
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
        }
        break;
        case TDMuteUser:
        {
            NSString *muteTitle = [NSString stringWithFormat:@"%@%@", @"Mute @", self.post.user.username];
            NSString *message = [NSString stringWithFormat:@"%@%@%@", @"Muting prevents @", self.post.user.username, @" from sending you direct messages. Are you sure?"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:muteTitle
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Mute", nil];
            alert.tag = 18894;
            [alert show];
        }
        break;
        case TDUnmutePost:
        {
            [[TDPostAPI sharedInstance] followPostWithId:self.post.postId];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"You will now receive notifications for this post, including any mentions."
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            [alert show];
            self.allowMuting = YES;
            [self.post removeUnfollowUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        }
        break;
        case TDMutePost:
        {
            [[TDPostAPI sharedInstance] unfollowPostWithId:self.post.postId];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"You will no longer receive any notifications for this post, including any mentions.  To turn on notifications, please unmute this post."
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            alert.tag = 18892;
            [alert show];
            self.allowMuting = YES;
            [self.post addUnfollowUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        }
        break;
        case TDCopyShareLink:
        {
            // index 1 = Copy Share Link
            [[TDAnalytics sharedInstance] logEvent:@"copied_share_url"];
            [[UIPasteboard generalPasteboard] setString:[TDConstants getShareURL:self.post.slug]];
            [[TDAppDelegate appDelegate] showToastWithText:@"Share link copied to clipboard" type:kToastType_Info payload:nil delegate:nil];
        }
        break;
        case TDCancel:
            break;
    }
}
#pragma mark - UIActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    debug NSLog(@"inside didDismissWithButtonIndex, buttonIndex=%ld", (long)buttonIndex);
    NSString *inStr = [NSString stringWithFormat:@"%@",
                       [NSNumber numberWithInteger:buttonIndex]];


    NSNumber *type = [self.actionSheetKey valueForKey:inStr] ;
    debug NSLog(@"type - %@", type);
    switch ([type intValue]) {
        case TDEditPost:
            debug NSLog(@"  got edit post, show controller");
            [self openEditPostView];
            break;
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
    } else if (alertView.tag == 18894 && buttonIndex != alertView.cancelButtonIndex) {
        //mute
        // Send follow user to server
        [[TDUserAPI sharedInstance] muteUser:self.post.user.userId callback:^(BOOL success) {
            if (success) {
                debug NSLog(@"Successfully muted user=%@, now remove the post from view", self.post.user.username);
                // Notify any view controllers about the removal which will cache the post and refresh table
                [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationRemovePost object:nil userInfo:@{@"postId": self.postId}];
            } else {
                [[TDAppDelegate appDelegate] showToastWithText:@"Error occured.  Please try again." type:kToastType_Warning payload:@{} delegate:nil];
            }
        }];
    }else if (alertView.tag == 18890 && buttonIndex != alertView.cancelButtonIndex) {
        // Report!
        [[TDPostAPI sharedInstance] reportPostWithId:self.postId];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report Sent"
                                                        message:@"Our moderators will review this post within the next 24 hours. Thank you."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else if (alertView.tag == 18891 && buttonIndex != alertView.cancelButtonIndex) {
        // Report comment!
        TDComment *comment = [self.post commentAtIndex:self.editingCommentNumber];
        debug NSLog(@"reporting comment id = %@", comment.commentId);
        [[TDPostAPI sharedInstance] reportCommentWithId:comment.commentId postId:self.postId];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report Sent"
                                                        message:@"Our moderators will review this comment within the next 24 hours. Thank you."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.editingCommentNumber+2 inSection:0];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        self.editingCommentNumber = -1;
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

        [self allowMutingPost];
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
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
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
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }

    NSUInteger commentNumber = (indexPath.row - 2);
    TDComment *comment = [self.post commentAtIndex:commentNumber];
    if (comment) {
        if (comment.user.userId == [TDCurrentUser sharedInstance].userId) {
            self.allowMuting = YES;
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

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > 1) {
        NSInteger commentNumber = indexPath.row -2;
        debug NSLog(@"inside didSelectRowAtIndexPath, commentNumber = %ld, section-%ld", (long)commentNumber, (long)indexPath.section);

        self.editingCommentNumber = commentNumber;

        TDComment *comment = [self.post commentAtIndex:commentNumber];
        debug NSLog(@"comment userid = %@, current userid=%@", comment.user.userId, [TDCurrentUser sharedInstance].userId);
        if ([comment.user.userId isEqualToNumber:[TDCurrentUser sharedInstance].userId]) {

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentDeleted:) name:TDNotificationRemoveComment object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentDeleteFailed:) name:TDNotificationRemoveCommentFailed object:nil];


            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil  message:nil preferredStyle:UIAlertControllerStyleActionSheet];

            UIAlertAction* deleteCommentAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive
                                                                                handler:^(UIAlertAction * action) {
                                                                                    [self presentDeleteCommentAlertView];
                                                                                }];
            UIAlertAction *editCommentAction =[UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault
                                                                        handler:^(UIAlertAction * action) {
                                                                            [self editComment:indexPath.row];

                                                                        }];
            UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                               [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                                                           }];

            [alert addAction:deleteCommentAction];
            [alert addAction:editCommentAction];
            [alert addAction:cancel];
            alert.view.tintColor = [UIColor blueColor];

            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil  message:nil preferredStyle:UIAlertControllerStyleActionSheet];

            UIAlertAction* inappropriateAction = [UIAlertAction actionWithTitle:@"Report as Inappropriate" style:UIAlertActionStyleDestructive
                                                                        handler:^(UIAlertAction * action) {
                                                                            debug NSLog(@"comment id we are reporting is %@", comment.commentId);
                                                                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report as Inappropriate?"
                                                                                                                            message:@"Please confirm you'd like to report this comment as inappropriate."
                                                                                                                           delegate:self
                                                                                                                  cancelButtonTitle:@"Cancel"
                                                                                                                  otherButtonTitles:@"Report", nil];
                                                                            alert.tag = 18891;
                                                                            [alert show];
                                                                        }];
            UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                               [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

                                                           }];

            [alert addAction:inappropriateAction];
            [alert addAction:cancel];
            alert.view.tintColor = [UIColor blueColor];

            [self presentViewController:alert animated:YES completion:nil];

        }
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
    debug NSLog(@"inside keyboardWillShow");
    NSDictionary *info = [notification userInfo];

    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];

    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
    CGFloat keyboardHeight = isPortrait ? keyboardFrame.size.height : keyboardFrame.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;

    NSNumber *curveValue = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    if (self.isEditingOriginalPost) {
        debug NSLog(@"SHOW editing View");
        self.editingView.hidden = NO;
        self.commentView.hidden = YES;
        debug NSLog(@"SCREEN_WIDTH=%f", SCREEN_WIDTH);
        debug NSLog(@"  editingView frame = %@", NSStringFromCGRect(self.editingView.frame));
        debug NSLog(@"  editingTextView frame = %@", NSStringFromCGRect(self.editingTextView.frame));
        debug NSLog(@"  save button frame = %@", NSStringFromCGRect(self.saveButton.frame));
        debug NSLog(@"  cancel button frame = %@", NSStringFromCGRect(self.cancelButton.frame));

        self.editingTextView.layer.borderColor = [[UIColor greenColor] CGColor];
        self.editingTextView.layer.borderWidth = 2.;
        debug NSLog(@"  editingTextView.contentSize=%f", self.editingTextView.contentSize.height);
        CGFloat fixedWidth = self.editingTextView.frame.size.width;
        CGSize newSize = [self.editingTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGRect newFrame = self.editingTextView.frame;
        newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);

        CGFloat height = MAX(MIN(newSize.height - kInputLineSpacing, kMaxInputHeight), kMinInputHeight);
        [self updateEditCommentSize:height];
        debug NSLog(@"   H: %f / %f", height, self.editingTextView.contentSize.height);

        CGFloat bottom = screenHeight - keyboardHeight;

        CGRect textFrame = self.editingTextView.frame;
        textFrame.size.height = height;
        textFrame.origin.y = self.cancelButton.frame.origin.y + self.cancelButton.frame.size.height;

        CGRect editViewFrame = self.editingView.frame;
        editViewFrame.size.height = textFrame.size.height + kCommentFieldPadding + MAX(self.cancelButton.frame.size.height, self.saveButton.frame.size.height);
        editViewFrame.origin.y = bottom - height - kCommentFieldPadding - MAX(self.cancelButton.frame.size.height, self.saveButton.frame.size.height);

        CGRect tableFrame = self.tableView.layer.frame;
        tableFrame.size.height = bottom - height - kCommentFieldPadding - kToolbarHeight;

        CGRect buttonFrame = self.saveButton.frame;
        buttonFrame.origin.y = (5);
        buttonFrame.origin.x = (textFrame.origin.x + textFrame.size.width) - buttonFrame.size.width;

        CGRect cancelButtonFrame = self.cancelButton.frame;
        cancelButtonFrame.origin.y = 5;
        cancelButtonFrame.origin.x = textFrame.origin.x;

        debug NSLog(@"  Animation going to...");
        debug NSLog(@"  editingView frame = %@", NSStringFromCGRect(self.editingView.frame));
        debug NSLog(@"  editingTextView frame = %@", NSStringFromCGRect(self.editingTextView.frame));
        debug NSLog(@"  save button frame = %@", NSStringFromCGRect(self.saveButton.frame));
        debug NSLog(@"  cancel button frame = %@", NSStringFromCGRect(self.cancelButton.frame));
        // animationCurve << 16 to convert it from a view animation curve to a view animation option
        [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{

            self.editingTextView.frame = textFrame;
            self.editingView.frame = editViewFrame;
            self.saveButton.frame = buttonFrame;
            self.cancelButton.frame = cancelButtonFrame;
            self.tableView.frame = tableFrame;
        } completion:nil];

    } else {
        self.commentView.hidden = NO;
        self.editingView.hidden = YES;
        CGFloat height = MAX(MIN(self.textView.contentSize.height, kMaxInputHeight), kMinInputHeight);
        CGFloat bottom = screenHeight - keyboardHeight;
        debug NSLog(@"show comment view...");
        debug NSLog(@"SCREEN_WIDTH=%f", SCREEN_WIDTH);
        debug NSLog(@"  textView frame = %@", NSStringFromCGRect(self.textView.frame));
        debug NSLog(@"  commentVIew frame = %@", NSStringFromCGRect(self.commentView.frame));
        debug NSLog(@"  tableViewFrame = %@", NSStringFromCGRect(self.tableView.frame));
        CGRect textFrame = self.textView.frame;
        textFrame.size.height = height;
    
        CGRect commentFrame = self.commentView.frame;
        commentFrame.size.height = textFrame.size.height + kCommentFieldPadding;
        commentFrame.origin.y = bottom - height - kCommentFieldPadding;

        CGRect tableFrame = self.tableView.layer.frame;
        tableFrame.size.height = bottom - height - kCommentFieldPadding - kToolbarHeight;

        CGRect buttonFrame = self.sendButton.frame;
        buttonFrame.origin.y = (height + kCommentFieldPadding) - buttonFrame.size.height;

        debug NSLog(@"  animation going to...");
        debug NSLog(@"  textView frame = %@", NSStringFromCGRect(self.textView.frame));
        debug NSLog(@"  commentVIew frame = %@", NSStringFromCGRect(self.commentView.frame));
        debug NSLog(@"  tableViewFrame = %@", NSStringFromCGRect(self.tableView.frame));

        // animationCurve << 16 to convert it from a view animation curve to a view animation option
        [UIView animateWithDuration:animationDuration delay:0.0 options:(animationCurve << 16) animations:^{
            self.textView.frame = textFrame;
            self.commentView.frame = commentFrame;
            self.sendButton.frame = buttonFrame;
            self.tableView.frame = tableFrame;
        } completion:nil];
    }
}


#pragma mark - TDKeyboardObserverDelegate

- (void)keyboardDidShow:(NSNotification *)notification {
    debug NSLog(@"inside keyboardDidShow");

    self.isEditing = YES;
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.tableView addGestureRecognizer:self.tapGesture];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationPauseTapGesture object:nil];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    debug NSLog(@"inside keyboardDidHide");
    self.isEditing = NO;
    [self.tableView removeGestureRecognizer:self.tapGesture];
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationResumeTapGesture object:nil];
    self.tapGesture = nil;
}

- (void)keyboardFrameChanged:(CGRect)keyboardFrame {
    debug NSLog(@"inside keyboardFrameChanged");
    if (self.isEditingOriginalPost) {
        CGRect tableFrame = self.tableView.layer.frame;
        tableFrame.size.height = keyboardFrame.origin.y - self.editingView.layer.frame.size.height - kToolbarHeight;
        self.tableView.frame = tableFrame;

        debug NSLog(@"   editingView.layer.frame.size.height=%f", self.editingView.layer.frame.size.height);
        CGPoint current = self.editingView.center;
        current.y = keyboardFrame.origin.y - (self.editingView.layer.frame.size.height / 2) - kToolbarHeight;
        self.editingView.center = current;
        debug NSLog(@"   editingView.center=%@", NSStringFromCGPoint(current));
    } else {
        CGRect tableFrame = self.tableView.layer.frame;
        tableFrame.size.height = keyboardFrame.origin.y - self.commentView.layer.frame.size.height - kToolbarHeight;
        self.tableView.frame = tableFrame;

        debug NSLog(@"   commentView.layer.frame.size.height=%f", self.commentView.layer.frame.size.height);
        CGPoint current = self.commentView.center;
        current.y = keyboardFrame.origin.y - (self.commentView.layer.frame.size.height / 2) - kToolbarHeight;
        self.commentView.center = current;
        debug NSLog(@"   commentView.center=%@", NSStringFromCGPoint(self.commentView.center));
    }
}

- (void)handleTapFrom:(UITapGestureRecognizer *)tap {
    if (!self.userListView.hidden) {
        [self.userListView hideView];
    }

    if (self.isEditing) {
        if (self.isEditingOriginalPost) {
            self.editingCommentNumber = -1;
            [self.editingTextView resignFirstResponder];
        } else {
            [self.textView resignFirstResponder];
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    debug NSLog(@"shouldCHangeTextInRange...");
    return [TDTextViewControllerHelper textView:textView shouldChangeTextInRange:range replacementText:text];
}

- (void)textViewDidChange:(UITextView *)textView {
    debug NSLog(@"text view changing");

    if (self.isEditingOriginalPost) {
        // get the size of the UITextView based on what it would be with the text
        CGFloat fixedWidth = self.editingTextView.frame.size.width;
        CGSize newSize = [self.editingTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        CGRect newFrame = self.editingTextView.frame;
        newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
        CGFloat height = MAX(MIN(newSize.height - kInputLineSpacing, kMaxInputHeight), kMinInputHeight);
        [self updateEditCommentSize:height];

        debug NSLog(@"  H: %f / %f", height, textView.contentSize.height);

        [self.userListView showUserSuggestions:textView callback:^(BOOL success) {
            if (success) {
                // Make sure we do this after updateCommentSize
                [self.userListView updateFrame:CGRectMake(0, 64, SCREEN_WIDTH, self.editingView.frame.origin.y - kToolbarHeight)];
            }
        }];
    } else {
        CGFloat height = MAX(MIN(textView.contentSize.height - kInputLineSpacing, kMaxInputHeight), kMinInputHeight);

        [self updateCommentSize:height];

        debug NSLog(@"H: %f / %f", height, textView.contentSize.height);

        [self.userListView showUserSuggestions:textView callback:^(BOOL success) {
            if (success) {
                // Make sure we do this after updateCommentSize
                debug NSLog(@"    comment view frame = %@", NSStringFromCGRect(self.commentView.frame));
                [self.userListView updateFrame:CGRectMake(0, 64, SCREEN_WIDTH, self.commentView.frame.origin.y - kToolbarHeight)];
                self.userListView.layer.borderColor = [[UIColor redColor] CGColor];
                self.userListView.layer.borderWidth = 2.;
                debug NSLog(@"  user list view frame = %@", NSStringFromCGRect(self.userListView.frame));
            }
        }];
    }
}

- (void)updateCommentSize:(CGFloat)height {
    debug NSLog(@"inside updateCommentSize w/ height-%f", height);
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
    debug NSLog(@"    commentView.frame=%@", NSStringFromCGRect(self.commentView.frame));
    CGRect tableFrame = self.tableView.layer.frame;
    tableFrame.size.height = bottom - height - kCommentFieldPadding;
    self.tableView.frame = tableFrame;

    CGRect buttonFrame = self.sendButton.frame;
    buttonFrame.origin.y = self.commentView.layer.frame.size.height - buttonFrame.size.height;
    self.sendButton.frame = buttonFrame;

    [self.view layoutSubviews];
}

- (void)updateEditCommentSize:(CGFloat)height {
    debug NSLog(@"updating comment size to height=%f", height);

    self.saveButton.enabled = ([[self.editingTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0);
    self.cancelButton.enabled = YES;
    CGRect saveButtonFrame = self.saveButton.frame;
    saveButtonFrame.origin.y = 5;
    self.saveButton.frame = saveButtonFrame;

    CGRect cancelButtonFrame = self.cancelButton.frame;
    cancelButtonFrame.origin.y = 5;
    self.cancelButton.frame = cancelButtonFrame;
    debug NSLog(@"  self.cancelButton frame = %@", NSStringFromCGRect(self.cancelButton.frame));
    debug NSLog(@"  self.saveButton frame = %@", NSStringFromCGRect(self.saveButton.frame));

    CGRect textFrame = self.editingTextView.frame;
    textFrame.size.height = height;
    textFrame.origin.y = self.saveButton.frame.origin.y + self.saveButton.frame.size.height + 5;
    self.editingTextView.frame = textFrame;

    CGFloat bottom = [UIScreen mainScreen].bounds.size.height - kToolbarHeight;
    if (self.keyboardObserver.keyboardView) {
        bottom = self.keyboardObserver.keyboardView.layer.frame.origin.y - kToolbarHeight;
    }
    debug NSLog(@"  bottom = %f", bottom);

    CGRect editingViewFrame = self.editingView.frame;
    editingViewFrame.size.height = textFrame.size.height + kCommentFieldPadding + MAX(self.cancelButton.frame.size.height, self.saveButton.frame.size.height);
    editingViewFrame.origin.y = bottom - height - kCommentFieldPadding - MAX(self.cancelButton.frame.size.height, self.saveButton.frame.size.height);
    self.editingView.frame = editingViewFrame;
    debug NSLog(@"  editingViewFrame is now=%@", NSStringFromCGRect(self.editingView.frame));
    self.editingView.layer.borderColor = [[UIColor purpleColor] CGColor];
    self.editingView.layer.borderWidth = 1.;

    CGRect tableFrame = self.tableView.layer.frame;
    tableFrame.size.height = bottom - height - kCommentFieldPadding;
    self.tableView.frame = tableFrame;
    [self.view layoutSubviews];
}

#pragma mark - Commenting

- (IBAction)sendButtonPressed:(id)sender {
    NSString *body = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    debug NSLog(@"***sendButtonPressed, body=%@", body);
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

- (IBAction)cancelButtonPressed:(id)sender {
    debug NSLog(@"cancel button pressed, reanimate to original view");
    if (!self.userListView.hidden) {
        [self.userListView hideView];
    }

    if (self.isEditingOriginalPost) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.editingCommentNumber+2 inSection:0];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

        self.editingCommentNumber = -1;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: (2 + [self.post.commentsTotalCount intValue])-1 inSection: 0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:NO];
        [self.editingTextView resignFirstResponder];
        self.editingView.hidden = YES;
        self.commentView.hidden = NO;
        self.isEditingOriginalPost = NO;
    }
}

- (IBAction)saveButtonPressed:(id)sender {
    debug NSLog(@"save button pressed, send to backend, updated the text");
    if (self.isEditingOriginalPost) {

        NSString *body = [self.editingTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([body length] > 0 && self.post && self.post.postId) {
            self.cachedText = body;
            self.editingTextView.text = @"";
            [self updateEditCommentSize:kMinInputHeight];

            if (!self.userListView.hidden) {
                [self.userListView hideView];
            }

            if (self.editingCommentNumber != -1) {
                TDComment *updatedComment = [self.post commentAtIndex:self.editingCommentNumber];

                [self.post updateComment:updatedComment text:self.cachedText];

                [self.tableView reloadData];
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: (2 + [self.post.commentsTotalCount intValue])-1 inSection: 0]
                                      atScrollPosition:UITableViewScrollPositionBottom
                                              animated:NO];
                debug NSLog(@"hide keyboard");
                [self.editingTextView resignFirstResponder];
                debug NSLog(@"done hiding");
                [[TDPostAPI sharedInstance] postUpdateComment:body forPost:self.post.postId forComment:updatedComment.commentId];

            } else {
                [self.post updatePostComment:self.post.postId comment:self.cachedText];
    
                [self.tableView reloadData];
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection: 0]
                                      atScrollPosition:UITableViewScrollPositionBottom
                                              animated:NO];
                [self.editingTextView resignFirstResponder];
    
                [[TDPostAPI sharedInstance] updatePostText:body postId:self.post.postId];
            }

            self.editingView.hidden = YES;
            self.commentView.hidden = NO;
            self.isEditingOriginalPost = NO;
        }
    }
}

- (void)updatePost:(NSNotification *)n {
    debug NSLog(@"inside updatePost");
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

- (void)updateCommentFailed:(NSNotification*)notification {
    //[self.post removeLastComment]; // Naive but will work unless commenter goes crazy during outage
    [self.tableView reloadData];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Something went wrong while updating your comment. Please try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    self.editingTextView.text = self.cachedText;
    self.cachedText = nil;
    self.saveButton.enabled = YES;
}

- (void)updatePostCommentFailed:(NSNotification*)notification {
    //[self.post removeLastComment]; // Naive but will work unless commenter goes crazy during outage
    [self.tableView reloadData];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Something went wrong while updating your comment. Please try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    //self.editingTextView.text = self.cachedText;
    //self.cachedText = nil;
    self.saveButton.enabled = YES;
}
#pragma mark - NSLayoutManagerDelegate

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    return kInputLineSpacing;
}

#pragma mark - TDUserListViewControllerDelegate

- (void)selectedUser:(NSDictionary *)user forUserNameFilter:(NSString *)userNameFilter {
    if (self.isEditingOriginalPost) {
        NSString *currentText = self.editingTextView.text;
        NSString *userName = [[user objectForKey:@"username"] stringByAppendingString:@" "];
        debug NSLog(@"concatenate with %@", userName);
        NSString *newText = [currentText substringToIndex:(currentText.length-userNameFilter.length)];

        self.editingTextView.text = [newText stringByAppendingString:userName];
    } else {
        NSString *currentText = self.textView.text;
        NSString *userName = [[user objectForKey:@"username"] stringByAppendingString:@" "];
        debug NSLog(@"concatenate with %@", userName);
        NSString *newText = [currentText substringToIndex:(currentText.length-userNameFilter.length)];

        self.textView.text = [newText stringByAppendingString:userName];
    }
}

#pragma mark - UIAlertViewController
- (void)presentDeleteCommentAlertView {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.editingCommentNumber+2 inSection:0];

    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Delete this comment?"
                                          message:@"Please confirm you'd like to delete this comment."
                                          preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                       [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                                   }];

    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                                   [self deleteComment];
                               }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    alertController.view.tintColor = [TDConstants headerTextColor];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteComment {
    TDComment *comment = [self.post commentAtIndex:self.editingCommentNumber];

    [[TDPostAPI sharedInstance] postDeleteComment:comment.commentId forPost:self.postId];
}

- (void)editComment:(NSInteger)commentRow {
    debug NSLog(@"inside edit Comment");
    self.isEditingOriginalPost = YES;

    NSUInteger commentNumber = (commentRow - 2);
    TDComment *comment = [self.post commentAtIndex:commentNumber];
    [self.editingTextView insertText:comment.body];
    [self.editingTextView becomeFirstResponder];
}


- (void)commentDeleted:(NSNotification*)notification {
    
    debug NSLog(@"inside comment deleted, commentId-%@", [notification.userInfo objectForKey:@"commentId"]);

    [self.post removeComment:[notification.userInfo objectForKey:@"commentId"]];

    [self.tableView reloadData];
}

- (void)commentDeleteFailed:(NSNotification*)notification {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.activityIndicator.hidden = YES;
    [[[UIAlertView alloc] initWithTitle:@"Delete failed" message:@"Sorry, there was a problem communicating with the server. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)allowMutingPost {
    debug NSLog(@"inside allowMutingPost");
    if ([self.post.user.userId isEqual:[TDCurrentUser sharedInstance].userId]) {
        self.allowMuting = YES;
    }

    if (self.post.liked) {
        // The user liked this
        self.allowMuting = YES;
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",[TDCurrentUser sharedInstance].username]; // if you need case sensitive search avoid '[c]' in the predicate

    NSArray *results = [self.post.mentions filteredArrayUsingPredicate:predicate];
    if (results.count > 0) {
        self.allowMuting = YES;
    }
}

- (void)openEditPostView {
    debug NSLog(@"inside openEditPostView");
    self.editingTextView.text = self.post.comment;
    self.isEditingOriginalPost = YES;
    self.editingCommentNumber = -1;
    [self.editingTextView becomeFirstResponder];
}

@end
