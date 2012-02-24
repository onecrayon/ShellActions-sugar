//
//  NSObject+OCTextActionContextAdditions.h
//  ShellActions.sugar
//
//  Created by Ian Beck on 12/14/10.
//  Copyright 2010 Ian Beck. MIT license.
//

#import <Cocoa/Cocoa.h>


@interface NSObject (OCTextActionContextAdditions)

- (NSString *)getWordAtIndex:(NSUInteger)cursor range:(NSRange *)range;
- (NSString *)getWordAtIndex:(NSUInteger)cursor allowExtraCharacters:(NSCharacterSet *)extraChars range:(NSRange *)range;

@end
