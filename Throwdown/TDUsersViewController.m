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
#import "TDTagUserFeedViewController.h"
#import "TDNoPostsCell.h"
@interface TDUsersViewController ()
@property (nonatomic) NSDictionary *campaignData;
@end

@implementation TDUsersViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString*)title campaignData:(NSDictionary*)campaignData
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.userList = [[NSMutableArray alloc] init];
        self.navTitle = title;
        self.campaignData = campaignData;
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
    [[TDUserAPI sharedInstance] getChallengersList:self.tagName callback:^(BOOL success, NSArray *suggestedList) {
        if (success && suggestedList && suggestedList.count > 0) {
            self.userList = [suggestedList copy];
            debug NSLog(@"challenger list, %@", self.userList);
            self.gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];
        } else if (success){
            self.gotFromServer = YES;
            [self.tableView reloadData];
            [self hideActivity];
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

    debug NSLog(@"self.activityIndicator.frame = %@", NSStringFromCGRect(self.activityIndicator.frame));
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
    if (self.gotFromServer) {
        if (self.userList.count) {
            return 65.;
        } else {
            return SCREEN_HEIGHT - self.navigationController.navigationBar.frame.size.height;
        }
    }
    return 0;
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
        if (self.userList.count) {
            return self.userList.count;
        } else {
            return 1;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.gotFromServer) {
        if (self.userList.count) {
            NSArray *object = [self.userList objectAtIndex:indexPath.row];
            TDFollowProfileCell *cell = [self createCell:tableView indexPath:indexPath userInfo:object];
            cell.delegate = self;
            return cell;
        } else {
            TDNoPostsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TDNoPostsCell"];
            if (!cell) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDNoPostsCell" owner:self options:nil];
                cell = [topLevelObjects objectAtIndex:0];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }

            NSString *photoURL = [self.campaignData valueForKey:@"image"];
            [cell createInfoCell:photoURL tagName:self.tagName];
     
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.userList.count) {
        //Open another view.
        TDFollowProfileCell *cell = (TDFollowProfileCell*)[tableView cellForRowAtIndexPath:indexPath];
        [self openTagUserFeed:cell.userId];
    }
}

- (TDFollowProfileCell*) createCell:(UITableView*)tableView indexPath:(NSIndexPath *)indexPath userInfo:(NSArray*)userInfo{
    TDFollowProfileCell *cell = (TDFollowProfileCell*)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_FOLLOWPROFILE];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CELL_IDENTIFIER_FOLLOWPROFILE owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.selectionStyle = UITableViewCellEditingStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.delegate = self;
    }
    cell.actionButton.hidden = YES;

    //TODO: Setting height to 1 for ios7 bug, but need to fix this
    if ([[[UIDevice currentDevice] systemVersion] floatValue] == 7.0){
        cell.topLine.frame = CGRectMake(0, 0, SCREEN_WIDTH, .5);
        cell.bottomLine.frame = CGRectMake(0, 64, SCREEN_WIDTH, .5);
    }
    // Reset everything in cell.
    cell.row = indexPath.row;
    cell.topLine.hidden = cell.row != 0;
    cell.userId = [userInfo valueForKey:@"id"];

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

    UIImageView *rightArrow = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 10 - [UIImage imageNamed:@"right-arrow-gray"].size.width, cell.frame.size.height/2 - [UIImage imageNamed:@"right-arrow-gray"].size.height/2, [UIImage imageNamed:@"right-arrow-gray"].size.width, [UIImage imageNamed:@"right-arrow-gray"].size.height)];
    [rightArrow setImage:[UIImage imageNamed:@"right-arrow-gray"]];
    [cell addSubview:rightArrow];

    NSInteger postNumber = [[userInfo valueForKey:@"tag_posts_count"] intValue];
    NSString *newTextString;
    if (postNumber) {
        newTextString = postNumber > 1 ? @"\nposts" : @"\npost";
    } else {
        newTextString = @"";
    }
    NSInteger activeDaysNumber = [[userInfo valueForKey:@"tag_days_count"] intValue];

    [self modifyPostsLabelString:cell.descriptionLabel statCount:[NSNumber numberWithInteger:postNumber] textString:newTextString];
    cell.descriptionLabel.hidden = NO; // Used for number of posts
    cell.descriptionLabel.frame = CGRectMake(0, 0, 100, cell.frame.size.height);
    [cell.descriptionLabel sizeToFit];

    if (activeDaysNumber) {
        newTextString = activeDaysNumber > 1 ? @"\ndays" : @"\nday";
    } else {
        newTextString = @"";
    }
    [self modifyPostsLabelString:cell.activeDaysLabel statCount:[NSNumber numberWithInteger:activeDaysNumber]
                      textString:newTextString];
    [cell.activeDaysLabel sizeToFit];

    CGRect activeDaysFrame = cell.activeDaysLabel.frame;
    activeDaysFrame.size.width = cell.activeDaysLabel.frame.size.width < 25 ? 25 : cell.activeDaysLabel.frame.size.width;
    activeDaysFrame.origin.x =     SCREEN_WIDTH - 10 - rightArrow.frame.size.width - 10 - activeDaysFrame.size.width;
    activeDaysFrame.origin.y = cell.frame.size.height/2 - cell.descriptionLabel.frame.size.height/2;
    cell.activeDaysLabel.frame = activeDaysFrame;
    [cell addSubview:cell.activeDaysLabel];

     CGRect descripFrame = cell.descriptionLabel.frame;
    descripFrame.size.width = cell.descriptionLabel.frame.size.width < 25 ? 25 : cell.descriptionLabel.frame.size.width;
    descripFrame.origin.x = SCREEN_WIDTH - 10 - rightArrow.frame.size.width - 10 - cell.activeDaysLabel.frame.size.width - 10 - descripFrame.size.width;
    descripFrame.origin.y = cell.frame.size.height/2 - cell.descriptionLabel.frame.size.height/2;
    cell.descriptionLabel.frame = descripFrame;

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

-(void)modifyPostsLabelString:(UILabel*)label statCount:(NSNumber*)statCount textString:(NSString*)textString{
    UIFont *font = [TDConstants fontRegularSized:17.0];
    UIFont *font2= [TDConstants fontRegularSized:11.];
//    NSString *newTextString;
//    if (statCount) {
//        newTextString = statCount.intValue > 1 ? @"\nposts" : textString;
//    } else {
//        newTextString = @"";
//    }
    NSString *postString = [NSString stringWithFormat:@"%@%@", statCount, textString];

    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:postString];
    [attString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, postString.length)];
    [attString addAttribute:NSForegroundColorAttributeName value:[TDConstants headerTextColor] range:NSMakeRange(0, postString.length)];
    [attString addAttribute:NSFontAttributeName value:font2 range:NSMakeRange(postString.length - textString.length, textString.length)];
    [attString addAttribute:NSForegroundColorAttributeName value:[TDConstants commentTimeTextColor] range:NSMakeRange(postString.length - textString.length, textString.length)];

    label.lineBreakMode = NSLineBreakByWordWrapping;
    [label setNumberOfLines:0];
    label.textAlignment = NSTextAlignmentCenter;

    [label setAttributedText:attString];
}

- (void)userProfilePressedWithId:(NSNumber *)userId{
    [self openTagUserFeed:userId];
}

- (void)openTagUserFeed:(NSNumber*)userId {
    TDTagUserFeedViewController *vc = [[TDTagUserFeedViewController alloc] initWithNibName:@"TDTagUserFeedViewController" bundle:nil];
    [vc setUserId:userId  tagName:self.tagName];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
