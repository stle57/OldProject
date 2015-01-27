//
//  TDInterestsViewController.m
//  Throwdown
//
//  Created by Stephanie Le on 12/17/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import "TDInterestsViewController.h"
#import "TDConstants.h"
#import "TDViewControllerHelper.h"
#import "TDGoalsCell.h"

@interface TDInterestsViewController ()
@property (nonatomic) NSIndexPath *selectedIndexPath;
@end

static NSString *topHeaderText1 = @"What are your interests?";
static NSString *topHeaderText2 = @"Select all that apply.";
static const int doneBackgroundViewHeight = 80;

@implementation TDInterestsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil withBackButton:(BOOL)yes interestsList:(NSArray*)interestsList
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if (interestsList == nil) {
            self.interestList =
            [NSMutableArray arrayWithObjects:
                @{@"name":@"Barre", @"selected":@0, @"id":@0},
                @{@"name":@"Baseball", @"selected":@0, @"id":@0},
                @{@"name":@"Basketball", @"selected":@0, @"id":@0},
                @{@"name":@"Bodybuilding", @"selected":@0, @"id":@0},
                @{@"name":@"Bootcamp",@"selected":@0, @"id":@0},
                @{@"name":@"Boxing",@"selected":@0, @"id":@0},
                @{@"name":@"Cricket",@"selected":@0, @"id":@0},
                @{@"name":@"CrossFit",@"selected":@0, @"id":@0},
                @{@"name":@"Cycling",@"selected":@0, @"id":@0},
                @{@"name":@"Dancing",@"selected":@0, @"id":@0},
                @{@"name":@"Eating Healthy",@"selected":@0, @"id":@0},
                @{@"name":@"Fitness Motivation",@"selected":@0, @"id":@0},
                @{@"name":@"Football (American)",@"selected":@0, @"id":@0},
                @{@"name":@"Golf",@"selected":@0, @"id":@0},
                @{@"name":@"Gymnastics",@"selected":@0, @"id":@0},
                @{@"name":@"Hiking",@"selected":@0, @"id":@0},
                @{@"name":@"Hockey",@"selected":@0, @"id":@0},
                @{@"name":@"Insanity",@"selected":@0, @"id":@0},
                @{@"name":@"Lacrosse",@"selected":@0, @"id":@0},
                @{@"name":@"Martial Arts",@"selected":@0, @"id":@0},
                @{@"name":@"Obstacle Course",@"selected":@0, @"id":@0},
                @{@"name":@"P90X",@"selected":@0, @"id":@0},
                @{@"name":@"Pilates",@"selected":@0, @"id":@0},
                @{@"name":@"Powerlifting",@"selected":@0, @"id":@0},
                @{@"name":@"Rowing",@"selected":@0, @"id":@0},
                @{@"name":@"Rugby",@"selected":@0, @"id":@0},
                @{@"name":@"Running",@"selected":@0, @"id":@0},
                @{@"name":@"Skating",@"selected":@0, @"id":@0},
                @{@"name":@"Skiing",@"selected":@0, @"id":@0},
                @{@"name":@"Snowboarding",@"selected":@0, @"id":@0},
                @{@"name":@"Soccer",@"selected":@0, @"id":@0},
                @{@"name":@"Softball",@"selected":@0, @"id":@0},
                @{@"name":@"Strongman",@"selected":@0, @"id":@0},
                @{@"name":@"Swimming",@"selected":@0, @"id":@0},
                @{@"name":@"Tennis",@"selected":@0, @"id":@0},
                @{@"name":@"Track and Field",@"selected":@0, @"id":@0},
                @{@"name":@"Volleyball",@"selected":@0, @"id":@0},
                @{@"name":@"Weightlifting (Olympic)",@"selected":@0, @"id":@0},
                @{@"name":@"Yoga",@"selected":@0, @"id":@0},
                @{@"name":@"Zumba",@"selected":@0, @"id":@0}, nil];

        } else {
            self.interestList = [interestsList mutableCopy];
        }

        self.showBackButton = yes;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH+20, SCREEN_HEIGHT);
    self.view.backgroundColor = [UIColor clearColor];
    if (self.showBackButton) {
        self.backButton.frame = CGRectMake(15, [UIApplication sharedApplication].statusBarFrame.size.height, [UIImage imageNamed:@"btn_back"].size.width, [UIImage imageNamed:@"btn_back"].size.height);
        //- Adjust the size of the button to have a larger tap area
        self.backButton.frame = CGRectMake(self.backButton.frame.origin.x -10,
                                            self.backButton.frame.origin.y -10,
                                            self.backButton.frame.size.width + 20,
                                            self.backButton.frame.size.height + 20);
        [self.view addSubview:self.backButton];
    }
    
    [self createHeaderLabel];
    
    self.tableView.frame = CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_HEIGHT - 80 - 100);
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    CGRect bottomLineRect = self.bottomMargin.frame;
    bottomLineRect.origin.x = 0;
    bottomLineRect.origin.y = SCREEN_HEIGHT - 80;
    bottomLineRect.size.height = (1.0 / [[UIScreen mainScreen] scale]);
    bottomLineRect.size.width = SCREEN_WIDTH;
    self.bottomMargin.frame = bottomLineRect;
    self.bottomMargin.backgroundColor = [TDConstants commentTimeTextColor];
    [self.view addSubview:self.bottomMargin];
    
    self.doneBackgroundView.frame = CGRectMake(0, self.bottomMargin.frame.origin.y + self.bottomMargin.frame.size.height, SCREEN_WIDTH, doneBackgroundViewHeight);
    self.doneBackgroundView.backgroundColor = [UIColor colorWithRed:(251.0/255.0) green:(250.0/255.0) blue:(249.0/255.0) alpha:1.0];
    [self.view addSubview:self.doneBackgroundView];

    
    self.doneButton.frame = CGRectMake(self.doneBackgroundView.frame.size.width/2 - [UIImage imageNamed:@"btn_okdone"].size.width/2, doneBackgroundViewHeight - 10- [UIImage imageNamed:@"ovals_right"].size.height - 10-[UIImage imageNamed:@"btn_okdone"].size.height, [UIImage imageNamed:@"btn_okdone"].size.width, [UIImage imageNamed:@"btn_okdone"].size.height);
    
    [self.doneBackgroundView addSubview:self.doneButton];
    
    self.pageIndicator.frame = CGRectMake(self.doneBackgroundView.frame.size.width/2 - [UIImage imageNamed:@"ovals_right"].size.width/2, self.doneButton.frame.origin.y + self.doneButton.frame.size.height + 10, [UIImage imageNamed:@"ovals_right"].size.width, [UIImage imageNamed:@"ovals_right"].size.height);
    
    self.pageIndicator.hidden = NO;
    [self.doneBackgroundView addSubview:self.pageIndicator];
    
    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];
    [self.keyboardObserver startListening];
    
    self.tableView.backgroundColor = [UIColor clearColor];

    debug NSLog(@"interest view frame=%@", NSStringFromCGRect(self.view.frame));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self.keyboardObserver stopListening];
    self.keyboardObserver = nil;
}

