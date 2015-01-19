//
//  TDUsersViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 1/18/15.
//  Copyright (c) 2015 Throwdown. All rights reserved.
//

#import "TDUsersViewController.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDUserAPI.h"
#import <SDWebImageManager.h>
#import <UIImage+Resizing.h>

@interface TDUsersViewController ()

@end

@implementation TDUsersViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString*)title
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.userList = [[NSMutableArray alloc] init];
        self.navTitle = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"background-gradient"] forBarMetrics:UIBarMetricsDefault];

    // Background color
    self.tableView.backgroundColor = [TDConstants lightBackgroundColor];

    self.view.backgroundColor = [TDConstants lightBackgroundColor];

    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.backButton];     // '<'
    self.navigationItem.leftBarButtonItem = leftBarButton;
    [navigationBar setBarStyle:UIBarStyleBlack];
    [navigationBar setTranslucent:NO];
    [navigationBar setOpaque:YES];

    // Title
    self.navLabel.text = self.navTitle;
    self.navLabel.textColor = [UIColor whiteColor];
    self.navLabel.font = [TDConstants fontSemiBoldSized:18];
    self.navLabel.textAlignment = NSTextAlignmentCenter;
    [self.navLabel sizeToFit];
    [self.navigationItem setTitleView:self.navLabel];

    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)loadData {
    self.gotFromServer = NO;
    self.activityIndicator.text.text = @"Loading";
    [self showActivity];
    // Load data from server
    [[TDUserAPI sharedInstance] getSuggestedUserList:^(BOOL success, NSArray *suggestedList) {
        if (success && suggestedList && suggestedList.count > 0) {
            self.userList = [suggestedList copy];
            debug NSLog(@"got suggested user list");
            [[TDUserAPI sharedInstance] getCommunityUserList:^(BOOL success, NSArray *returnList) {
                if (success && returnList && returnList.count > 0) {
                    debug NSLog(@"got community user list");
                    self.userList = [returnList copy];
                    self.gotFromServer = YES;
                    [self.tableView reloadData];
                    [self hideActivity];
                } else {
                    self.gotFromServer = NO;
                    [self hideActivity];
                }
            }];
        } else {
            self.gotFromServer = NO;
            [self hideActivity];
        }
    }];
}

- (IBAction)backButtonHit:(id)sender {
    [self leave];
}

- (void) leave {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)showActivity {
    self.backButton.enabled = NO;
    self.activityIndicator.center = [TDViewControllerHelper centerPosition];

    CGPoint centerFrame = self.activityIndicator.center;
    centerFrame.y = self.activityIndicator.center.y - self.activityIndicator.backgroundView.frame.size.height/2;
    self.activityIndicator.center = centerFrame;
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startSpinner];
    self.activityIndicator.hidden = NO;
}

- (void)hideActivity {
    self.backButton.enabled = YES;
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopSpinner];
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65.;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    if (self.gotFromServer) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.gotFromServer) {
        return self.userList.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *object = [self.userList objectAtIndex:indexPath.row];
    TDFollowProfileCell *cell = [self createCell:tableView indexPath:indexPath userInfo:object];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    //Open another view.
    TDFollowProfileCell *cell = (TDFollowProfileCell*)[tableView cellForRowAtIndexPath:indexPath];
    debug NSLog(@"open user view with hashtag=%@", cell.userId);
}

- (TDFollowProfileCell*) createCell:(UITableView*)tableView indexPath:(NSIndexPath *)indexPath userInfo:(NSArray*)userInfo{
    TDFollowProfileCell *cell = (TDFollowProfileCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_FOLLOWPROFILE];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_FOLLOWPROFILE owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.delegate = self;
    }

    //TODO: Setting height to 1 for ios7 bug, but need to fix this
    if ([[[UIDevice currentDevice] systemVersion] floatValue] == 7.0){
        cell.topLine.frame = CGRectMake(0, 0, SCREEN_WIDTH, .5);
        cell.bottomLine.frame = CGRectMake(0, 64, SCREEN_WIDTH, .5);
    }
    // Reset everything in cell.
    cell.row = indexPath.row;
    cell.topLine.hidden = cell.row != 0;
    cell.userId = [userInfo valueForKey:@"id"];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    cell.nameLabel.textColor = [TDConstants headerTextColor];
    cell.nameLabel.font = [TDConstants fontSemiBoldSized:16];

    NSString *fullName = [userInfo valueForKey:@"name"];
    cell.nameLabel.hidden = NO;
    cell.nameLabel.text = fullName;
    [cell.nameLabel sizeToFit];

    CGRect nameFrame = cell.nameLabel.frame;
    nameFrame.origin.x = cell.userImageView.frame.origin.y + cell.userImageView.frame.size.width + 10;
    nameFrame.origin.y = cell.frame.size.height/2 - cell.nameLabel.frame.size.height/2;
    cell.nameLabel.frame = nameFrame;

    cell.descriptionLabel.hidden = NO; // Used for number of posts
    cell.descriptionLabel.textColor = [TDConstants commentTimeTextColor];
    cell.descriptionLabel.font = [TDConstants fontRegularSized:15];
    NSAttributedString *numPostStr = [TDViewControllerHelper makeParagraphedTextWithString:@"100 posts" font:[TDConstants fontRegularSized:15.] color:[TDConstants commentTimeTextColor] lineHeight:15. lineHeightMultipler:(15./15.)];
    cell.descriptionLabel.attributedText = numPostStr;
    [cell.descriptionLabel sizeToFit];

    CGRect descripFrame = cell.descriptionLabel.frame;
    descripFrame.origin.x = SCREEN_WIDTH - 44 - 10 - cell.descriptionLabel.frame.size.width;
    descripFrame.origin.y = cell.frame.size.height/2 - cell.descriptionLabel.frame.size.height/2;
    cell.descriptionLabel.frame = descripFrame;

    cell.actionButton.hidden = YES;

    cell.userImageView.hidden = NO;
    cell.userImageView.image = nil;
    if ([userInfo valueForKey:@"picture"] != [NSNull null] && ![[userInfo valueForKey:@"picture"] isEqualToString:@"default"]) {
        [self downloadUserImage:[userInfo valueForKeyPath:@"picture"] cell:cell];
    } else {
        cell.userImageView.image = [UIImage imageNamed:@"prof_pic_default"];
    }

    cell.nameLabel.textColor = [TDConstants headerTextColor];
    cell.nameLabel.font = [TDConstants fontSemiBoldSized:16];

    return cell;
}

-(void)actionButtonPressedFromRow:(NSInteger)row tag:(NSInteger)tag userId:(NSNumber*)userId{
    //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0] ;
    return;
}

- (void)downloadUserImage:(NSString *)profileImage cell:(TDFollowProfileCell *)cell {
    cell.userImageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", RSHost, profileImage]];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:cell.userImageURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        // no progress bar here
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *finalURL) {
        CGFloat width = cell.userImageView.frame.size.width * [UIScreen mainScreen].scale;
        image = [image scaleToSize:CGSizeMake(width, width)];
        if (![finalURL isEqual:cell.userImageURL]) {
            return;
        }
        if (!error && image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cell.userImageView) {
                    cell.userImageView.image = image;
                }
            });
        }
    }];
}
@end
