//
//  NSImage+Categary.h
//  自动打包器
//
//  Created by LT-MacbookPro on 17/6/30.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Categary)

+ (NSImage *)scaleImage:(NSImage *)image toSize:(NSSize)newSize proportionally:(BOOL)prop;

+ (NSImage*) resizeImage:(NSImage*)sourceImage size:(NSSize)size;


@end
