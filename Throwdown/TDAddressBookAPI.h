//
//  TDAddressBookAPI.h
//  Throwdown
//
//  Created by Stephanie Le on 10/2/14.
//  Copyright (c) 2014 Throwdown. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AddressBook;

@interface TDAddressBookAPI : NSObject
+ (TDAddressBookAPI *)sharedInstance;
- (void)addContactsToAddressBook:(ABAddressBookRef)addressBook;
- (NSArray*)getContactList;

@end
