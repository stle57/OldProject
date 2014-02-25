//
//  TDHomeViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDHomeViewController.h"
#import "TDAppDelegate.h"
#import "TDPostAPI.h"
#import "TDPostView.h"
#import "TDConstants.h"
#import "TDUserAPI.h"

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *posts;
    UIRefreshControl *refreshControl;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;
@property (nonatomic, retain) UIRefreshControl *refreshControl;

@end

@implementation TDHomeViewController

@synthesize refreshControl;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view insertSubview:self.recordButton aboveSubview:self.tableView];
    [self.view insertSubview:self.notificationButton aboveSubview:self.tableView];
    [self.view insertSubview:self.profileButton aboveSubview:self.tableView];
//    [self.view bringSubviewToFront:self.recordButton];
//    [self.view bringSubviewToFront:self.notificationButton];
//    [self.view bringSubviewToFront:self.profileButton];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPosts:) name:@"TDReloadPostsNotification" object:nil];
    [self reloadPosts];
    [[TDPostAPI sharedInstance] fetchPostsUpstream];
    
    // Add refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshControlUsed)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl setTintColor:[TDConstants brandingRedColor]];
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    [self reloadPosts];
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.refreshControl = nil;
}

#pragma mark - refresh control
-(void)refreshControlUsed
{
    debug NSLog(@"refreshControlUsed");
    
    [self reloadPosts];
    // uirefreshcontrol should be attached to a uitableviewcontroller - this stops a slight jutter
    [self.refreshControl performSelector:@selector(endRefreshing)
                              withObject:nil
                              afterDelay:0.1];
}

# pragma mark - table view delegate


- (void)reloadPosts:(NSNotification*)notification
{
    [self reloadPosts];
}

- (void)reloadPosts {
    debug NSLog(@"reload posts");
    posts = [[TDPostAPI sharedInstance] getPosts];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TDPostView *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER];
    if (!cell) {
        // Load the nib and assign an owner
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    TDPost *post = (TDPost *)[posts objectAtIndex:indexPath.row];
    [cell.usernameLabel setText:post.username];
    [cell setPreviewImageFrom:post.filename];
    return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    DetailVC *dvc = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailVC"];
//    dvc.tweet = [self.tweetsArray objectAtIndex:indexPath.row];
//    [self.navigationController pushViewController:dvc animated:YES];
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 362.0f;
}


# pragma mark - navigation

// HACK to get log out to work
- (IBAction)profileButtonPressed:(id)sender {
    [[TDUserAPI sharedInstance] logout];
    [self showWelcomeController];
}

- (void)returnToRoot {
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)showWelcomeController
{
    [self dismissViewControllerAnimated:NO completion:nil];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *welcomeViewController = [storyboard instantiateViewControllerWithIdentifier:@"WelcomeViewController"];

    TDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.window.rootViewController = welcomeViewController;
    [self.navigationController popToRootViewControllerAnimated:NO];
}


@end
