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

@implementation TDDetailViewController

@synthesize delegate;
@synthesize post;
@synthesize typingView;
@synthesize frostedViewWhileTyping;

- (void)dealloc
{
    delegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TDRefreshPostsNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:FULL_POST_INFO_NOTIFICATION
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NEW_COMMENT_INFO_NOTICIATION
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:POST_DELETED_NOTIFICATION
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:POST_DELETED_FAIL_NOTIFICATION
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TDUpdateWithUserChangeNotification
                                                  object:nil];

    self.post = nil;
    self.typingView = nil;
    self.frostedViewWhileTyping = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Stop any current playbacks
    [[NSNotificationCenter defaultCenter] postNotificationName:TDNotificationStopPlayers object:nil];

    // Title
    self.titleLabel.textColor = [TDConstants headerTextColor];
    [self.navigationItem setTitleView:self.titleLabel];

    // Frosted View for while we're typing to stop video playing
    self.frostedViewWhileTyping = [[UIView alloc] initWithFrame:CGRectMake(0.0,
                                                                           0.0,
                                                                           self.view.frame.size.width,
                                                                           self.view.frame.size.height)];
    self.frostedViewWhileTyping.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.frostedViewWhileTyping];
    self.frostedViewWhileTyping.hidden = YES;

    UIButton *backButton = [TDViewControllerHelper navBackButton];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = barButton;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;

    // Cell heights
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_POST_VIEW owner:self options:nil];
    TDPostView *cell = [topLevelObjects objectAtIndex:0];
    postViewHeight = cell.frame.size.height;
    postCommentViewHeight = cell.likeView.frame.size.height;
    cell = nil;
    topLevelObjects = nil;
    topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDDetailsLikesCell" owner:self options:nil];
    TDDetailsLikesCell *cell1 = [topLevelObjects objectAtIndex:0];
    minLikeheight = cell1.frame.size.height;
    cell1 = nil;

    // Typing Bottom
    self.typingView = [[TDTypingView alloc] initWithFrame:CGRectMake(0.0,
                                                                    [UIScreen mainScreen].bounds.size.height-[TDTypingView typingHeight],
                                                                    self.view.frame.size.width,
                                                                    [TDTypingView typingHeight])];
    self.typingView.delegate = self;
    [self.view insertSubview:self.typingView aboveSubview:self.tableView];
    origTypingViewCenter = self.typingView.center;

    // Adjust tableView and frosted
    CGRect frame = self.tableView.frame;
    frame.size.height -= [TDTypingView typingHeight];
    self.tableView.frame = frame;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPosts:) name:TDRefreshPostsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullPostReturn:) name:FULL_POST_INFO_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCommentReturn:) name:NEW_COMMENT_INFO_NOTICIATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:POST_DELETED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleteFail:) name:POST_DELETED_FAIL_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAfterUserUpdate:) name:TDUpdateWithUserChangeNotification object:nil];

    // Delete Icon - have to use uibutton to give design's hit state correctly
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *trashImage = [UIImage imageNamed:@"nav_trash"];
    [deleteButton setImage:trashImage
                  forState:UIControlStateNormal];
    [deleteButton setFrame:CGRectMake(0.0,
                                      0.0,
                                      trashImage.size.width,
                                      trashImage.size.height)];
    deleteButton.hidden = YES;
    trashImage = nil;
    trashImage = [UIImage imageNamed:@"nav_trash_hit"];
    [deleteButton setImage:trashImage
                  forState:UIControlStateSelected];
    trashImage = nil;
    [deleteButton addTarget:self action:@selector(deleteButtonPressed:)
           forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *deleteBarButton = [[UIBarButtonItem alloc] initWithCustomView:deleteButton];
    self.navigationItem.rightBarButtonItem = deleteBarButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    // Get the full post info
    if (self.post && self.post.postId) {
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api getFullPostInfoForPostId:self.post.postId];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Delete Post
- (void)deleteButtonPressed:(id)selector {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete?"
                                                    message:@"Are you sure you want to\ndelete this video?"
                                                   delegate:self
                                          cancelButtonTitle:@"Yes"
                                          otherButtonTitles:@"No", nil];
    alert.tag = 89890;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    // Delete Yes is index 0
    if (alertView.tag == 89890 && buttonIndex == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;

        // Delete from server Server
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api deletePostWithId:self.post.postId];
    }
}

#pragma mark - Notifications
- (void)reloadPosts:(NSNotification*)notification {
    if (!liking) {
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api getFullPostInfoForPostId:self.post.postId];
    }
    liking = NO;
}