- (IBAction)doneButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(doneButtonPressed:)]) {
        [self.delegate doneButtonPressed:self.interestList];
    }
}

#pragma mark UITableViewDataSource delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.interestList.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.interestList.count +1) {
        return 59;
    } else {
        return 44;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TDGoalsCell *cell = (TDGoalsCell *)[tableView dequeueReusableCellWithIdentifier:@"TDGoalsCell"];
    if (!cell) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"TDGoalsCell" owner:self options:nil];
        cell = [topLevelObjects objectAtIndex:0];
        cell.delegate = self;
        cell.editableTextField.delegate = self;
    }
    
    cell.row = indexPath.row;
    if (indexPath.row == self.interestList.count) {
        [cell createCell:YES text:nil selected:NO];
        
    } else {
        NSDictionary *dict = self.interestList[indexPath.row];
        BOOL selected = [[dict objectForKey:@"selected"] boolValue];
        NSString *interestName = [dict objectForKey:@"name"];

        [cell createCell:NO text:interestName selected:selected];
    }

    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == self.interestList.count) {
        TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            [cell makeCellFirstResponder];
            self.selectedIndexPath = indexPath;
        }
    } else {
        [self selectionButtonPressedFromRow:indexPath.row];
    }
}

#pragma mark TDGoalsCellDelegate
- (void)selectionButtonPressedFromRow:(NSInteger)row {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell goalSelected:(cell.selectionButton.tag == 0) ? YES : NO];
        // take out of the list
        NSMutableDictionary *dict = [[self.interestList objectAtIndex:row] mutableCopy];
        if ([[dict valueForKey:@"selected"] boolValue] == YES) {
            [dict setValue:@0 forKey:@"selected"];
            self.interestList[row] = dict;
        } else {
            [dict setValue:@1 forKey:@"selected"];
            self.interestList[row] = dict;
        }
    }
}

