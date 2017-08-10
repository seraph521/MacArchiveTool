//
//  ViewController.m
//  自动打包器
//
//  Created by LT-MacbookPro on 17/6/20.
//  Copyright © 2017年 XFX. All rights reserved.
//找不到request module，参考stackoverflow, 使用 $ sudo pip install requests或者sudo easy_install -U requests;
// ./fruitstrap -b Unity-iPhone.ipa //com.joym.armorhero2
//iPhone Developer "CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Distribution";
//CODE_SIGN_IDENTITY = "iPhone Developer: Ping Zhao (2WA888YLVC)";
//"CODE_SIGN_IDENTITY[sdk=*]" = "iPhone Developer: Ping Zhao (2WA888YLVC)";
//"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Distribution";

//open -a /Users/lt-macbookpro/Desktop/自动打包器.app --args /Users/lt-macbookpro/Desktop/XuFeiXiang/JJXD/JJXDiOS

#import "ViewController.h"
#import "DJProgressHUD.h"
#import "DragView.h"
#import "SSZipArchive.h"
#import "InstallViewController.h"
#import "NSImage+Categary.h"
#import "ArchieveTool.h"
#define successColor    [NSColor colorWithRed:24/255.0 green:151/255.0 blue:24/255.0 alpha:1]

#define middleColor    [NSColor colorWithRed:58/255.0 green:155/255.0 blue:252/255.0 alpha:1]

#define failColor    [NSColor colorWithRed:252/255.0 green:54/255.0 blue:86/255.0 alpha:1]

#define labelColor    [NSColor colorWithRed:122/255.0 green:117/255.0 blue:115/255.0 alpha:1]


@interface ViewController ()<NSXMLParserDelegate,DragViewDelegate,NSComboBoxDelegate,NSTextFieldDelegate,NSControlTextEditingDelegate>
@property (weak) IBOutlet NSButton *selectPathBtn;
@property (weak) IBOutlet NSButton *startBtn;
@property (weak) IBOutlet NSButton *isDebugBtn;
@property (weak) IBOutlet NSTextField *bundleIDLabel;
@property (weak) IBOutlet NSTextField *displayNameLabel;
@property (weak) IBOutlet NSTextField *pathLabel;
@property (weak) IBOutlet NSTextField *tipMsgLabel;
@property (weak) IBOutlet NSTextField *selectMPLabel;
@property (weak) IBOutlet NSPopUpButton *selectMPBtn;
@property (weak) IBOutlet NSTextField *stateLabel;

@property (weak) IBOutlet NSTextField *versionLabel;

@property (weak) IBOutlet NSTextField *buildLabel;

@property (weak) IBOutlet NSTextField *versionValueLabel;

@property (weak) IBOutlet NSTextField *buildValueLabel;
@property (weak) IBOutlet NSTextField *achieveStateLabel;
@property (weak) IBOutlet NSButton *installBtn;
@property (weak) IBOutlet NSButton *refreshBundleIdBtn;
@property (weak) IBOutlet NSComboBox *bundleIDBox;
@property (weak) IBOutlet NSTextField *projectPathLabel;
@property (weak) IBOutlet NSTextField *projectIdLabel;
@property (weak) IBOutlet NSTextField *projectNameLabel;
@property (weak) IBOutlet NSTextField *tipsLabel;
@property (weak) IBOutlet NSProgressIndicator *progressBar;

@property(nonatomic,copy) NSString * projectName;
@property(nonatomic,copy) NSString * convertedString;//project.pbxproj文件字符串
@property(nonatomic,copy) NSString * projectFullName;
@property(nonatomic,assign) BOOL isXcodeproj;
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, copy) NSString * currentElement;
@property (nonatomic, copy) NSString * bundleID;
@property (nonatomic, copy) NSString * displayName;
@property (nonatomic, assign) int index;

@property (nonatomic, copy) NSString * pythonName;
@property (nonatomic, copy) NSString * ipaName;//打包完成后ipa名称

@property (nonatomic, copy) NSString * plistName;
@property (nonatomic, assign) BOOL isNameType;
@property (nonatomic, copy) NSString * bundleString;
@property (nonatomic, copy) NSString * oldBundleId;//切换包名前的bundleid

@property (nonatomic,strong) NSMutableArray * mobileProvisionArray;
@property (nonatomic, strong)NSMutableArray * selectProductProfile;
@property (nonatomic, strong)NSMutableArray * allBundleIdArray;//存放描述文件相关字典
@property (nonatomic, strong)NSMutableSet * fullBundleIdSet;//存放描述文件包含的bundleid不重复
@property(nonatomic,strong)NSMutableDictionary * pbxprojSettingDic;//project.pbxproj需要修改的value
@property(nonatomic,strong) NSMutableArray * comboxItemArray;
@property(nonatomic,strong) NSTimer * timer;
@property (nonatomic, assign) BOOL isAppStoreType;

@property (nonatomic, copy) NSString * rootPath;//项目路径


//记录修改前project.pbxproj关键值
@property(nonatomic,copy) NSString * oldName;
@property(nonatomic,copy) NSString * oldTeam;
@property(nonatomic,copy) NSString * oldUuid;
@property(nonatomic,copy) NSString * oldType;

@end

@implementation ViewController

- (NSMutableArray *)selectProductProfile{

    if(_selectProductProfile == nil){
    
        _selectProductProfile = [NSMutableArray array];
    }
    return _selectProductProfile;
}

