//
//  TDMoreComments.h
//  Throwdown
//
//  Created by Andrew Bennett on 3/24/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDMoreCommentsDelegate <NSObject>
@optional
@end

@interface TDMoreComments : UITableViewCell
{
    id <TDMoreCommentsDelegate> __unsafe_unretained delegate;
    NSInteger row;
    CGRect origMoreLabelRect;
}

@property (nonatomic, assign) id <TDMoreCommentsDelegate> __unsafe_unretained delegate;
@property (nonatomic, assign) NSInteger row;
@property (weak, nonatomic) IBOutlet UIImageView *moreImageView;
@property (weak, nonatomic) IBOutlet UILabel *moreLabel;

-(void)moreCount:(NSInteger)count;
@end