- (void)addGoals:(NSString*)text row:(NSInteger)row{
    NSDictionary *tempDict = @{@"name":text, @"selected":@1, @"id":[[NSNumber numberWithLong:(row+1)] stringValue]};
    [self.interestList addObject:tempDict];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        [cell changeCellToAddGoals];
    }

    NSIndexPath *path1 = [NSIndexPath indexPathForRow:self.interestList.count inSection:0]; //ALSO TRIED WITH indexPathRow:0
    NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];

    //Create indexPath for row below, so we can scroll to it
    NSIndexPath *addMoreRowIndexPath = [NSIndexPath indexPathForRow:row+1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:addMoreRowIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    
}

- (void)addNewGoalPressed:(NSInteger)row {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark helper methods

- (void)createHeaderLabel {
    self.headerLabel1.frame = CGRectMake(0,
                                         35,
                                         SCREEN_WIDTH,
                                         50);
    NSAttributedString *attString1 = [TDViewControllerHelper makeLeftAlignedTextWithString:topHeaderText1 font:[TDConstants fontSemiBoldSized:18.] color:[TDConstants headerTextColor] lineHeight:18. lineHeightMultipler:18/18];
    [self.headerLabel1 setAttributedText:attString1];
    [self.headerLabel1 setNumberOfLines:0];
    [self.headerLabel1 sizeToFit];
    
    CGRect frame1 = self.headerLabel1.frame;
    frame1.origin.x = SCREEN_WIDTH/2 - self.headerLabel1.frame.size.width/2;
    self.headerLabel1.frame = frame1;
    [self.view addSubview:self.headerLabel1];
    
    UIFont *font2 = [TDConstants fontRegularSized:14.0];
    self.headerLabel2.frame = CGRectMake(0,
                                         self.headerLabel1.frame.origin.y + self.headerLabel1.frame.size.height + 9,
                                         SCREEN_WIDTH,
                                         50);
    NSAttributedString *attString2 = [TDViewControllerHelper makeLeftAlignedTextWithString:topHeaderText2 font:font2 color:[TDConstants headerTextColor] lineHeight:14.0 lineHeightMultipler:(14./14.0)];
    [self.headerLabel2 setAttributedText:attString2];
    [self.headerLabel2 setNumberOfLines:0];
    [self.headerLabel2 sizeToFit];
    
    CGRect frame2 = self.headerLabel2.frame;
    frame2.origin.x = SCREEN_WIDTH/2 - self.headerLabel2.frame.size.width/2;
    frame2.origin.y = self.headerLabel1.frame.origin.y + self.headerLabel1.frame.size.height+ 9;
    self.headerLabel2.frame = frame2;

    [self.view addSubview:self.headerLabel2];
}

#pragma mark - Keyboard / Textfield

- (void)keyboardWillHide:(NSNotification *)notification {
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSNumber *rate = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    [UIView animateWithDuration:rate.floatValue animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }];
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Show the "Add" button
    debug NSLog(@"going to start editing");
    
}

- (void)textFieldDidChange:(UITextField *)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    //Show the checkbox
    debug NSLog(@"done editing");
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    debug NSLog(@"return button hit");
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:self.selectedIndexPath];
    if (cell) {
        [self addGoals:cell.editableTextField.text row:cell.row];
    }
    return YES;
}

- (IBAction)backButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(backButtonPressed)]) {
        [self.delegate backButtonPressed];
    }
}

@end
