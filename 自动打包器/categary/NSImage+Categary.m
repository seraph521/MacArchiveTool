//
//  NSImage+Categary.m
//  自动打包器
//
//  Created by LT-MacbookPro on 17/6/30.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "NSImage+Categary.h"

@implementation NSImage (Categary)

+ (NSImage *)scaleImage:(NSImage *)image toSize:(NSSize)newSize proportionally:(BOOL)prop
{
    if (image) {
        NSImage *copy = [image copy];
        NSSize size = [copy size];
        
        if (prop) {
            float rx, ry, r;
            
            rx = newSize.width / size.width;
            ry = newSize.height / size.height;
            r = rx < ry ? rx : ry;
            size.width *= r;
            size.height *= r;
        } else
            size = newSize;
        
        [copy setScalesWhenResized:YES];
        [copy setSize:size];
        
        return copy;
    }
    return nil; // or 'image' if you prefer.
}

+ (NSImage*) resizeImage:(NSImage*)sourceImage size:(NSSize)size
{
    
    NSRect targetFrame = NSMakeRect(0, 0, size.width, size.height);
    NSImage* targetImage = nil;
    NSImageRep *sourceImageRep =
    [sourceImage bestRepresentationForRect:targetFrame
                                   context:nil
                                     hints:nil];
    
    targetImage = [[NSImage alloc] initWithSize:size];
    
    [targetImage lockFocus];
    [sourceImageRep drawInRect: targetFrame];
    [targetImage unlockFocus];
    
    return targetImage;
}

@end
