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
    CGRect textViewdOrigRect;
    CGFloat bottomLineOrigY;
    CGFloat topLineOrigHeight;
    CGFloat bottomLineOrigHeight;
}

@property (nonatomic, assign) id <TDUserEditCellDelegate> __unsafe_unretained delegate;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *longTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *middleLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftMiddleLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIView *topLine;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *rightArrow;
@property (nonatomic, assign) CGRect textViewdOrigRect;
@property (nonatomic, assign) CGFloat bottomLineOrigY;
@property (nonatomic, assign) CGFloat topLineOrigHeight;
@property (nonatomic, assign) CGFloat bottomLineOrigHeight;
@property (nonatomic) NSURL *userImageURL;


@end
