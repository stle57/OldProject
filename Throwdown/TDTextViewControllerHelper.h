//
//  TDTextViewControllerHelper.h
//  Throwdown
//
//  Created by Stephanie Le on 7/5/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDTextViewControllerHelper : NSObject

+(int)findUsernameLength:(NSString*)currentText;
+(NSString*)getUserNameList:(NSString*)text length:(int)userNameLength;
@end
