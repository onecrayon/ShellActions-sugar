//
//  NSMutableDictionary+OCSettingAdditions.h
//  ShellActions.sugar
//
//  Created by Ian Beck on 2/23/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import <Foundation/Foundation.h>


@interface NSMutableDictionary (OCSettingAdditions)

- (BOOL)addObjectOrEmptyString:(id)myObject forKey:(NSString *)myKey;

@end
