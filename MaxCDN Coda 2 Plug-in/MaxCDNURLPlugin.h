//
//  MaxCDNURLPlugin.h
//  MaxCDN Coda 2 Plug-in
//
//  Created by Joe Dakroub on 4/17/13.
//  Copyright (c) 2013 MaxCDN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CodaPlugInsController.h"

@class CodaPlugInsController;

@interface MaxCDNURLPlugin : NSObject <CodaPlugIn>
{
    CodaPlugInsController *controller;
    CodaTextView *textView;

    NSArray *supportedFileExtensions;
}

@end