- (void)fullPostReturn:(NSNotification*)notification {
    if ([notification.userInfo isKindOfClass:[NSDictionary class]]) {
        TDPost *newPost = [[TDPost alloc] initWithDictionary:notification.userInfo];
        if ([newPost.postId isEqualToNumber:self.post.postId]) {
            [self.post loadUpFromDict:notification.userInfo];
            [self.tableView reloadData];

            // Delete button
            if ([self.post.user.userId isEqualToNumber:[[TDCurrentUser sharedInstance] currentUserObject].userId]) {
                // Same User as current
                self.navigationItem.rightBarButtonItem.customView.hidden = NO;
            } else {
                self.navigationItem.rightBarButtonItem.customView.hidden = YES;
            }
        }
    }
}

- (void)newCommentReturn:(NSNotification*)notification {
    if ([notification.userInfo isKindOfClass:[NSDictionary class]]) {

        NSDictionary *commentDict = (NSDictionary *)notification.userInfo;
        if ([commentDict objectForKey:@"comment"] && [[commentDict objectForKey:@"comment"] objectForKey:@"comment"]) {
            TDComment *newComment = [[TDComment alloc] init];
            [newComment user:[[TDCurrentUser sharedInstance] currentUserObject]
                        dict:[[commentDict objectForKey:@"comment"] objectForKey:@"comment"]];
            [self.post addComment:newComment];
            [self.typingView reset];
            [self.tableView reloadData];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(2+[self.post.comments count])-1
                                                                      inSection:0]
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:NO];
            [[TDCurrentUser sharedInstance] registerForPushNotifications:@"Would you like to be notified of future replies?"];
        }
    }
}

- (void)postDeleted:(NSNotification*)notification {
    NSLog(@"delete notification:%@", notification);

    // And then go back
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)postDeleteFail:(NSNotification *)notification {
    NSLog(@"postDeleteFail notification:%@ CLASS:%@", notification, [notification.object class]);

    if ([notification.object isKindOfClass:[NSError class]]) {
        NSError *error = (NSError*)notification.object;
        if ([[error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)[error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
            if (response && response.statusCode == 403) {
                [TDViewControllerHelper showAlertMessage:@"There was an error (403). You don’t have permission to delete this post." withTitle:@"Error"];
            }
            if (response && response.statusCode == 401) {
                [TDViewControllerHelper showAlertMessage:@"There was an error (401).\nPlease try again." withTitle:@"Error"];
            }
        }
    }

    self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark - TableView delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2+[self.post.comments count];   // PostView, Like Cell, +Comments.count
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Post View
    if (indexPath.row == 0) {
        TDPostView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_POST_VIEW];
        if (!cell) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_POST_VIEW owner:self options:nil];
            cell = [topLevelObjects objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.bottomPaddingLine.hidden = YES;
            cell.likeView.hidden = YES;
            cell.delegate = self;
        }

        [cell setPost:self.post];
        cell.likeView.row = indexPath.row;
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
        cell.origTimeFrame = cell.timeLabel.frame;
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSInteger commentNumber = (indexPath.row - 2);
    TDComment *comment = [self.post.comments objectAtIndex:commentNumber];
    cell.commentNumber = commentNumber;
    [cell makeText:comment.body];
    [cell makeTime:comment.createdAt name:comment.user.username];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Post
    if (indexPath.row == 0) {
        return postViewHeight - postCommentViewHeight;
    }

    // Likes row
    if (indexPath.row == 1) {
        if ([self.post.likers count] == 0) {
            return minLikeheight;    // at least one row to show 'like' button
        } else {
            NSUInteger textHeight = [TDDetailsLikesCell heightOfLikersLabel:self.post.likers];
            return (textHeight < minLikeheight ? minLikeheight : textHeight + 7.0); // 7 = label's margin from top
        }
    }

    // Comments
    // A comment is at least 40+height for the message text
    TDComment *comment = [self.post.comments objectAtIndex:(indexPath.row-2)];
    // Last one?
    if (((indexPath.row-2)) == ([self.post.comments count]-1)) {
        return TDCommentCellProfileHeight + comment.messageHeight + 8.0;    // add a bit of padding
    }
    return TDCommentCellProfileHeight + comment.messageHeight;
}

#pragma mark - TypingView delegates

- (void)keyboardAppeared:(CGFloat)height curve:(NSInteger)curve {
    NSLog(@"delegate-keyboardAppeared:%f curve:%ld", height, (long)curve);

    self.typingView.isUp = YES;

    CGPoint newCenter = CGPointMake(origTypingViewCenter.x,
                                    origTypingViewCenter.y-height);

    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:500.0
          initialSpringVelocity:0.0
                        options:curve
                     animations:^{
                         self.typingView.center = newCenter;
                     }
                     completion:^(BOOL animDone){

                         if (animDone)
                         {
                             self.typingView.keybdUpFrame = self.typingView.frame;

                             [self adjustFrostedView];
                         }
                     }];
}

