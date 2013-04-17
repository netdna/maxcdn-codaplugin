//
//  MaxCDNURLPlugin.m
//  MaxCDN Coda 2 Plug-in
//
//  Created by Joe Dakroub <joe.dakroub@me.com> on 4/17/13.
//  Copyright (c) 2013 MaxCDN. All rights reserved.
//

#import "MaxCDNURLPlugin.h"
#import "CodaPlugInsController.h"

NSString * const kPluginName = @"HTML Entities";
NSString * const kMenuItemTitle = @"Insert HTML Entity...";
NSString *stringToBeEncoded = @"";

@interface MaxCDNURLPlugin()
- (id)initWithController:(CodaPlugInsController*)inController;
@end

@implementation MaxCDNURLPlugin

//2.0 and lower
- (id)initWithPlugInController:(CodaPlugInsController*)aController bundle:(NSBundle*)aBundle
{
    return [self initWithController:aController];
}

//2.0.1 and higher
- (id)initWithPlugInController:(CodaPlugInsController*)aController plugInBundle:(NSObject <CodaPlugInBundle> *)plugInBundle
{
    return [self initWithController:aController];
}

- (id)initWithController:(CodaPlugInsController*)inController
{
	if (!(self = [super init]))
        return nil;
    
    controller = inController;
    textView = [controller focusedTextView:self];
    [self textViewDidFocus:textView];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    supportedFileExtensions = [[bundle infoDictionary] objectForKey:@"SupportedFileExtensions"];
    
	return self;
}

- (NSString*)name
{
	return kPluginName;
}

- (void)addTextViewObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textViewDidChange:)
                                                 name:NSTextDidChangeNotification
                                               object:nil];
}

- (void)textViewDidFocus:(CodaTextView *)aTextView;
{
    textView = aTextView;
    
    [self addTextViewObservers];
}

- (void)textViewDidChange:(NSNotification *)notification
{
    id codeTextView = [notification object];
    
    if (codeTextView == nil)
        return;
    
    if ([codeTextView rangeForUserTextChange].location == NSNotFound ||
        [codeTextView rangeForUserTextChange].location == 0)
        return;
    
    NSRange previousCharacterRange = NSMakeRange([codeTextView rangeForUserTextChange].location - 1, 1);
    
    if (previousCharacterRange.location == NSNotFound)
        return;
    
    NSString *character = [[[codeTextView textStorage] string] substringWithRange:previousCharacterRange];
    
    if ([self canBeEncoded:character])
    {
        textView = [controller focusedTextView:self];
        
        [textView beginUndoGrouping];
        
        [textView setSelectedRange:previousCharacterRange];
        [self encodeHTMLEntities];
        
        [textView endUndoGrouping];
        
        [textView setSelectedRange:NSMakeRange([codeTextView rangeForUserTextChange].location +
                                               [codeTextView selectedRange].length, 0)];
    }
}

#pragma -
#pragma HTML Entities helpers

- (BOOL)isSupportedFileExtension
{
    textView = [controller focusedTextView:self];
    
    if ([textView path])
        return [supportedFileExtensions containsObject:[[textView path] pathExtension]];
    
    NSArray *titleParts = [[[textView window] title] componentsSeparatedByString:@" - "];
    
    return [supportedFileExtensions containsObject:[[titleParts objectAtIndex:0] pathExtension]];
}

- (BOOL)canBeEncoded:(NSString *)string
{
    BOOL canBeEncoded = YES;
    
    if ( ! [self isSupportedFileExtension])
        return NO;
    
    if ([string length] != 1 || string == nil)
        return NO;
    
    NSArray *characterSets = [NSArray arrayWithObjects:
                              [NSCharacterSet characterSetWithCharactersInString:@"`~!@#$%^&*()_-+={[}]|\\:;\"'<,>.?/"],
                              [NSCharacterSet controlCharacterSet],
                              [NSCharacterSet decimalDigitCharacterSet],
                              [NSCharacterSet letterCharacterSet],
                              [NSCharacterSet newlineCharacterSet],
                              [NSCharacterSet nonBaseCharacterSet],
                              [NSCharacterSet whitespaceAndNewlineCharacterSet], nil];
    
    for (NSCharacterSet *charSet in characterSets)
    {
        if ([string rangeOfCharacterFromSet:charSet].location != NSNotFound)
            canBeEncoded = NO;
    }
    
    return canBeEncoded;
}

- (void)encodeHTMLEntities
{
    textView = [controller focusedTextView:self];
    
    NSMenuItem *textMenuItem = [[[textView window] menu] itemAtIndex:4];
    NSMenu *textMenu = [textMenuItem submenu];
    NSMenuItem *processingMenuItem = [textMenu itemAtIndex:9];
    NSMenu *processingMenu = [processingMenuItem submenu];
    
    [processingMenu performActionForItemAtIndex:0];
}

@end
