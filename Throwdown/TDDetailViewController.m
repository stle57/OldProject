//
//  TDDetailViewController.m
//  Throwdown
//
//  Created by Andrew Bennett on 3/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDDetailViewController.h"
#import "TDPostAPI.h"
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDComment.h"

@interface TDDetailViewController ()

@end

@implementation TDDetailViewController

@synthesize post;
@synthesize typingView;
@synthesize frostedViewWhileTyping;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"TDReloadPostsNotification"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:FULL_POST_INFO_NOTIFICATION
                                                  object:nil];

    self.post = nil;
    self.typingView = nil;
    self.frostedViewWhileTyping = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Details";

    // Frosted View for while we're typing to stop video playing
    self.frostedViewWhileTyping = [[UIView alloc] initWithFrame:CGRectMake(0.0,
                                                                           0.0,
                                                                           self.view.frame.size.width,
                                                                           self.view.frame.size.height)];
    self.frostedViewWhileTyping.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.frostedViewWhileTyping];
    self.frostedViewWhileTyping.hidden = YES;

    // Cell height
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_POST_VIEW owner:self options:nil];
    TDPostView *cell = [topLevelObjects objectAtIndex:0];
    postViewHeight = cell.frame.size.height;
    postCommentViewHeight = cell.likeCommentView.frame.size.height;
    cell = nil;

    // Typing Bottom
    self.typingView = [[TDTypingView alloc] initWithFrame:CGRectMake(0.0,
                                                                    [UIScreen mainScreen].bounds.size.height-[TDTypingView typingHeight]-self.navigationController.navigationBar.frame.size.height-[[UIApplication sharedApplication] statusBarFrame].size.height,
                                                                    self.view.frame.size.width,
                                                                    [TDTypingView typingHeight])];
    self.typingView.delegate = self;
    [self.view insertSubview:self.typingView aboveSubview:self.tableView];
    origTypingViewCenter = self.typingView.center;

    // Adjust tableView
    CGRect frame = self.tableView.frame;
    frame.size.height -= [TDTypingView typingHeight];
    self.tableView.frame = frame;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPosts:) name:@"TDReloadPostsNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullPostReturn:) name:FULL_POST_INFO_NOTIFICATION object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:NO];

    // Get the full post info
    if (self.post && self.post.postId) {
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api getFullPostInfoForPostId:self.post.postId];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Notifications
- (void)reloadPosts:(NSNotification*)notification
{
    [self.tableView reloadData];
}

-(void)fullPostReturn:(NSNotification*)notification
{
    if ([notification.userInfo isKindOfClass:[NSDictionary class]]) {
        TDPost *newPost = [[TDPost alloc] initWithDictionary:notification.userInfo];
        if ([newPost.postId isEqualToNumber:self.post.postId]) {
            self.post = nil;
            self.post = [[TDPost alloc] initWithDictionary:notification.userInfo];
            [self.tableView reloadData];
        }
    }
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
            cell.likeCommentView.hidden = YES;
        }

        [cell setPost:self.post];
        cell.likeCommentView.row = indexPath.row;
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

    TDComment *comment = [self.post.comments objectAtIndex:(indexPath.row-2)];
    [cell makeText:comment.body];
    [cell makeTime:comment.createdAt name:comment.user.username];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Post
    if (indexPath.row == 0) {
        return postViewHeight-postCommentViewHeight;
    }

    // Likes row
    if (indexPath.row == 1) {
        if ([self.post.likers count] == 0) {
            return 33.0;    // at least one row to show 'like' button
        } else {
            return [TDDetailsLikesCell numberOfRowsForLikers:[self.post.likers count]]*33.0;
        }
    }

    // Comments
    // A comment is at least 40+height for the message text
    TDComment *comment = [self.post.comments objectAtIndex:(indexPath.row-2)];
    return 40.0+comment.messageHeight;
}

#pragma mark - TypingView delegates
-(void)keyboardAppeared:(CGFloat)height curve:(NSInteger)curve
{
    debug NSLog(@"delegate-keyboardAppeared:%f curve:%ld", height, (long)curve);

    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:500.0
          initialSpringVelocity:0.0
                        options:curve
                     animations:^{
                         self.typingView.center = CGPointMake(origTypingViewCenter.x,
                                                              origTypingViewCenter.y-height);
                     }
                     completion:^(BOOL animDone){

                         if (animDone)
                         {
                             self.frostedViewWhileTyping.hidden = NO;
                             self.typingView.keybdUpFrame = self.typingView.frame;
                             self.typingView.isUp = YES;
                         }
                     }];
}

-(void)keyboardDisappeared:(CGFloat)height
{
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

-(void)typingViewMessage:(NSString *)message
{
    NSLog(@"chat-typingViewMessage:%@", message);

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.typingView.isUp) {
        [self.typingView removeKeyboard];
    }
}

#pragma mark - TDDetailsLikesCell Delegates
-(void)likeButtonPressedFromLikes
{
    if (self.post.postId) {
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api likePostWithId:self.post.postId];
    }
}

-(void)unLikeButtonPressedLikes
{
    if (self.post.postId) {
        TDPostAPI *api = [TDPostAPI sharedInstance];
        [api unLikePostWithId:self.post.postId];
    }
}

-(void)miniAvatarButtonPressedForLiker:(NSDictionary *)liker
{
    NSLog(@"delegate-miniAvatarButtonPressedForLiker:%@", liker);
}


@end
