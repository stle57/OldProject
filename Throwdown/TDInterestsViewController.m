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
@property (nonatomic) NSMutableArray *interestList;
@property (nonatomic) NSIndexPath *selectedIndexPath;
@end

static NSString *topHeaderText1 = @"What are your interests?";
static NSString *topHeaderText2 = @"Select all that apply.";

@implementation TDInterestsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.interestList = [NSMutableArray arrayWithObjects:@"Cycling", @"Yoga",
                         @"CrossFit", @"Bodybuilding", @"Marathons", @"Kickboxing", @"MMA", nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
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
    
    self.doneButton.frame = CGRectMake(SCREEN_WIDTH/2 - [UIImage imageNamed:@"btn_okdone"].size.width/2, SCREEN_HEIGHT - 70, [UIImage imageNamed:@"btn_okdone"].size.width, [UIImage imageNamed:@"btn_okdone"].size.height);
    
    [self.view addSubview:self.doneButton];
    
    self.keyboardObserver = [[TDKeyboardObserver alloc] initWithDelegate:self];
    [self.keyboardObserver startListening];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.layer.borderWidth = 2.;
    self.view.layer.borderColor = [[UIColor greenColor] CGColor];
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
    debug NSLog(@"done button pressed");
    if (self.delegate && [self.delegate respondsToSelector:@selector(doneButtonPressed)]) {
        [self.delegate doneButtonPressed];
    }
}

#pragma mark UITableViewDataSource delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    debug NSLog(@"number of rows");
    return self.interestList.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
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
    
    cell.bottomLine.hidden = NO;
    cell.row = indexPath.row;
    cell.goalLabel.hidden = NO;
    cell.addButton.hidden = YES;
    cell.selectionButton.hidden = NO;
    cell.editableTextField.hidden = YES;
    
    if (indexPath.row == self.interestList.count) {
        cell.goalLabel.hidden = YES;
        cell.addButton.hidden = NO;
        cell.selectionButton.hidden = YES;
        CGRect buttonFrame = cell.addButton.frame;
        buttonFrame.origin.x = cell.frame.size.width/2 - cell.addButton.frame.size.width/2;
        buttonFrame.origin.y = cell.frame.size.height/2 - cell.addButton.frame.size.height/2;
        cell.addButton.frame = buttonFrame;
        cell.bottomLine.hidden = YES;
        
    } else {
        NSAttributedString *attString = [self makeTextWithString:self.interestList[indexPath.row] font:[TDConstants fontRegularSized:16.] color:[TDConstants headerTextColor] lineHeight:16. lineHeightMultipler:16./16.];
        cell.goalLabel.attributedText = attString;
        [cell.goalLabel sizeToFit];
    }
    
    CGRect goalFrame = cell.goalLabel.frame;
    goalFrame.origin.y = cell.frame.size.height/2 - cell.goalLabel.frame.size.height/2;
    cell.goalLabel.frame = goalFrame;
    
    cell.editableTextField.frame = goalFrame;
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    debug NSLog(@"row selected");
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == self.interestList.count) {
        TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            cell.goalLabel.hidden = YES;
            cell.addButton.hidden = YES;
            cell.editableTextField.hidden = NO;
            [cell.editableTextField becomeFirstResponder];
            debug NSLog(@"cell.editableTextField.frame = %@",NSStringFromCGRect( cell.editableTextField.frame));
            [cell.editableTextField setEnablesReturnKeyAutomatically:YES];
            self.selectedIndexPath = indexPath;
            cell.bottomLine.hidden = NO;
            debug NSLog(@"cell.bottomLine.frame = %@", NSStringFromCGRect(cell.bottomLine.frame));
        }
    } else {
        [self selectionButtonPressedFromRow:indexPath.row];
    }
}

#pragma mark TDGoalsCellDelegate
- (void)selectionButtonPressedFromRow:(NSInteger)row {
    debug NSLog(@"selection button pressed, change buttons");
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        if (cell.selectionButton.tag == 0) {
            [cell.selectionButton setImage:[UIImage imageNamed:@"checkbox_checked"] forState:UIControlStateNormal] ;
            NSAttributedString *str =
            [self makeTextWithString:cell.goalLabel.attributedText.string font:[TDConstants fontRegularSized:16] color:[TDConstants brandingRedColor] lineHeight:16. lineHeightMultipler:16/16];
            cell.goalLabel.attributedText = str;
            cell.selectionButton.tag = 1;
        } else {
            [cell.selectionButton setImage:[UIImage imageNamed:@"checkbox_empty"] forState:UIControlStateNormal];
            cell.selectionButton.tag = 0;
            NSAttributedString *attString = [self makeTextWithString:cell.goalLabel.attributedText.string font:[TDConstants fontRegularSized:16.] color:[TDConstants headerTextColor] lineHeight:16. lineHeightMultipler:16./16.];
            cell.goalLabel.attributedText = attString;
        }
    }
}

- (void)addGoals:(NSString*)text row:(NSInteger)row{
    [self.interestList addObject:text];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    TDGoalsCell *cell = (TDGoalsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionButton.hidden = NO;
        [cell.selectionButton setImage:[UIImage imageNamed:@"checkbox_checked"] forState:UIControlStateNormal];
        cell.selectionButton.tag = 1;
        cell.selectionButton.userInteractionEnabled = YES;
        [cell.selectionButton addTarget:self action:@selector(selectionButtonPressedFromRow:) forControlEvents:UIControlEventTouchUpInside];
        [cell.editableTextField resignFirstResponder];
        cell.goalLabel.attributedText = [self makeTextWithString:cell.editableTextField.text font:[TDConstants fontRegularSized:16] color:[TDConstants headerTextColor] lineHeight:16 lineHeightMultipler:16/16];
        cell.editableTextField.hidden = YES;
        cell.goalLabel.hidden = NO;
        cell.bottomLine.hidden = NO;
    }
    NSIndexPath *path1 = [NSIndexPath indexPathForRow:self.interestList.count inSection:0]; //ALSO TRIED WITH indexPathRow:0
    NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
}

- (void)addNewGoalPressed:(NSInteger)row {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark helper methods
- (NSAttributedString *)makeTextWithString:(NSString *)text font:(UIFont*)font color:(UIColor*)color lineHeight:(CGFloat)lineHeight lineHeightMultipler:(CGFloat)lineHeightMultiplier{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineHeightMultiple:lineHeightMultiplier];
    [paragraphStyle setMinimumLineHeight:lineHeight];
    [paragraphStyle setMaximumLineHeight:lineHeight];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, text.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, text.length)];
    return attributedString;
}

- (void)createHeaderLabel {
    self.headerLabel1.frame = CGRectMake(0,
                                         35,
                                         SCREEN_WIDTH,
                                         50);
    NSAttributedString *attString1 = [self makeTextWithString:topHeaderText1 font:[TDConstants fontSemiBoldSized:18.] color:[TDConstants headerTextColor] lineHeight:18. lineHeightMultipler:18/18];
    [self.headerLabel1 setTextAlignment:NSTextAlignmentLeft];
    [self.headerLabel1 setLineBreakMode:NSLineBreakByWordWrapping];
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
    NSAttributedString *attString2 = [self makeTextWithString:topHeaderText2 font:font2 color:[TDConstants headerTextColor] lineHeight:14.0 lineHeightMultipler:(14./14.0)];
    [self.headerLabel2 setTextAlignment:NSTextAlignmentLeft];
    [self.headerLabel2 setLineBreakMode:NSLineBreakByWordWrapping];
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



@end