- (NSMutableArray *) mobileProvisionArray{

    if(_mobileProvisionArray == nil){
        
        //遍历Xcode中所有的MobileProvision描述文件
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/ls"];
        [task setCurrentDirectoryPath:@"~/Library/MobileDevice/Provisioning Profiles/"];
        NSArray *arguments;
        arguments = [NSArray arrayWithObjects: @"-m", nil];
        [task setArguments: arguments];
        
        NSPipe *pipe;
        pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];
        
        NSFileHandle *file = [pipe fileHandleForReading];
        [task launch];
        
        NSData *data = [file readDataToEndOfFile];
        NSString *resultStr = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        resultStr = [resultStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        resultStr = [resultStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        resultStr = [resultStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *array = [resultStr componentsSeparatedByString:@","];
        NSLog(@"array >>> %@",  array);
       
        _mobileProvisionArray = [NSMutableArray arrayWithArray:array];
        
        NSArray *arguments2;
        NSPipe *pipe2 = [NSPipe pipe];
        self.allBundleIdArray = [NSMutableArray array];
        self.fullBundleIdSet = [NSMutableSet set];
        if (_mobileProvisionArray)
        {
            //解析所有的MobileProvision描述文件，转成可以阅读的xml格式
            for (NSString *name in self.mobileProvisionArray)
            {
                NSTask *task2 = [[NSTask alloc] init];
                [task2 setLaunchPath:@"/usr/bin/security"];
                [task2 setCurrentDirectoryPath:@"~/Library/MobileDevice/Provisioning Profiles/"];
                arguments2 = [NSArray arrayWithObjects: @"cms", @"-D", @"-i", name, nil];
                [task2 setArguments: arguments2];
                pipe2 = [NSPipe pipe];
                [task2 setStandardOutput: pipe2];
                NSFileHandle *file2 = [pipe2 fileHandleForReading];
                [task2 launch];
                NSData *data2 = [file2 readDataToEndOfFile];
                NSString *resultStr = [[NSString alloc] initWithData:data2 encoding: NSUTF8StringEncoding];
                //在每个MobileProvision描述文件中，找出与bundle id对应的描述文件
                NSData* plistData = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
                NSPropertyListFormat format;
                NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:nil];
                if (plist)
                {
                    if ([plist objectForKey:@"Entitlements"])
                    {
                        NSDictionary* plistChildDic = (NSDictionary *)[plist objectForKey:@"Entitlements"];
                        if (plistChildDic)
                        {
                            NSString* value = [plistChildDic objectForKey:@"application-identifier"];
                      //      NSString* bundleId ;//= self.bundleID;//@"com.lili.look";
                            //   plutil -convert xml1 -s -r -o converted.xml  Unity-iPhone.xcodeproj/project.pbxproj
                     //       if(self.isNameType){
                    //            bundleId = [self.bundleString stringByReplacingOccurrencesOfString:@"${PRODUCT_NAME}" withString:self.bundleID];//self.bundleID;//${PRODUCT_NAME}
                     
                     //       }else{
                     //           bundleId = self.bundleID;
                                
                    //        }
                            
                            if(value){
                               
                                NSString* provisionName = [plist valueForKey:@"Name"];
                                NSString* uuid = [plist valueForKey:@"UUID"];
                                NSLog(@"provisionName >>> %@", provisionName);
                                
                                NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
                                [tempDic setObject:provisionName forKey:@"name"];
                                [tempDic setObject:uuid forKey:@"uuid"];
                                if ([plist valueForKey:@"ProvisionedDevices"])
                                {
                                    [tempDic setObject:@"0" forKey:@"appstore"];
                                }
                                else
                                {
                                    [tempDic setObject:@"1" forKey:@"appstore"];
                                }
                                
                                NSArray *array = [value componentsSeparatedByString:@"."];
                                
                                NSString * headString = array[0];
                                NSString * ID = [value substringFromIndex:headString.length+1];
                                [tempDic setObject:ID forKey:@"bundleid"];

                                [tempDic setObject:headString forKey:@"team"];
                                
                                NSString * teamName = [plist valueForKey:@"TeamName"];
                                [tempDic setObject:teamName forKey:@"TeamName"];
                                
                                if(ID.length>2){//过滤*的包名
                                    [self.allBundleIdArray addObject:tempDic];
                                    [self.fullBundleIdSet addObject:ID];
                                }
                               
                                
                            }
                            
                        }
                    }
                }
                
            }
        }

    }
    NSLog(@"=========allBundleIdArray=%@",self.allBundleIdArray);
    return _mobileProvisionArray;
}
//导出ipa完成后安装到设备
- (IBAction)installToDevice:(NSButton *)sender {
    
    NSLog(@"-------installToDevice--------");
    [self.progressBar setHidden:YES];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    //0 检测build文件夹下是否有ipa文件
    NSString * ipa = [self.displayNameLabel.stringValue stringByAppendingString:@".ipa"];
    NSString * pathStr = [NSString stringWithFormat:@"%@build/%@",self.rootPath,ipa];
    BOOL isSuccess = [fileManager fileExistsAtPath:pathStr];
    if(!isSuccess){
        
        [self handleStartBtn:self.startBtn];
        //[self installToDevice:self.installBtn];
        
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"确定"];
        [alert addButtonWithTitle:@"取消"];
        [alert setMessageText:@"提示"];
        [alert setInformativeText:@"项目路径/build/下未找到ipa文件！"];
        [alert setAlertStyle:NSWarningAlertStyle];
       // [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
         //   if(returnCode == NSAlertFirstButtonReturn){
         //       NSLog(@"确定");
         //       [self.progressBar setHidden:YES];
         //       return ;
         //   }else if(returnCode == NSAlertSecondButtonReturn){
         //       NSLog(@"删除");
         //       [self.progressBar setHidden:YES];
         //       return ;
        //    }
       // }];

        return;
    }
    
    //开始安装
    
    [DJProgressHUD showProgress:0.1 withStatus:@"" FromView:self.view];

    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(loadingLog) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    // 1 写入fruitstrap.zip 并解压
    NSString * path = [[NSBundle mainBundle] pathForResource:@"fruitstrap.zip" ofType:nil];
    NSData * fruitstrapData = [NSData dataWithContentsOfFile:path];
    NSString * filePath = [NSString stringWithFormat:@"%@build/fruitstrap.zip",self.rootPath];
    [fruitstrapData writeToFile:filePath atomically:YES];
    
    NSString * dirPath = [NSString stringWithFormat:@"%@build/",self.rootPath];
    
    [SSZipArchive unzipFileAtPath:filePath toDestination:dirPath];
    
    //ipa有中文可能安装不成功
    NSString * renamePath = [NSString stringWithFormat:@"%@build/1.ipa",self.rootPath];
    [fileManager moveItemAtPath:pathStr toPath:renamePath error:nil];
    //2 安装命令
  //  NSString * ipaName = [self.displayNameLabel.stringValue stringByAppendingString:@".ipa"];
    
    NSString * cmd = [NSString stringWithFormat:@"cd %@; ./fruitstrap -b 1.ipa > log.txt",dirPath];//> log.txt
    
    NSLog(@"===-----cmd-%@",cmd);
    // 3 子线程安装
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        system([cmd UTF8String]);
        //名称改回来
        [fileManager moveItemAtPath:renamePath toPath:pathStr error:nil];

    });

    
}

//更新进度
- (void)loadingLog{
    
    NSLog(@"=========loadingLog");
    [DJProgressHUD showProgress:0.2 withStatus:@"" FromView:self.view];

    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * pathStr = [NSString stringWithFormat:@"%@build/log.txt",self.rootPath];
    NSString * dirPath = [NSString stringWithFormat:@"%@build/",self.rootPath];
    
    BOOL isSuccess = [fileManager fileExistsAtPath:pathStr];
    if(isSuccess){
        NSString * log = [NSString stringWithContentsOfFile:pathStr encoding:NSUTF8StringEncoding error:nil];
      //  self.logsLabel.stringValue = log;
        
        if([log containsString:@"52%"]){
        
            [self.progressBar incrementBy:30];
            [DJProgressHUD showProgress:0.52 withStatus:@"" FromView:self.view];

        }
        if([log containsString:@"57%"]){
            
            [self.progressBar incrementBy:30];
            [DJProgressHUD showProgress:0.57 withStatus:@"" FromView:self.view];

            
        }
        if([log containsString:@"95%"]){
            
            [self.progressBar incrementBy:40];
            [DJProgressHUD showProgress:0.95 withStatus:@"" FromView:self.view];


        }
        
        if([log containsString:@"100%"]){
            [DJProgressHUD showProgress:1 withStatus:@"" FromView:self.view];
            
            [self.progressBar setHidden:YES];
            [self.timer invalidate];
            self.timer = nil;
            //删除中间文件
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"fruitstrap.zip"] error:nil];
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"fruitstrap"] error:nil];
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"log.txt"] error:nil];
            
            [DJProgressHUD dismiss];

        }
        
        if([log containsString:@"failed"]){
            
            NSAlert *alert = [NSAlert new];
            [alert addButtonWithTitle:@"确定"];
            [alert addButtonWithTitle:@"取消"];
            [alert setMessageText:@"提示"];
            [alert setInformativeText:@"安装失败！"];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
                if(returnCode == NSAlertFirstButtonReturn){
                    NSLog(@"确定");
                    return ;
                }else if(returnCode == NSAlertSecondButtonReturn){
                    NSLog(@"删除");
                    return ;
                }
            }];
            
            [self.progressBar setHidden:YES];
            [self.timer invalidate];
            self.timer = nil;
            //删除中间文件
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"fruitstrap.zip"] error:nil];
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"fruitstrap"] error:nil];
            [fileManager removeItemAtPath:[dirPath stringByAppendingString:@"log.txt"] error:nil];
            [DJProgressHUD dismiss];

        }
    }
    
}


