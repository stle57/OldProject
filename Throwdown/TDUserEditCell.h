//
//  TDUserEditCell.h
//  Throwdown
//
//  Created by Andrew Bennett on 4/9/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDUserEditCellDelegate <NSObject>
@optional
@end

@interface TDUserEditCell : UITableViewCell
{
    id <TDUserEditCellDelegate> __unsafe_unretained delegate;
}

@property (nonatomic, assign) id <TDUserEditCellDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *middleLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftMiddleLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end
