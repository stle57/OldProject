//
//  TDHomeViewController.m
//  Throwdown
//
//  Created by Andrew C on 1/21/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDHomeViewController.h"
#import "TDPostAPI.h"
#import "TDPostView.h"
#import "TDConstants.h"

#define CELL_IDENTIFIER @"TDPostView"

@interface TDHomeViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSArray *posts;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationButton;
@property (weak, nonatomic) IBOutlet UIButton *profileButton;

@end

@implementation TDHomeViewController

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
}


# pragma mark - table view delegate


- (void)reloadPosts:(NSNotification*)notification
{
    NSLog(@"reload posts with notification");
    [self reloadPosts];
}

- (void)reloadPosts {
    NSLog(@"reload posts");
    posts = [[TDPostAPI sharedInstance] getPosts];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"number of rows in section %lu", (unsigned long)[posts count]);
    return [posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"cell for row at %@", indexPath);
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


- (void)returnToRoot {
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