//界面跳转传值
-(void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"install"]) {
        InstallViewController *installVC = segue.destinationController;
        installVC.pathString =self.rootPath;
        installVC.projectName  = self.projectName;
    }
}

- (void)viewWillAppear{

    self.view.layer.backgroundColor = [[NSColor whiteColor] CGColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bundleIDBox.delegate = self;
    self.tipsLabel.stringValue = @"支持拖拽xcode工程文件夹到窗口";
    self.tipsLabel.textColor = successColor;
   // self.progressBar
   // [self.progressBar setIndeterminate:YES];
    [self.progressBar setUsesThreadedAnimation:YES];
    [self.progressBar startAnimation:nil];
    //子线程解析
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray * array =  self.mobileProvisionArray;
        //主线程设置UI
        dispatch_async(dispatch_get_main_queue(), ^{
            //combox
            NSArray *allObj = [self.fullBundleIdSet allObjects];
            for(int i=0;i<allObj.count;i++){
                [self.bundleIDBox addItemWithObjectValue:allObj[i]];

            }
            //接收外部参数
            ArchieveTool * tool = [ArchieveTool sharedInstance];
            if(tool.pathString.length > 30){
                
                NSData *nsdataFromBase64String = [[NSData alloc]
                                                  initWithBase64EncodedString:tool.pathString options:0];
                
                NSString *base64Decoded = [[NSString alloc]
                                           initWithData:nsdataFromBase64String encoding:NSUTF8StringEncoding];
                
                [self handleDragViewWithPath:base64Decoded];
                tool.pathString = @"";
            }
        });
    });
    
   //环境
   //NSString * s =  @"sudo easy_install -U requests";
   // system([s UTF8String]);
    //添加拖拽文件获取路径控件
    DragView * dragView = [[DragView alloc] initWithFrame:CGRectMake(0, 0, 550, 300)];
    dragView.delegate = self;
    [self.view addSubview:dragView];
    self.achieveStateLabel.stringValue = @"";
    self.startBtn.hidden = YES;
    self.selectMPLabel.hidden = YES;
    self.selectMPBtn.hidden = YES;
    [self.selectMPBtn setTarget:self];
    [self.selectMPBtn setAction:@selector(changeMPFile)];
    [self.selectMPBtn removeAllItems];
    self.versionLabel.hidden  = YES;
    self.versionValueLabel.hidden = YES;
    self.buildLabel.hidden = YES;
    self.buildValueLabel.hidden = YES;
    self.installBtn.hidden = YES;
    self.refreshBundleIdBtn.hidden = YES;
    
    //
    self.pathLabel.hidden = YES;
    self.projectPathLabel.hidden = YES;
    self.projectIdLabel.hidden = YES;
    self.projectNameLabel.hidden = YES;
    self.bundleIDBox.hidden = YES;
    self.displayNameLabel.hidden = YES;
}

#pragma mark - delegate

//检测证书情况
-(void)comboBoxSelectionDidChange:(NSNotification *)notification{

    NSLog(@"-------------comboBoxSelectionDidChange------------");
    NSLog(@"==============--------stringValue---%@",self.comboxItemArray[self.bundleIDBox.indexOfSelectedItem]);
    //有工程时再处理
    if(self.rootPath.length>0){
      
        self.versionLabel.hidden  = YES;
        self.versionValueLabel.hidden = YES;
        self.buildLabel.hidden = YES;
        self.buildValueLabel.hidden = YES;
        self.achieveStateLabel.hidden = NO;
        self.installBtn.hidden = NO;
        
        NSString * bundleid = self.comboxItemArray[self.bundleIDBox.indexOfSelectedItem];
        //更新bundleid
        self.bundleID = bundleid;
        //self.bundleIDLabel.stringValue = bundleid;
        [self updateConverted];
        [self searchMatchProductProfileArray];
        [self updateState];
     //   [self updateProject];
        
    }

   
}

- (void)controlTextDidEndEditing:(NSNotification *)obj{

    NSLog(@"-------------controlTextDidEndEditing------------");

}


//切换证书文件
- (void)changeMPFile{
    
    NSInteger index = self.selectMPBtn.indexOfSelectedItem;
    
    NSDictionary * dic = self.selectProductProfile[index];
    
    NSString * appstore = [dic objectForKey:@"appstore"];
    
    if([appstore isEqualToString:@"0"]){
        self.versionLabel.hidden  = YES;
        self.versionValueLabel.hidden = YES;
        self.buildLabel.hidden = YES;
        self.buildValueLabel.hidden = YES;
        self.isAppStoreType = NO;
        self.installBtn.hidden = NO;
    }
    if([appstore isEqualToString:@"1"]){
        self.isAppStoreType = YES;
        self.versionLabel.hidden  = NO;
        self.versionValueLabel.hidden = NO;
        self.buildLabel.hidden = NO;  
        self.buildValueLabel.hidden = NO;
        self.installBtn.hidden = YES;
        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:[self.rootPath stringByAppendingString:@"info.plist"]];
        self.versionValueLabel.stringValue = [data objectForKey:@"CFBundleShortVersionString"];
        self.buildValueLabel.stringValue = [data objectForKey:@"CFBundleVersion"];
        
        //温馨提示
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"确定"];
        [alert addButtonWithTitle:@"取消"];
        [alert setMessageText:@"提示"];
        [alert setInformativeText:@"打正式包前请先向运营人员确定项目Buind,Version值！并正确填写！"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn){
                return ;
            }else if(returnCode == NSAlertSecondButtonReturn){
                return ;
            }
        }];
        
    }

}

//获取打包进程当前状态
- (void)setupState{
    NSLog(@"======获取打包进程当前状态");
    //Unity-iPhone.xcarchive

    NSFileManager * fileManager  =[NSFileManager defaultManager];
    NSString * archiveName = [NSString stringWithFormat:@"%@.xcarchive",self.projectName];
    BOOL isExe = [fileManager fileExistsAtPath:[self.rootPath stringByAppendingPathComponent:archiveName]];
    if(isExe){
    
        NSLog(@"===============存在---%@",archiveName);
        [DJProgressHUD showStatus:@"正在导出IPA" FromView:self.view];
        self.stateLabel.stringValue = @"状态：正在导出IPA";
        self.stateLabel.textColor = middleColor;
    }
    
}
//手动输入bundleID后，刷新，检测是否有对应描述文件
- (IBAction)refreshWhenBundleIdChanged:(NSButton *)sender {
    [DJProgressHUD showStatus:@"刷新" FromView:self.view];
    
    [self searchMatchProductProfileArray];
    [self updateState];
    
}


#pragma delegate

