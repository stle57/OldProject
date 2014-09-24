//
//  TDContactInfo.h
//  Throwdown
//
//  Created by Stephanie Le on 9/18/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDContactInfo : NSObject

@property (nonatomic) NSInteger id;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (nonatomic) NSMutableArray *phoneList;
@property (nonatomic) NSMutableArray *emailList;
@property (strong, nonatomic) UIImage *contactPicture;
@property (strong, nonatomic) NSString *fullName;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *selectedData;
@property (nonatomic) BOOL following;
@end
