//
//  MaxCDNURLPlugin.m
//  MaxCDN Coda 2 Plug-in
//

#import "MaxCDNURLPlugin.h"
#import "CodaPlugInsController.h"

NSString * const kDefaultsURLKey = @"MaxCDNURL";
NSString * const kExtensionJoinString = @"|";
NSString * const kProtocolRegex = @"(ftp|http(s))";
NSString * const kSheetXIB = @"URLSheet";
NSString * const kURLRegex = @"([^\\s|\"|'|=|(]+.(%@))";

@interface MaxCDNURLPlugin()
{
    CodaPlugInsController *controller;
    CodaTextView *textView;
    
    NSArray *supportedFileExtensions;
}

@property (assign) IBOutlet NSWindow *sheet;
@property (unsafe_unretained) IBOutlet NSTextField *messageLabel;
@property (unsafe_unretained) IBOutlet NSTextField *URLLabel;
@property (unsafe_unretained) IBOutlet NSTextField *URLTextField;
@property (unsafe_unretained) IBOutlet NSButton *cancelButton;
@property (unsafe_unretained) IBOutlet NSButton *saveButton;

- (id)initWithController:(CodaPlugInsController*)inController;
- (IBAction)closeSheet:(id)sender;
- (IBAction)saveURL:(id)sender;
@end

@implementation MaxCDNURLPlugin

#pragma -
#pragma CodaPlugiInsController Callbacks

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

    [self initializePlugin];
        
	return self;
}

- (NSString*)name
{
	return [self localizedStringForKey:@"plugin-name"];
}

- (void)textViewDidFocus:(CodaTextView *)aTextView;
{
    textView = aTextView;
}

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    BOOL result = YES;
    
    // Disable the Insert menu item if the editor doesn't have focus
	if ([aMenuItem title] == [self localizedStringForKey:@"menu-item-2-title"])
	{
		CodaTextView *tv = [controller focusedTextView:self];
        
		if (tv == nil)
			result = NO;
	}
    
	return result;
}

#pragma -
#pragma Methods

- (void)initializePlugin
{    
    // Register menu items
    [controller registerActionWithTitle:[self localizedStringForKey:@"menu-item-1-title"]
                  underSubmenuWithTitle:nil
                                 target:self
                               selector:@selector(showURLSheet:)
                      representedObject:self
                          keyEquivalent:nil
                             pluginName:[self localizedStringForKey:@"plugin-name"]];
    
    [controller registerActionWithTitle:[self localizedStringForKey:@"menu-item-2-title"]
                  underSubmenuWithTitle:nil
                                 target:self
                               selector:@selector(insertURL:)
                      representedObject:self
                          keyEquivalent:[self localizedStringForKey:@"menu-item-2-key-command"]
                             pluginName:[self localizedStringForKey:@"plugin-name"]];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    supportedFileExtensions = [[bundle infoDictionary] objectForKey:@"SupportedFileExtensions"];
}


#pragma -
#pragma Actions

- (IBAction)closeSheet:(id)sender
{
    [NSApp endSheet:_sheet];
    [_sheet orderOut:sender];
}

- (IBAction)saveURL:(id)sender
{
    [self closeSheet:sender];
    
    // Save URL
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[_URLTextField stringValue] forKey:kDefaultsURLKey];
}

- (void)showURLSheet:(id)sender
{
    if (_sheet == nil)
    {
        [NSBundle loadNibNamed:kSheetXIB owner:self];
        
        // Localize labels
        [_messageLabel setStringValue:[self localizedStringForKey:@"sheet-message"]];
        [_URLLabel setStringValue:[self localizedStringForKey:@"sheet-url-label"]];
        [[_URLTextField cell] setPlaceholderString:[self localizedStringForKey:@"sheet-url-text-field-placeholder"]];
        [_cancelButton setStringValue:[self localizedStringForKey:@"sheet-cancel-button"]];
        [_saveButton setStringValue:[self localizedStringForKey:@"sheet-save-button"]];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:kDefaultsURLKey] != nil)
        [_URLTextField setStringValue:[defaults valueForKey:kDefaultsURLKey]];

    [NSApp beginSheet:_sheet
       modalForWindow:[textView window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}

- (void)insertURL:(id)sender
{
    NSString *extensions = [supportedFileExtensions componentsJoinedByString:kExtensionJoinString];
    NSString *regex = [NSString stringWithFormat:kURLRegex, extensions];
    NSMutableString *mutableString = [NSMutableString stringWithString:[textView string]];
    
    [mutableString enumerateStringsMatchedByRegex:regex usingBlock:^(NSInteger captureCount,
                                                                     NSString * const capturedStrings[captureCount],
                                                                     const NSRange capturedRanges[captureCount],
                                                                     volatile BOOL *const stop)
     {
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         NSString *CDNURL = [defaults objectForKey:kDefaultsURLKey];
         
         if ([[capturedStrings[0] componentsMatchedByRegex:kProtocolRegex] count] == 0)
         {
             
             NSString *URLPrefix = [CDNURL hasSuffix:@"/"] ? CDNURL : [CDNURL stringByAppendingString:@"/"];
             NSString *updatedMatch = [capturedStrings[0] hasPrefix:@"/"] ? [capturedStrings[0] substringFromIndex:1] : capturedStrings[0];
             NSString *newURL = [NSString stringWithFormat:@"%@%@", URLPrefix, updatedMatch];
             
             [textView replaceCharactersInRange:capturedRanges[0] withString:newURL];
         }
     }];
}

#pragma -
#pragma Helpers

- (BOOL)isSupportedFileExtension
{
    textView = [controller focusedTextView:self];
    
    if ([textView path])
        return [supportedFileExtensions containsObject:[[textView path] pathExtension]];
    
    return NO;
}

- (NSString *)localizedStringForKey:(NSString *)key
{
    return NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], nil);
}

@end