- (void)handleDragViewWithPath:(NSString *)path{

    self.achieveStateLabel.stringValue = @"";
    self.startBtn.hidden = YES;
    self.selectMPLabel.hidden = YES;
    self.selectMPBtn.hidden = YES;
    [self.selectMPBtn removeAllItems];
    self.stateLabel.stringValue = @"";
    self.versionLabel.hidden  = YES;
    self.versionValueLabel.hidden = YES;
    self.buildLabel.hidden = YES;
    self.buildValueLabel.hidden = YES;
    self.pathLabel.stringValue = [NSString stringWithFormat:@"%@/",path];
    self.rootPath = self.pathLabel.stringValue;
    NSArray * array = [self.pathLabel.stringValue componentsSeparatedByString:@"/"];
    self.pathLabel.stringValue = @"";
    for(int i=0;i<array.count;i++){
    
            if(i>2){
            
                self.pathLabel.stringValue = [NSString stringWithFormat:@"%@/%@",self.pathLabel.stringValue,array[i]];

            }

    }

    self.installBtn.hidden = YES;
    self.refreshBundleIdBtn.hidden = YES;

    //开始检测当前路径下是否有xcode工程
    [self isHaveProject];
    
}

- (IBAction)handleSelectPathBtn:(NSButton *)sender {
    
    self.achieveStateLabel.stringValue = @"";
    self.startBtn.hidden = YES;
    self.selectMPLabel.hidden = YES;
    self.selectMPBtn.hidden = YES;
    [self.selectMPBtn removeAllItems];
    self.stateLabel.stringValue = @"";
    self.versionLabel.hidden  = YES;
    self.versionValueLabel.hidden = YES;
    self.buildLabel.hidden = YES;
    self.buildValueLabel.hidden = YES;
    self.installBtn.hidden = YES;
    self.refreshBundleIdBtn.hidden = YES;

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setResolvesAliases:YES];
    
    NSString *panelTitle = NSLocalizedString(@"Choose a file", @"Title for the open panel");
    [panel setTitle:panelTitle];
    
    NSString *promptString = NSLocalizedString(@"Choose", @"Prompt for the open panel prompt");
    [panel setPrompt:promptString];
    
    [panel beginSheetModalForWindow:[self.view window] completionHandler:^(NSInteger result){
        
        [panel orderOut:self];
        
        if (result != NSOKButton) {
            return;
        }
        NSURL *url = [[panel URLs] objectAtIndex:0];
        
        self.pathLabel.stringValue = url;
        
        self.pathLabel.stringValue = [self.pathLabel.stringValue stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        self.pathLabel.stringValue =   [self.pathLabel.stringValue stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.rootPath = self.pathLabel.stringValue ;
        NSArray * array =  [self.pathLabel.stringValue componentsSeparatedByString:@"/"];
        self.pathLabel.stringValue = @"";

        for(int i=0;i<array.count;i++){
            
            if(i>2){
                
                self.pathLabel.stringValue = [NSString stringWithFormat:@"%@/%@",self.pathLabel.stringValue,array[i]];
                
            }
            
        }
        
        //开始检测当前路径下是否有xcode工程
        [self isHaveProject];
        
    }];

}

//开始检测当前路径下是否有xcode工程
- (void)isHaveProject{

    self.tipsLabel.stringValue = @"";
    self.bundleIDLabel.stringValue  = @"";
    self.displayNameLabel.stringValue = @"";
    self.tipMsgLabel.stringValue = @"";
    self.installBtn.hidden = NO;

    [DJProgressHUD showStatus:@"检测中" FromView:self.view];
    //检查非空
    if(self.rootPath.length == 0){
        
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"确定"];
        [alert addButtonWithTitle:@"取消"];
        [alert setMessageText:@"提示"];
        [alert setInformativeText:@"项目路径不能为空!"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn){
                NSLog(@"确定");
                return ;
            }else if(returnCode == NSAlertSecondButtonReturn){
                NSLog(@"删除");
                return ;
            }
        }];
        
    }else{
        
        NSFileManager * fileManager = [NSFileManager defaultManager];
        
        // 判断项目类型
        BOOL isXcodeproj;
        int flag = 0;
        NSString * projectName;
        NSString * projectFullName;
        NSArray *   subPaths = [fileManager contentsOfDirectoryAtPath:self.rootPath error:nil];
        
        for(int i=0;i<subPaths.count;i++){
            
            NSString * filePath = subPaths[i];
            NSString *suffix = [filePath pathExtension];
            
            if([suffix isEqualToString:@"xcodeproj"]){
                flag = 1;
                projectName = [filePath stringByDeletingPathExtension];
                projectFullName = filePath;
            }else if([suffix isEqualToString:@"xcworkspace"]){

                flag = 2;
                projectName = [filePath stringByDeletingPathExtension];
                projectFullName = filePath;
                return;
            }
        }
        
        if(flag == 1 ){
            
            isXcodeproj = YES;
        }else if (flag == 2){
            
            isXcodeproj = NO;
        }else if (flag == 0){
            
            NSAlert *alert = [NSAlert new];
            [alert addButtonWithTitle:@"确定"];
            [alert addButtonWithTitle:@"取消"];
            [alert setMessageText:@"提示"];
            [alert setInformativeText:@"当前路径下未检测到xcode项目!"];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
                if(returnCode == NSAlertFirstButtonReturn){
                    NSLog(@"确定");
                    self.pathLabel.stringValue = @"";
                    self.rootPath = @"";
                    [DJProgressHUD  dismiss];
                    return ;
                }else if(returnCode == NSAlertSecondButtonReturn){
                    NSLog(@"删除");
                    self.pathLabel.stringValue = @"";
                    self.rootPath = @"";
                    [DJProgressHUD  dismiss];
                    return ;
                }
            }];
            
        }
        
        //有工程现实控件
        self.pathLabel.hidden = NO;
        self.projectPathLabel.hidden = NO;
        self.projectIdLabel.hidden = NO;
        self.projectNameLabel.hidden = NO;
        self.bundleIDBox.hidden = NO;
        self.displayNameLabel.hidden = NO;
        
        self.isXcodeproj = isXcodeproj;
        self.projectName = projectName;
        self.projectFullName = projectFullName;
        //解析info.plist 获取displayName
        [self parseInfoPlist];
        //解析当前xcode工程bundleid
        [self parsePbxproj];
        
    }
    
}

/**
 当前xcode工程project.pbxproj导出为xml解析bundleid
 */
- (void)parsePbxproj{
   
    NSFileManager * fileManager = [NSFileManager defaultManager];
    //0导出为xml
    //plutil -convert xml1 -s -r -o converted.xml  Unity-iPhone.xcodeproj/project.pbxproj
    NSString * parseName = [self.projectName stringByAppendingString:@".xcodeproj/project.pbxproj"];
    NSString * parseString = [NSString stringWithFormat:@"cd %@ ; plutil -convert xml1 -s -r -o converted.xml %@",self.rootPath,parseName];
    system([parseString UTF8String]);

    //1解析xml
    BOOL isExist  =  [fileManager fileExistsAtPath:[self.rootPath stringByAppendingString:@"converted.xml"]];
    NSLog(@"--------------%@",[self.rootPath stringByAppendingString:@"converted.xml"]);
    if(isExist){
        
        NSLog(@"---------------存在");
        NSData * data = [NSData dataWithContentsOfFile:[self.rootPath stringByAppendingString:@"converted.xml"]];
        self.convertedString = [NSString stringWithContentsOfFile:[self.rootPath stringByAppendingString:@"converted.xml"] encoding:NSUTF8StringEncoding error:nil];
        [self searchPbxprojSetting];
        self.parser = [[NSXMLParser alloc] initWithData:data];
        self.parser.delegate = self;
        [self.parser parse];
        
    }else{
        
        NSLog(@"--------------不存在");
        [DJProgressHUD dismiss];
        self.stateLabel.stringValue = @"状态：解析失败";
        self.stateLabel.textColor = failColor;
    }

}