- (void)adjustFrostedView {
    CGRect newFrame = self.frostedViewWhileTyping.frame;
    newFrame.origin.y = self.navigationController.navigationBar.frame.size.height;
    newFrame.size.height = self.typingView.frame.origin.y-newFrame.origin.y;
    self.frostedViewWhileTyping.frame = newFrame;
    self.frostedViewWhileTyping.hidden = NO;
}

- (void)keyboardDisappeared:(CGFloat)height {
    NSLog(@"delegate-keyboardDisappeared:%f", height);

    [UIView animateWithDuration: 0.25
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{

                         self.typingView.center = origTypingViewCenter;

                     }
                     completion:^(BOOL animDone){

                         if (animDone)
                         {
                             self.typingView.isUp = NO;
                             self.frostedViewWhileTyping.hidden = YES;
                         }
                     }];
}

- (void)typingViewMessage:(NSString *)message {
    NSLog(@"chat-typingViewMessage:%@", message);

    if (self.typingView.isUp) {
        [self.typingView removeKeyboard];
    }

    // Post the comment to the server
    TDPostAPI *api = [TDPostAPI sharedInstance];
    [api postNewComment:message
                forPost:self.post.postId];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"TDDetailViewController-touches");

    if (self.typingView.isUp) {
        [self.typingView removeKeyboard];
    }
}

#pragma mark - TDDetailsLikesCell Delegates
- (void)likeButtonPressedFromLikes {
    if (self.post.postId) {

        // Add the like for the update
        [self.post addLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self.tableView reloadData];

        liking = YES;

        // Update Server
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api likePostWithId:self.post.postId];
    }
}

- (void)unLikeButtonPressedFromLikes {
    NSLog(@"TDDetailViewController-unLikeButtonPressedLikes");

    if (self.post.postId) {

        // Remove the like for the update
        [self.post removeLikerUser:[[TDCurrentUser sharedInstance] currentUserObject]];
        [self.tableView reloadData];

        liking = YES;

        // Update Server
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api unLikePostWithId:self.post.postId];
    }
}

- (void)miniAvatarButtonPressedForLiker:(NSDictionary *)liker {
    NSLog(@"delegate-miniAvatarButtonPressedForLiker:%@", liker);
}


#pragma mark - TDPostViewDelegate

- (void)userButtonPressedFromRow:(NSInteger)row {
    // Because we're on the detail page the only user available is the post's user
    [self showUserProfile:self.post.user];
}

#pragma mark - TDDetailsCommentsCellDelegate

- (void)userButtonPressedFromRow:(NSInteger)row commentNumber:(NSInteger)commentNumber {
    debug NSLog(@"detail-userButtonPressedFromRow:%ld commentNumber:%ld, %@ %@", (long)row, (long)commentNumber, self.post.user.userId, [[TDCurrentUser sharedInstance] currentUserObject].userId);

    if (self.post.comments && [post.comments count] > row) {
        TDComment *comment = [post.comments objectAtIndex:commentNumber];
        [self showUserProfile:comment.user];
    }
}

- (void)showUserProfile:(TDUser *)user {
    TDUserProfileViewController *vc = [[TDUserProfileViewController alloc] initWithNibName:@"TDUserProfileViewController" bundle:nil ];
    vc.profileUser = user;
    vc.fromProfileType = kFromProfileScreenType_OtherUser;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Update Posts After User Change Notification
-(void)updatePostsAfterUserUpdate:(NSNotification *)notification
{
    NSLog(@"%@ updatePostsAfterUserUpdate:%@", [self class], [[TDCurrentUser sharedInstance] currentUserObject]);

    if ([[[TDCurrentUser sharedInstance] currentUserObject].userId isEqualToNumber:self.post.user.userId])
    {
        [self.post replaceUserAndLikesAndCommentsWithUser:[[TDCurrentUser sharedInstance] currentUserObject]];
    }

    [self.tableView reloadData];
}


@end
