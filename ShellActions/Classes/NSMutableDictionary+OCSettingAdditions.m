//
//  NSMutableDictionary+OCSettingAdditions.m
//  ShellActions.sugar
//
//  Created by Ian Beck on 2/23/12.
//  Copyright 2012 Ian Beck. MIT license.
//

#import "NSMutableDictionary+OCSettingAdditions.h"


@implementation NSMutableDictionary (OCSettingAdditions)

- (BOOL)addObjectOrEmptyString:(id)myObject forKey:(NSString *)myKey {
	// If myKey is nil, sending it the length method will return 0
	if (myKey.length == 0) {
		return NO;
	}
	if (myObject == nil) {
		myObject = @"";
	}
	[self setObject:myObject forKey:myKey];
	return YES;
}

@end