// 修改project.pbxproj文件，删除xcode自动管理签名
- (void)modifyPbxprojAndIsChangeID:(BOOL)isChangeID{

    NSString * parseName = [self.projectName stringByAppendingString:@".xcodeproj/project.pbxproj"];
    
    NSString * pbxprojString = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",self.rootPath,parseName] encoding:NSUTF8StringEncoding error:nil];
    NSString * path = [NSString stringWithFormat:@"%@%@",self.rootPath,self.projectFullName];
    
    BOOL flag = NO;
    //是否需要修改bundleID

        if(self.isNameType){
            //1 info.plist 修改
            NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:[self.rootPath stringByAppendingString:@"info.plist"]];
            [data setObject:@"$(PRODUCT_BUNDLE_IDENTIFIER) " forKey:@"CFBundleIdentifier"];
            [data writeToFile:[self.rootPath stringByAppendingString:@"info.plist"] atomically:YES];
            
            //2 修改配置文件，增加ID配置
            flag = YES;
            self.isNameType = NO;
     
        }else{
            NSString * bundleString = [self getValueStringWithKey:@"PRODUCT_BUNDLE_IDENTIFIER" FromPbxprojString:pbxprojString];
            NSString * commandBundleid = [NSString stringWithFormat:@"cd %@ ; sed -i '' 's/%@/%@/g' project.pbxproj",path,bundleString,[NSString stringWithFormat:@"PRODUCT_BUNDLE_IDENTIFIER = %@",self.bundleID]];
            NSLog(@"---------------------s=%@",commandBundleid);
            system([commandBundleid UTF8String]);
        }


    //是自动管理签名的，取消自动管理
    if([pbxprojString containsString:@"Automatic"]){
        
        //1 删除 ProvisioningStyle = Automatic;
        NSString * key = @"ProvisioningStyle = Automatic;";
        NSString * delAuto = [NSString stringWithFormat:@"cd %@ ;sed -i '' 's/%@/ /g' project.pbxproj",path,key];
        system([delAuto UTF8String]);
    }

    //2 描述文件配置
    NSDictionary * newDic;
    NSString * appstore;
    if(self.selectProductProfile.count>0){
        newDic = self.selectProductProfile[0];
        appstore = [newDic objectForKey:@"appstore"];
    }
    
    NSString * nameString = [self getValueStringWithKey:@"PROVISIONING_PROFILE" FromPbxprojString:pbxprojString];
    NSString * uuidString = [self getValueStringWithKey:@"PROVISIONING_PROFILE_SPECIFIER" FromPbxprojString:pbxprojString];
    NSString * commandName ;
    if(flag){
        //需要增加PRODUCT_BUNDLE_IDENTIFIER
    commandName = [NSString stringWithFormat:@"cd %@ ;sed -i '' 's/%@/%@/g' project.pbxproj",path,nameString,[NSString stringWithFormat:@"PROVISIONING_PROFILE = %@; PRODUCT_BUNDLE_IDENTIFIER = %@",[newDic objectForKey:@"name"],self.bundleID]];
    }else{
         commandName = [NSString stringWithFormat:@"cd %@ ;sed -i '' 's/%@/%@/g' project.pbxproj",path,nameString,[NSString stringWithFormat:@"PROVISIONING_PROFILE = %@",[newDic objectForKey:@"name"]]];
    }
   
    NSString * commandUuid = [NSString stringWithFormat:@"cd %@ ;sed -i '' 's/%@/%@/g' project.pbxproj",path,uuidString,[NSString stringWithFormat:@"PROVISIONING_PROFILE_SPECIFIER = %@",[newDic objectForKey:@"uuid"]]];
    //3 team修改
    NSString * teamString = [self getValueStringWithKey:@"DEVELOPMENT_TEAM" FromPbxprojString:pbxprojString];
    NSString * commandTeam = [NSString stringWithFormat:@"cd %@ ;sed -i '' 's/%@/%@/g' project.pbxproj",path,teamString,[NSString stringWithFormat:@"DEVELOPMENT_TEAM = \"%@\"",[newDic objectForKey:@"team"]]];
    //4
    NSString * commandType;
    if([appstore isEqualToString:@"1"]){
        commandType = [NSString stringWithFormat:@"cd %@ ;sed -i '' 's/iPhone Developer/iPhone Distribution/g' project.pbxproj",path];
        self.oldType = @"iPhone Distribution";
        
    }else{
        commandType = [NSString stringWithFormat:@"cd %@ ;sed -i '' 's/iPhone Distribution/iPhone Developer/g' project.pbxproj",path];
        self.oldType = @"iPhone Developer";
        
    }
    NSLog(@"---------------------s=%@",commandName);
    NSLog(@"---------------------s=%@",commandUuid);
    NSLog(@"---------------------s=%@",commandTeam);
    
    system([commandName UTF8String]);
    system([commandUuid UTF8String]);
    system([commandTeam UTF8String]);
    system([commandType UTF8String]);
    
}


//project.pbxproj
- (NSString *)getValueStringWithKey:(NSString *)key FromPbxprojString:(NSString *)string{

    //获取key值所在位置
    NSRange range = [string rangeOfString:key];
    //截取字符串
    NSString * valueString = [string substringWithRange:NSMakeRange(range.location, (range.length + 80))];
    //根据;分割字符串
    NSArray * valueArray = [valueString componentsSeparatedByString:@";"];

    if(valueArray.count >0){
    
        return valueArray[0];
    }
    return @"";
}

//解析info.plist 获取displayName
- (void)parseInfoPlist{

    // 解析info.plist 获取displayName
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:[self.rootPath stringByAppendingString:@"info.plist"]];
    
    self.displayName = [data objectForKey:@"CFBundleDisplayName"];
    
    self.bundleString = [data objectForKey:@"CFBundleIdentifier"];
    
    // PRODUCT_NAME
    // PRODUCT_BUNDLE_IDENTIFIER
    self.isNameType = [self.bundleString containsString:@"PRODUCT_NAME"];
}

- (void)updateConverted{

    NSString * parseName = [self.projectName stringByAppendingString:@".xcodeproj/project.pbxproj"];
    NSString * parseString = [NSString stringWithFormat:@"cd %@ ; plutil -convert xml1 -s -r -o converted.xml %@",self.rootPath,parseName];
    NSLog(@"-------parseString--------%@",parseString);
    system([parseString UTF8String]);
    NSData * data = [NSData dataWithContentsOfFile:[self.rootPath stringByAppendingString:@"converted.xml"]];
    self.convertedString = [NSString stringWithContentsOfFile:[self.rootPath stringByAppendingString:@"converted.xml"] encoding:NSUTF8StringEncoding error:nil];
    [self searchPbxprojSetting];
}

#pragma mark  - delegate

//几个代理方法的实现
//开始解析
- (void)parserDidStartDocument:(NSXMLParser *)parser{
    NSLog(@"parserDidStartDocument...");
}
//准备节点
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict{
    
    self.currentElement = elementName;
    
}
//获取节点内容
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
   // PRODUCT_NAME
   // PRODUCT_BUNDLE_IDENTIFIER
    NSString * key ;
    if(self.isNameType){
    
        key = @"PRODUCT_NAME";
    }else{
    
        key = @"PRODUCT_BUNDLE_IDENTIFIER";
    }
    
    if ([string isEqualToString:key]) {
        
        self.index = 1;
    }else{
    
        if(self.index == 2){
            
            if(self.isNameType){
                self.bundleID =  [self.bundleString stringByReplacingOccurrencesOfString:@"${PRODUCT_NAME}" withString:string];

            }else{
                self.bundleID = string;

            }
            self.index = 0;
        }
        if(self.index == 1){
        
            self.index ++;
        }
        
    }
    
}

