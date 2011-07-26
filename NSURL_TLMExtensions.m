//
//  NSURL_TLMExtensions.m
//  TeX Live Manager
//
//  Created by Adam R. Maxwell on 07/15/11.
/*
 This software is Copyright (c) 2010-2011
 Adam Maxwell. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 
 - Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the
 distribution.
 
 - Neither the name of Adam Maxwell nor the names of any
 contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSURL_TLMExtensions.h"
#import "TLMLogServer.h"

#define TLPDB_PATH  @"tlpkg/texlive.tlpdb"
#define MULTIPLEXER @"mirror.ctan.org"
#define TLNET_PATH  @"systems/texlive/tlnet"

@implementation NSURL (TLMExtensions)

+ (NSURL *)databaseURLForTLNetURL:(NSURL *)mirrorURL;
{
    return [mirrorURL tlm_URLByAppendingPathComponent:TLPDB_PATH];
}

+ (NSURL *)TLNetURLForMirror:(NSURL *)mirrorURL;
{
    return [mirrorURL tlm_URLByAppendingPathComponent:TLNET_PATH];
}

+ (BOOL)writeURLs:(NSArray *)array toPasteboard:(NSPasteboard *)pboard;
{
    OSStatus err;
    
    PasteboardRef carbonPboard;
    err = PasteboardCreate((CFStringRef)[pboard name], &carbonPboard);
    
    if (noErr == err)
        err = PasteboardClear(carbonPboard);
    
    if (noErr == err)
        (void)PasteboardSynchronize(carbonPboard);
    
    if (noErr != err) {
        TLMLog(__func__, @"failed to setup pboard %@: %s", [pboard name], GetMacOSStatusErrorString(err));
        return NO;
    }
    
    for (NSURL *aURL in array) {
        
        CFDataRef utf8Data = (CFDataRef)[[aURL absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
        
        // any pointer type; private to the creating application
        PasteboardItemID itemID = (void *)aURL;
        
        // Finder adds a file URL and destination URL for weblocs, but only a file URL for regular files
        // could also put a string representation of the URL, but Finder doesn't do that
        
        if ([aURL isFileURL]) {
            err = PasteboardPutItemFlavor(carbonPboard, itemID, kUTTypeFileURL, utf8Data, kPasteboardFlavorNoFlags);
        }
        else {
            err = PasteboardPutItemFlavor(carbonPboard, itemID, kUTTypeURL, utf8Data, kPasteboardFlavorNoFlags);
        }
        
        if (noErr != err)
            TLMLog(__func__, @"failed to write to pboard %@: %s", [pboard name], GetMacOSStatusErrorString(err));
    }
    
    ItemCount itemCount;
    err = PasteboardGetItemCount(carbonPboard, &itemCount);
    
    if (carbonPboard) 
        CFRelease(carbonPboard);
    
    return noErr == err && itemCount > 0;
}

- (BOOL)isMultiplexer;
{
    return [[[self host] lowercaseString] isEqualToString:MULTIPLEXER];
}

- (NSURL *)tlm_URLByDeletingLastPathComponent;
{
    return [(id)CFURLCreateCopyDeletingLastPathComponent(CFGetAllocator((CFURLRef)self), (CFURLRef)self) autorelease];
}

- (NSURL *)tlm_URLByAppendingPathComponent:(NSString *)pathComponent;
{
    NSParameterAssert(pathComponent);
    CFAllocatorRef alloc = CFGetAllocator((CFURLRef)self);
    return [(id)CFURLCreateCopyAppendingPathComponent(alloc, (CFURLRef)self, (CFStringRef)pathComponent, FALSE) autorelease];
}

// CFURL is pretty stupid about equality.  Among other things, it considers a double slash directory separator significant.
- (NSURL *)tlm_normalizedURL;
{
    NSURL *aURL = self;
    NSMutableString *str = [[aURL absoluteString] mutableCopy];
    NSRange startRange = [str rangeOfString:@"//"];
    NSUInteger start = NSMaxRange(startRange);
    if (startRange.length && [str replaceOccurrencesOfString:@"//" withString:@"/" options:NSLiteralSearch range:NSMakeRange(start, [str length] - start)])
        aURL = [NSURL URLWithString:str];
    [str release];
    return aURL;
}

@end