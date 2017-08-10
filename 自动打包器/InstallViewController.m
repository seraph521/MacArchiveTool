//
//  InstallViewController.m
//  自动打包器
//
//  Created by LT-MacbookPro on 17/6/29.
//  Copyright © 2017年 XFX. All rights reserved.
//

#import "InstallViewController.h"
#import "SSZipArchive.h"

#define color    [NSColor colorWithRed:24/255.0 green:151/255.0 blue:24/255.0 alpha:1]
#define failcolor    [NSColor colorWithRed:252/255.0 green:54/255.0 blue:86/255.0 alpha:1]
@interface InstallViewController ()

@property(nonatomic,strong) NSTimer * timer;
@property (weak) IBOutlet NSTextField *logsLabel;

@property (weak) IBOutlet NSTextField *stateLabel;
@end

@implementation InstallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startInstall];
}

- (void) startInstall{
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(loadingLog) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    //0 检测build文件夹下是否有ipa文件
    NSString * ipa = [self.projectName stringByAppendingString:@".ipa"];
    NSString * pathStr = [NSString stringWithFormat:@"%@build/%@",self.pathString,ipa];
    BOOL isSuccess = [fileManager fileExistsAtPath:pathStr];
    if(!isSuccess){
    
        self.logsLabel.stringValue = @"项目路径/build/下未找到ipa文件！";
        return;
    }
    
    // 1 写入fruitstrap.zip 并解压
        NSString * path = [[NSBundle mainBundle] pathForResource:@"fruitstrap.zip" ofType:nil];
        NSData * fruitstrapData = [NSData dataWithContentsOfFile:path];
        NSString * filePath = [NSString stringWithFormat:@"%@build/fruitstrap.zip",self.pathString];
        [fruitstrapData writeToFile:filePath atomically:YES];
    
        NSString * dirPath = [NSString stringWithFormat:@"%@/build/",self.pathString];
    
        [SSZipArchive unzipFileAtPath:filePath toDestination:dirPath];
    
    //2 安装命令
        NSString * ipaName = [self.projectName stringByAppendingString:@".ipa"];
    
        NSString * cmd = [NSString stringWithFormat:@"cd %@; ./fruitstrap -b %@ > log.txt",dirPath,ipaName];//> log.txt
    
        NSLog(@"===-----cmd-%@",cmd);
    // 3 子线程安装
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        system([cmd UTF8String]);
            
        });
}


- (void)loadingLog{
    
    NSLog(@"=========loadingLog");
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * pathStr = [NSString stringWithFormat:@"%@build/log.txt",self.pathString];
    NSString * dirPath = [NSString stringWithFormat:@"%@/build/",self.pathString];

    BOOL isSuccess = [fileManager fileExistsAtPath:pathStr];
    if(isSuccess){
            NSString * log = [NSString stringWithContentsOfFile:pathStr encoding:NSUTF8StringEncoding error:nil];
            self.logsLabel.stringValue = log;
        
        if([log containsString:@"100%"]){
            self.stateLabel.stringValue = @"安装完成！";
            self.stateLabel.textColor = color;
            [self.timer invalidate];
            self.timer = nil;
            //删除中间文件
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"fruitstrap.zip"] error:nil];
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"fruitstrap"] error:nil];
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"log.txt"] error:nil];
        }
        
        if([log containsString:@"failed"]){
        
            self.stateLabel.stringValue = @"安装失败！";
            self.stateLabel.textColor = failcolor;
            [self.timer invalidate];
            self.timer = nil;
            //删除中间文件
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"fruitstrap.zip"] error:nil];
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"fruitstrap"] error:nil];
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"log.txt"] error:nil];
        }
    }


}

- (void)viewWillDisappear{

    [super viewWillDisappear];
    [self.timer invalidate];
    self.timer = nil;
}

@end