//解析完一个节点
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName{
    
    self.currentElement = nil;
}

//解析结束
- (void)parserDidEndDocument:(NSXMLParser *)parser{
    NSLog(@"parserDidEndDocument...");
    
    //解析结束，刷新工程相关信息
    [self refreshProjectInfo];
    //根据当前bundleid查找对应的描述文件
    [self searchMatchProductProfileArray];
    //更新状态（是否安装有对应描述文件）
    //[self updateState];
    NSLog(@"===");
}

//根据当前bundleid查找对应的描述文件
- (void)searchMatchProductProfileArray{
    [self.selectProductProfile removeAllObjects];
    [self.selectMPBtn removeAllItems];
    if(self.bundleID.length>0){//self.bundleIDLabel.stringValue
    
        for(int i=0;i<self.allBundleIdArray.count;i++){
        
            NSDictionary * dic = self.allBundleIdArray[i];
            NSString * bundleid = [dic objectForKey:@"bundleid"];
            
           // NSArray *array = [bundleid componentsSeparatedByString:@"."];
            
          //  NSString * headString = array[0];
           
           // NSString * ID = [bundleid substringFromIndex:headString.length+1];
          //  NSLog(@"===================ID=%@",ID);
            if([bundleid isEqualToString:self.bundleID]){//self.bundleIDLabel.stringValue
                [self.selectProductProfile addObject:dic];
            }
   
        }
    }
}

//解析结束，刷新工程相关信息
- (void)refreshProjectInfo{

    //0删除中间生成的xml文件
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL flag =  [fileManager  isDeletableFileAtPath:[self.rootPath stringByAppendingPathComponent:@"converted.xml"]];
    
    if(flag){
        
        // [fileManager removeItemAtPath:[self.pathLabel.stringValue stringByAppendingPathComponent:@"converted.xml"] error:nil];
    }
    
    self.displayNameLabel.stringValue = self.displayName;

    //1 根据类型，设置正确bundleid
  //  if(self.isNameType){
        //  self.bundleIDLabel.stringValue = [self.bundleString stringByReplacingOccurrencesOfString:@"${PRODUCT_NAME}" withString:self.bundleID];//self.bundleID;//${PRODUCT_NAME}
  //      self.bundleID = [self.bundleString stringByReplacingOccurrencesOfString:@"${PRODUCT_NAME}" withString:self.bundleID];
 //   }else{
        //  self.bundleIDLabel.stringValue = self.bundleID;
        
  //  }
    
    //2 combox选择当前bundlid
    NSArray *allObj = [self.fullBundleIdSet allObjects];
    self.comboxItemArray = [NSMutableArray arrayWithArray:allObj];
    BOOL isExist = NO;
    for (int i=0; i<allObj.count; i++) {
        NSString * bundleid = allObj[i];
        if([self.bundleID isEqualToString:bundleid]){
            [self.bundleIDBox selectItemAtIndex:i];
            isExist = YES;
            break;
        }
    }
    //如果不存在就添加
    if(!isExist){
        [self.bundleIDBox insertItemWithObjectValue:self.bundleID atIndex:0];
        [self.comboxItemArray insertObject:self.bundleID atIndex:0];
        [self.bundleIDBox selectItemAtIndex:0];
    }
    
}

//更新状态（是否安装有对应描述文件）
- (void)updateState{
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // [self loadMobileProvision];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [DJProgressHUD dismiss];
            
            
            if(self.selectProductProfile.count > 0){
                
                self.tipMsgLabel.stringValue = @"本机是否已安装对应包名的证书与描述文件：是";
                self.tipMsgLabel.textColor = successColor;
                self.startBtn.hidden = NO;
                self.selectMPLabel.hidden = NO;
                self.selectMPBtn.hidden = NO;
                self.stateLabel.stringValue = @"状态：有效的XCode工程";
                self.stateLabel.textColor = successColor;
                [self.bundleIDLabel setEditable:NO];
                [self.bundleIDLabel setSelectable:NO];
                self.refreshBundleIdBtn.hidden = YES;
                
                
                for(int i = 0;i<self.selectProductProfile.count;i++){
                    
                    NSDictionary * dic = self.selectProductProfile[i];
                    
                    NSString * name = [dic objectForKey:@"name"];
                    NSString * appstore = [dic objectForKey:@"appstore"];
                    
                    [self.selectMPBtn addItemWithTitle:name];
                    
                    if(i == 0){
                        //第一个是dis证书
                        if([appstore isEqualToString:@"1"]){
                            
                            self.installBtn.hidden = YES;
                            self.isAppStoreType = YES;
                            self.versionLabel.hidden  = NO;
                            self.versionValueLabel.hidden = NO;
                            self.buildLabel.hidden = NO;
                            self.buildValueLabel.hidden = NO;
                            NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:[self.rootPath stringByAppendingString:@"info.plist"]];
                            self.versionValueLabel.stringValue = [data objectForKey:@"CFBundleShortVersionString"];
                            self.buildValueLabel.stringValue = [data objectForKey:@"CFBundleVersion"];
                            
                        }
                    }
                }
                
                //有对应的证书时，删除自动签名管理
                [self modifyPbxprojAndIsChangeID:NO];
                
                
            }else{
                self.tipMsgLabel.stringValue = @"本机是否已安装对应包名的证书与描述文件：否";
                self.tipMsgLabel.textColor = failColor;
                self.stateLabel.stringValue = @"状态：无效的XCode工程";
                self.stateLabel.textColor = failColor;
                //改为手动输入bundleID
               // self.bundleIDLabel.hidden = YES;
               // [self.bundleIDLabel setEditable:YES];
               // [self.bundleIDLabel setSelectable:YES];
               // self.refreshBundleIdBtn.hidden = NO;
            }
            
        });
        
    });
    
}

- (void)updateProject{
   
    // 如果info.plist的bundleID与self.bundleIDLabel.stringValue不同，则修改project.pbxproj文件
  //  if(self.isNameType){
  //      bundleid = [self.bundleString stringByReplacingOccurrencesOfString:@"${PRODUCT_NAME}" withString:self.bundleID];//self.bundleID;//${PRODUCT_NAME}
        
  //  }else{
  //       bundleid = self.bundleID;
        
  //  }
    //修改project.pbxproj文件
    [self modifyPbxprojAndIsChangeID:YES];

}

