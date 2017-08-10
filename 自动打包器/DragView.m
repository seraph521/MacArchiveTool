//
//  DragView.m
//  自动打包器
//
//  Created by LT-MacbookPro on 17/6/26.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "DragView.h"
#define D_GrayColor3 [NSColor colorWithSRGBRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.01]

@interface DragView ()<NSDraggingDestination>{
 BOOL isDragIn;
}

@end

@implementation DragView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        NSTextField * label = [[NSTextField alloc] init];
        //358, 56
        [label setBordered:NO];
        [label setEditable:NO];
        [label setSelectable:NO];
        label.frame = CGRectMake(130, 20, 150, 20);
        label.backgroundColor = [NSColor clearColor];
        label.stringValue = @"支持拖拽文件到此处";
        //[self addSubview:label];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    [D_GrayColor3 setFill];
    NSRectFill(dirtyRect);
    
    if (isDragIn)
    {
        NSColor* color = [NSColor colorWithRed:100.0 / 255 green:100.0 / 255 blue:220.0 / 255 alpha:1.0];
        [color set];
        NSBezierPath* thePath = [NSBezierPath bezierPath];
        [thePath appendBezierPathWithRoundedRect:dirtyRect xRadius:8.0 yRadius:8.0];
        [thePath fill];
    }
    
}


#pragma mark - Destination Operations

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    isDragIn = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationCopy;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    isDragIn = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    isDragIn = NO;
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    if ([sender draggingSource] != self)
    {
        NSArray* filePaths = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
        NSString * path = [filePaths lastObject];
        if([self.delegate respondsToSelector:@selector(handleDragViewWithPath:)]){
            [self.delegate handleDragViewWithPath:path];
        }
        
    }
    
    return YES;
}

@end
