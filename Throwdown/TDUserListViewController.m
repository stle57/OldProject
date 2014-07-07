 //
//  TDUserListViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 7/6/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDUserListViewController.h"
#import "TDConstants.h"
#import "TDAPIClient.h"
#include "TDUserAPI.h"
#import "TDUser.h"
#import "TDUserList.h"

@interface TDUserListViewController ()

@end

@implementation TDUserListViewController
@synthesize userNames;
@synthesize filteredList;

-(id) init {
    self = [super init];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    return self;

}
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.communityInfo = [TDUserList sharedInstance];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    debug NSLog(@"-->inside numberOfRowsInSection w count=%lu", (unsigned long)self.filteredList.count);
    return self.filteredList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    debug NSLog(@"--> inside cellForRowAtIndexPath %lu", (unsigned long)indexPath.row);
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [TDConstants fontBoldSized:14.0];
        cell.detailTextLabel.font = [TDConstants fontLightSized:12.0];
        cell.indentationLevel = 5;
        cell.indentationWidth = 6;
    }

    NSDictionary* user = [self.filteredList objectAtIndex:indexPath.row];
    debug NSLog(@"user=%@", user);
    cell.textLabel.text  = [user objectForKey:@"username"];
    cell.detailTextLabel.text  = [user objectForKey:@"name"];

    UIImageView *imgView=[[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 30, 30)];
    imgView.backgroundColor=[UIColor clearColor];
    [imgView.layer setCornerRadius:15.0f];
    [imgView.layer setMasksToBounds:YES];
    [imgView setClipsToBounds:YES];
    imgView.image = [UIImage imageNamed:@"prof_pic_default"];

    if ([user objectForKey:@"picture"] != [NSNull null] && ![[user objectForKey:@"picture"] isEqualToString:@"default"]){
        [[TDAPIClient sharedInstance] setImage:@{@"imageView":imgView,
                                                 @"filename":[user objectForKey:@"picture"],
                                                 @"width":[NSNumber numberWithInt:cell.imageView.frame.size.width],
                                                 @"height":[NSNumber numberWithInt:cell.imageView.frame.size.height]}];

    }

    [imgView.layer setCornerRadius:imgView.layer.frame.size.width / 2];
    imgView.contentMode = UIViewContentModeScaleAspectFit;

    [cell.contentView addSubview:imgView];

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    debug NSLog(@"row selected, %lu", indexPath.row);
    NSDictionary * selectedUser = [self.filteredList objectAtIndex:indexPath.row];
    debug NSLog(@"selectedUser=%@", selectedUser);

    // Pass data back to controller
    [self.delegate addItemViewController:self didFinishEnteringItem:selectedUser];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

-(void)showTableView:(NSString*)filterString {
    debug NSLog(@"inside showTableView with filterString=%@", filterString);

    if(filterString.length != 0)  {
        [self.filteredList removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF.username like[c] %@) OR (SELF.name like[c] %@)",[NSString stringWithFormat:@"%@*",filterString], [NSString stringWithFormat:@"*%@*",filterString]];
        self.filteredList = [NSMutableArray arrayWithArray:[self.communityInfo.userList filteredArrayUsingPredicate:predicate]];

        debug NSLog(@"--->filteredList=%@", self.filteredList);
    }
}
@end