//查找project.pbxproj文件各配置信息
- (void) searchPbxprojSetting{
    
    self.pbxprojSettingDic = [NSMutableDictionary dictionary];
    if(self.convertedString.length>0){
    
        for (int i=0; i<self.allBundleIdArray.count; i++) {
            NSDictionary * dic = self.allBundleIdArray[i];
            NSString * bundleid = [dic objectForKey:@"bundleid"];
            NSString * name = [dic objectForKey:@"name"];
            NSString * team = [dic objectForKey:@"team"];
            NSString * uuid = [dic objectForKey:@"uuid"];
            
            if(bundleid.length>2){//过滤*
            
                if([self.convertedString containsString:bundleid]){
                
                    [self.pbxprojSettingDic setObject:bundleid forKey:@"bundleid"];
                
                }
                if([self.convertedString containsString:name]){
                   [self.pbxprojSettingDic setObject:name forKey:@"name"];
                }
                
                if([self.convertedString containsString:team]){
                
                    [self.pbxprojSettingDic setObject:team forKey:@"team"];

                }
                if([self.convertedString containsString:uuid]){
                    
                    [self.pbxprojSettingDic setObject:uuid forKey:@"uuid"];
                    
                }
            }
        }
    }
    
}
//============创建脚本
- (void) setupPython{

    NSFileManager * fileManager = [NSFileManager defaultManager];

    NSString * pythonName;
    NSString * plistName;
    
    NSInteger index = self.selectMPBtn.indexOfSelectedItem;
    
    NSDictionary * dic = self.selectProductProfile[index];
    
    NSString * appstore = [dic objectForKey:@"appstore"];
    
    if([appstore isEqualToString:@"0"]){
        
        //Debug
        self.isAppStoreType = NO;
        pythonName = @"autobuild_debug.py";
        plistName = @"exportOptions_debug.plist";
    }else if([appstore isEqualToString:@"1"]){
        //Release
        self.isAppStoreType = YES;
        pythonName = @"autobuild_release.py";
        plistName = @"exportOptions_release.plist";
    }
    
    // 0 是否已有脚本
    
    BOOL isExecutable0 = [fileManager fileExistsAtPath:[self.rootPath stringByAppendingPathComponent:pythonName]];
    NSLog(@"------%@",[self.rootPath stringByAppendingPathComponent:pythonName]);
    BOOL isExecutable1 = [fileManager fileExistsAtPath:[self.rootPath stringByAppendingPathComponent:plistName]];
    
    if(!isExecutable0){
        
        //不存在，创建
        //1 写入python文件
        NSString * path = [[NSBundle mainBundle] pathForResource:pythonName ofType:nil];
        NSData * pythonData = [NSData dataWithContentsOfFile:path];
        
        [pythonData writeToFile:[self.rootPath stringByAppendingPathComponent:pythonName] atomically:YES];
    }
    
    if(!isExecutable1){
        
        //不存在，创建
        NSString * path = [[NSBundle mainBundle] pathForResource:plistName ofType:nil];
        NSData * plistData = [NSData dataWithContentsOfFile:path];
        
        [plistData writeToFile:[self.rootPath stringByAppendingPathComponent:plistName] atomically:YES];
    }
    
    self.pythonName = pythonName;
    self.plistName = plistName;
    
}


- (IBAction)handleIsDebugBtn:(NSButton *)sender {
    
   //v NSLog(@"=========sender.state=%ld",(long)sender.state);
}

- (NSString * )getIconPathWithName:(NSString *)iconName{

    return [NSString stringWithFormat:@"%@%@/Images.xcassets/AppIcon.appiconset/%@",self.rootPath,self.projectName,iconName];
}

//增加 167尺寸icon
- (void) addIconImage{

    //检测是否有180 icon图片
    NSString * iconPath = [self getIconPathWithName:@"Icon-180.png"];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isHas180Icon =  [fileManager fileExistsAtPath:iconPath];
    
    if(isHas180Icon){
    
        //检测是否有180 icon图片
        NSString * iconPath = [self getIconPathWithName:@"Icon-167.png"];
        BOOL isHas167Icon =   [fileManager fileExistsAtPath:iconPath];
        if(isHas167Icon){
            return;
        }else{
           //生成167icon
            NSString * iconpath = [self getIconPathWithName:@"Icon-180.png"];
            NSImage *imageView = [[NSImage alloc] initWithContentsOfFile:iconpath];
            NSImage * newimage =   [NSImage resizeImage:imageView size:NSMakeSize(83.5, 83.5)];
            NSData *imageData = [newimage TIFFRepresentation];
            [imageData writeToFile:[self getIconPathWithName:@"Icon-167.png"] atomically:YES];
          //修改配置json文件
            NSString * contentS = [NSString stringWithContentsOfFile:[self getIconPathWithName:@"Contents.json"] encoding:NSUTF8StringEncoding error:nil];
            
         NSString * newcontentS =  [contentS stringByReplacingOccurrencesOfString:@"83.5\"," withString:@"83.5\",\n \"filename\" : \"Icon-167.png\","];
        
         [newcontentS writeToFile:[self getIconPathWithName:@"Contents.json"] atomically:YES encoding: NSUTF8StringEncoding error:nil];
        }
    }
    
}

- (IBAction)handleStartBtn:(NSButton *)sender {
    
    //打包时生成167X167尺寸icon
    [self addIconImage];
    
   // self.tipMsgLabel.stringValue = @"";
    //正式包需要重写info.plist文件的Version与Build值
    if(self.isAppStoreType){
        
        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:[self.rootPath stringByAppendingString:@"info.plist"]];
        NSString * version = [data objectForKey:@"CFBundleShortVersionString"];
        NSString * build = [data objectForKey:@"CFBundleVersion"];
        
        //需要重写
        if(![self.versionValueLabel.stringValue isEqualToString:version] || ![self.buildValueLabel.stringValue isEqualToString:build]){
            NSLog(@"------------------需要重写");
            [data setObject:self.versionValueLabel.stringValue forKey:@"CFBundleShortVersionString"];
            [data setObject:self.buildValueLabel.stringValue forKey:@"CFBundleVersion"];
            
            //删除
            NSFileManager * fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:[self.rootPath stringByAppendingString:@"info.plist"] error:nil];
            
            [data writeToFile:[self.rootPath stringByAppendingString:@"info.plist"] atomically:YES];
        }
        
    }
    
    //计时器
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setupState) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    
    [DJProgressHUD showStatus:@"正在生成APP" FromView:self.view];
    
    self.stateLabel.stringValue = @"状态：正在生成APP";
    self.stateLabel.textColor = middleColor;
    
    //设置脚本
    [self setupPython];
    //打包工程
    [self achieveProject];

     }

