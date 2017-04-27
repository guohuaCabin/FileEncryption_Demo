//
//  ViewController.m
//  FileEncryption_Demo
//
//  Created by 秦国华 on 2017/4/25.
//  Copyright © 2017年 秦国华. All rights reserved.
//

#import "ViewController.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "ReaderViewController.h"

#define aPassword  @"qgh"
const static CGFloat space = 10.f;

@interface ViewController ()<ReaderViewControllerDelegate>

@property(strong,nonatomic)UIImageView *imageView;
@property(strong,nonatomic)UIButton *button;
@property(copy,nonatomic)NSString *filepath;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [self createUI];

    [self imageEncryptionAndDecryption];
//    [self PDFEncryption];
}

-(void)createUI
{
    CGFloat iPhoneHeight = self.view.bounds.size.height;
    CGFloat iPhoneWidth  = self.view.bounds.size.width;
    
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(50.f, 100.f, iPhoneWidth-100.f, 50.f)];
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"查看PDF" forState:UIControlStateNormal];
    button.layer.cornerRadius = 5.f;
    button.clipsToBounds = YES;
    button.layer.borderWidth = 1.f;
    button.layer.borderColor = [UIColor blackColor].CGColor;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [self.view addSubview:button];
    
    
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(space, iPhoneHeight/2, iPhoneWidth-20, 300)];
    self.imageView.layer.borderColor = [UIColor blackColor].CGColor;
    self.imageView.layer.borderWidth = 1.f;
    self.imageView.clipsToBounds  = YES;
    self.imageView.layer.cornerRadius = 5.f;

    [self.view addSubview:self.imageView];
    
}

#pragma  mark --Image加解密
-(void)imageEncryptionAndDecryption
{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"default.jpg" ofType:nil]];
    NSError *error;
    //加密
    NSData *encryptedData = [RNEncryptor encryptData:data withSettings:kRNCryptorAES256Settings password:aPassword error:&error ];
    if (!error) {
        NSLog(@"^_^ 加密成功 ……——(^_^)\n");
//        NSLog(@"encryptedData==%@",encryptedData);
    }
    //解密
    NSData *decryptedData = [RNDecryptor decryptData:encryptedData
                                        withPassword:aPassword
                                               error:&error];
    if (!error) {
        NSLog(@"^_^ 解密成功 ……——(^_^)\n");
//        NSLog(@"decryptedData==%@",decryptedData);
        self.imageView.image = [UIImage imageWithData:decryptedData];
    }
    
}

#pragma mark --PDF加密
-(void)PDFEncryption
{
    __block NSData *encryptedData;
    __block NSError *error;
    
    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"11.pdf" ofType:nil];
    NSString *fileEncryPath = [NSHomeDirectory()stringByAppendingPathComponent:@"/Documents/TKAMC.qgh"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断是否已存在加密文件，若存在直接执行解密过程。
    if ([fileManager fileExistsAtPath:fileEncryPath]) {
        
        [self PDFDecryptedData:[NSData dataWithContentsOfFile:fileEncryPath]];
        return;
    }
    //异步去加密，防止占用太多内存
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        //加密
        encryptedData = [RNEncryptor encryptData:data withSettings:kRNCryptorAES256Settings password:aPassword error:&error ];
        if (!error) {
            NSLog(@"^_^ PDF加密成功 ……——(^_^)\n");
//            NSLog(@"encryptedData==%@",encryptedData);
        }
        
        //在主线程上写入文件
        dispatch_sync(dispatch_get_main_queue(), ^{
            BOOL yes = [encryptedData writeToFile:fileEncryPath atomically:NO];
            if (yes) {
                NSLog(@"加密文件写入成功");

            }else{
                NSLog(@"加密文件写入失败");
            }
            
            NSLog(@"写入PDF路径：%@",fileEncryPath);
            
            [self PDFDecryptedData:encryptedData];
        });
    });
  
}

#pragma mark ---PDF解密
-(void)PDFDecryptedData:(NSData *)encryptedData{

    NSString *fileDecryPath = [NSHomeDirectory()stringByAppendingPathComponent:@"/Documents/TKAMC"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //    解密
        NSError *error;
        
        if (encryptedData != nil || aPassword != nil) {
            NSData *decryptedData = [RNDecryptor decryptData:encryptedData
                                                withPassword:aPassword
                                                       error:&error];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                 BOOL yes = [decryptedData writeToFile:fileDecryPath atomically:NO];
                if (yes) {
                    NSLog(@"解密文件写入成功");
                    NSLog(@"写入解密PDF路径：%@",fileDecryPath);
                    self.filepath = fileDecryPath;
                    [self pushVC];
                }else{
                    NSLog(@"解密文件写入失败");
                }
            });
        }else{
            NSLog(@"加密数据为空");
        }
    });
}

#pragma mark --button点击事件
-(void)buttonClicked:(id)sender
{
    [self PDFEncryption];
}

-(void)pushVC
{
    // 1. 实例化控制器
    NSString *phrase = nil;
    
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:self.filepath password:phrase];
    
    
    if (document != nil)
    {
        ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
        readerViewController.delegate = self;
        
        readerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        readerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:readerViewController animated:YES completion:NULL];
        
    }else{
        NSLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:'%@'] failed.", __FUNCTION__, self.filepath, phrase);
        NSLog(@"没有PDF文件");
    }

}


#pragma mark - ReaderViewControllerDelegate methods

- (void)dismissReaderViewController:(ReaderViewController *)viewController
{
    
    //MARK:退出查看PDF时删除解密存储文件。
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    [fileManager removeItemAtPath:self.filepath error:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