//检测是否打包成功
- (void)achieveProject{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //根据工程类型打包
        if(self.isXcodeproj){
            // [DJProgressHUD showStatus:@"打包中。。。" FromView:self.view];
            // python autobuild.py -p ../AOP.xcodeproj -s AOP
            NSString * command = [NSString stringWithFormat:@"cd %@;python %@ -p %@ -s %@ >logs.txt",self.rootPath,self.pythonName,self.projectFullName,self.projectName];
            system([command UTF8String]);
        }else{
            
            //[DJProgressHUD showStatus:@"打包中。。。" FromView:self.view];
            // python autobuild.py -w ../yourworkspace.xcworkspace -s yourscheme
            NSString * command = [NSString stringWithFormat:@"cd %@;python %@ -w %@ -s %@",self.rootPath,self.pythonName,self.projectFullName,self.projectName];
            system([command UTF8String]);
            
        }
        //检测是否打包成功
        NSFileManager * fileManager = [NSFileManager defaultManager];
        //NSString *suffix = [filePath pathExtension];
        NSString * ipa = [self.projectName stringByAppendingString:@".ipa"];
        NSString * path = [NSString stringWithFormat:@"%@build/%@",self.rootPath,ipa];
        BOOL isSuccess = [fileManager fileExistsAtPath:path];
        if(isSuccess){
            //如果是正式包需要删除字符集文件夹
            if(self.isAppStoreType){
                //解压ipa包
                
                NSString * dir =[NSString stringWithFormat:@"%@build/%@",self.rootPath,self.projectName];
                
                [SSZipArchive unzipFileAtPath:path toDestination:dir];
                //删除包内Symbols文件夹
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/Symbols",dir] error:nil];
                //重新生成精简后的ipa包
                [SSZipArchive createZipFileAtPath:[dir stringByAppendingString:@".ipa"] withContentsOfDirectory:[NSString stringWithFormat:@"%@/",dir]];
                //删除中间文件夹
                [fileManager removeItemAtPath:dir error:nil];
            }
            
        }
        
        //回到主线程刷新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //删除脚本
            NSFileManager * fileManager = [NSFileManager defaultManager];
            
            BOOL flag1 =  [fileManager  isDeletableFileAtPath:[self.rootPath stringByAppendingPathComponent:self.pythonName]];
            
            if(flag1){
                
                [fileManager removeItemAtPath:[self.rootPath stringByAppendingPathComponent:self.pythonName] error:nil];
            }
            
            BOOL flag2 =  [fileManager  isDeletableFileAtPath:[self.rootPath stringByAppendingPathComponent:self.plistName]];
            
            if(flag2){
                
                [fileManager removeItemAtPath:[self.rootPath stringByAppendingPathComponent:self.plistName] error:nil];
            }
            //======
            //检测是否打包成功
            
            //解析logs.txt
            NSString * logsPath = [NSString stringWithFormat:@"%@logs.txt",self.rootPath];
            
            BOOL isSuccess = [fileManager fileExistsAtPath:logsPath];
            if(isSuccess){
                NSString * archieveLog = [NSString stringWithContentsOfFile:logsPath encoding:NSUTF8StringEncoding error:nil];
                [fileManager removeItemAtPath:logsPath error:nil];
                
                //打包成功
                if([archieveLog containsString:@"** ARCHIVE SUCCEEDED **"]){
                
                    //正式包隐藏安装按钮
                    if(self.isAppStoreType){
                        
                        self.installBtn.hidden = YES;
                        
                    }else{
                        
                        self.installBtn.hidden = NO;
                    }
                    
                    [DJProgressHUD dismiss];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
                        self.achieveStateLabel.stringValue = @"打包成功,ipa文件在工程路径/build/下";
                        self.achieveStateLabel.textColor = labelColor;
                        self.stateLabel.stringValue = @"状态：导出IPA已完成";
                        self.stateLabel.textColor = successColor;
                        
                        //修改ipa名称
                        NSString * ipa = [self.projectName stringByAppendingString:@".ipa"];
                        NSString * renameIpa = [self.displayNameLabel.stringValue stringByAppendingString:@".ipa"];
                        NSString * path = [NSString stringWithFormat:@"%@build/%@",self.rootPath,ipa];
                        NSString * renamePath = [NSString stringWithFormat:@"%@build/%@",self.rootPath,renameIpa];
                        [fileManager moveItemAtPath:path toPath:renamePath error:nil];
                        
                        //打包成功后打开当前文件夹
                        NSOpenPanel *panel = [NSOpenPanel openPanel];
                        [panel setAllowsMultipleSelection:NO];
                        [panel setCanChooseDirectories:NO];
                        [panel setCanChooseFiles:YES];
                        [panel setResolvesAliases:YES];
                        [panel setDirectory:[NSString stringWithFormat:@"%@/build",self.rootPath]];
                        [panel beginWithCompletionHandler:^(NSInteger result) {
                            
                        }];
                    });

                }
                
                
                //[archieveLog containsString:@"No signing certificate"] ||[archieveLog containsString:@"Code signing is required"] || [archieveLog containsString:@"ARCHIVE FAILED"]
                if(![archieveLog containsString:@"** ARCHIVE SUCCEEDED **"]){
                    
                    [DJProgressHUD dismiss];
                    self.stateLabel.stringValue = @"状态：打包失败";
                    self.stateLabel.textColor = [NSColor redColor];
                    //======关闭定时器
                    [self.timer invalidate];
                    self.timer = nil;
                    
                    NSAlert *alert = [NSAlert new];
                    [alert addButtonWithTitle:@"确定"];
                    [alert addButtonWithTitle:@"取消"];
                    [alert setMessageText:@"提示"];
                    [alert setInformativeText:@"打包失败，请确认工程是否有错或者检查证书!"];
                    [alert setAlertStyle:NSWarningAlertStyle];
                    [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
                        if(returnCode == NSAlertFirstButtonReturn){
                            NSLog(@"确定");
                            return ;
                        }else if(returnCode == NSAlertSecondButtonReturn){
                            NSLog(@"删除");
                            return ;
                        }
                    }];
                    
                }
            }

            //======关闭定时器
            [self.timer invalidate];
            self.timer = nil;
            
        });
        
    });

}


//业务逻辑改变不在使用
-(void)loadMobileProvision
{
    //遍历Xcode中所有的MobileProvision描述文件
    
    NSArray *arguments2;
    NSPipe *pipe2 = [NSPipe pipe];
    NSMutableArray * selectProductProfile = [[NSMutableArray alloc] init];
    
    if (self.mobileProvisionArray)
    {
        //解析所有的MobileProvision描述文件，转成可以阅读的xml格式
        for (NSString *name in self.mobileProvisionArray)
        {
            NSTask *task2 = [[NSTask alloc] init];
            [task2 setLaunchPath:@"/usr/bin/security"];
            [task2 setCurrentDirectoryPath:@"~/Library/MobileDevice/Provisioning Profiles/"];
            arguments2 = [NSArray arrayWithObjects: @"cms", @"-D", @"-i", name, nil];
            [task2 setArguments: arguments2];
            pipe2 = [NSPipe pipe];
            [task2 setStandardOutput: pipe2];
            NSFileHandle *file2 = [pipe2 fileHandleForReading];
            [task2 launch];
            NSData *data2 = [file2 readDataToEndOfFile];
            NSString *resultStr = [[NSString alloc] initWithData:data2 encoding: NSUTF8StringEncoding];
            NSLog(@" >>> %@", resultStr);
            
            //在每个MobileProvision描述文件中，找出与bundle id对应的描述文件
            NSData* plistData = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
            NSPropertyListFormat format;
            NSDictionary* plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:nil];
            if (plist)
            {
                if ([plist objectForKey:@"Entitlements"])
                {
                    NSDictionary* plistChildDic = (NSDictionary *)[plist objectForKey:@"Entitlements"];
                    if (plistChildDic)
                       {
                        NSString* value = [plistChildDic objectForKey:@"application-identifier"];
                           NSString* bundleId ;//= self.bundleID;//@"com.lili.look";
                        //   plutil -convert xml1 -s -r -o converted.xml  Unity-iPhone.xcodeproj/project.pbxproj
                           if(self.isNameType){
                               bundleId = [self.bundleString stringByReplacingOccurrencesOfString:@"${PRODUCT_NAME}" withString:self.bundleID];//self.bundleID;//${PRODUCT_NAME}
                               
                           }else{
                               bundleId = self.bundleID;
                               
                           }
                        if (value && bundleId)
                        {
                            if ([value containsString:bundleId])
                            {
                                NSString* provisionName = [plist valueForKey:@"Name"];
                                NSString* uuid = [plist valueForKey:@"UUID"];
                                NSLog(@"provisionName >>> %@", provisionName);
                                
                                NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
                                [tempDic setObject:provisionName forKey:@"name"];
                                [tempDic setObject:uuid forKey:@"uuid"];
                                if ([plist valueForKey:@"ProvisionedDevices"])
                                {
                                    [tempDic setObject:@"0" forKey:@"appstore"];
                                }
                                else
                                {
                                    [tempDic setObject:@"1" forKey:@"appstore"];
                                }
                                [selectProductProfile addObject:tempDic];
                            }
                        }
                    }
                }
            }
            
        }
        self.selectProductProfile = selectProductProfile;
    }
    
}

@end
