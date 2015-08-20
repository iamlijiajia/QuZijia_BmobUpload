//
//  UploadViewController.m
//  QuZijia_AVUpload
//
//  Created by lijiajia on 15/8/14.
//  Copyright (c) 2015年 lijiajia. All rights reserved.
//

#import "UploadViewController.h"
#import <BmobSDK/Bmob.h>
#import <BmobSDK/BmobProFile.h>

#define KTestDownLoadImageViewTag       1000

@interface UploadViewController ()

@property (nonatomic , strong) UIProgressView *progressV;
@property (nonatomic , strong) NSMutableArray *imageResources;
@property (nonatomic , strong) NSMutableArray *imagePaths;

@property (nonatomic , strong) NSArray *imageRealFileNames;
@property (nonatomic) BOOL upLoadFinished;

@property (nonatomic) NSInteger downloadIndex;

@property (nonatomic) BOOL allFilesOK;

@end

@implementation UploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.downloadIndex = 0;
    self.allFilesOK = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *uploadButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 100, 150, 50)];
    
    [uploadButton setBackgroundImage:[UIImage imageNamed:@"button.png"] forState:UIControlStateNormal];
    [uploadButton setBackgroundImage:[UIImage imageNamed:@"button_grey.png"] forState:UIControlStateHighlighted];
    
    [uploadButton setTitle:@"上传所有数据" forState:UIControlStateNormal];
    [uploadButton addTarget:self action:@selector(UploadAll:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:uploadButton];
    
    
    UIButton *uploadImageButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 200, 150, 50)];
    
    [uploadImageButton setBackgroundImage:[UIImage imageNamed:@"button.png"] forState:UIControlStateNormal];
    [uploadImageButton setBackgroundImage:[UIImage imageNamed:@"button_grey.png"] forState:UIControlStateHighlighted];
    
    [uploadImageButton setTitle:@"下载图片并显示" forState:UIControlStateNormal];
    [uploadImageButton addTarget:self action:@selector(downloadImage:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:uploadImageButton];
    
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(200, 200, 100, 100)];
    imgView.tag = KTestDownLoadImageViewTag;
    [self.view addSubview:imgView];
//
    
    
//    UIButton *uploadButtonTest = [[UIButton alloc] initWithFrame:CGRectMake(20, 300, 150, 50)];
//    
//    [uploadButtonTest setBackgroundImage:[UIImage imageNamed:@"button.png"] forState:UIControlStateNormal];
//    [uploadButtonTest setBackgroundImage:[UIImage imageNamed:@"button_grey.png"] forState:UIControlStateHighlighted];
//    
//    [uploadButtonTest setTitle:@"创建类并上传PList" forState:UIControlStateNormal];
//    [uploadButtonTest addTarget:self action:@selector(UploadDoc:) forControlEvents:UIControlEventTouchUpInside];
//    
//    [self.view addSubview:uploadButtonTest];
    
    self.progressV = [[UIProgressView alloc] initWithFrame:CGRectMake(20, self.view.frame.size.height - 80, self.view.frame.size.width - 40 , 20)];
    [self.view addSubview:self.progressV];
    self.progressV.hidden = YES;
}

- (void)UploadRouteArray:(NSArray*)routeArray
{
    for (NSDictionary *dic in routeArray)
    {
        BmobObject *route_1_0 = [BmobObject objectWithClassName:@"Route_1_0"];
        [route_1_0 setObject:[dic objectForKey:@"name"] forKey:@"name"];
        [route_1_0 setObject:[dic objectForKey:@"intro"] forKey:@"intro"];
        [route_1_0 setObject:[dic objectForKey:@"detailIntro"] forKey:@"detailIntro"];
        [route_1_0 setObject:[dic objectForKey:@"baseIntroThumb"] forKey:@"baseIntroThumb"];
        [route_1_0 setObject:[dic objectForKey:@"city_of_hotel_Info"] forKey:@"city_of_hotel_Info"];
        [route_1_0 setObject:[dic objectForKey:@"introImages"] forKey:@"introImages"];
        [route_1_0 setObject:[dic objectForKey:@"routeImage"] forKey:@"routeImage"];
        
        [route_1_0 saveInBackground];
    }
}

- (void)UploadAll:(id)sender
{
    self.progressV.hidden = NO;
    self.upLoadFinished = NO;
    
    self.imagePaths = [[NSMutableArray alloc] init];
    self.imageResources = [[NSMutableArray alloc] init];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"routeGroup" ofType:@"plist"];
    NSMutableArray *routeArray = [NSMutableArray arrayWithContentsOfFile:path];
    __block UploadViewController *blockSelf = self;
    
    [self loopArray:routeArray];
    
    if (self.allFilesOK)
    {
        [BmobProFile uploadFilesWithPaths:self.imagePaths resultBlock:^(NSArray *filenameArray, NSArray *urlArray, NSArray *bmobFileArray, NSError *error) {
            blockSelf.progressV.hidden = YES;
            blockSelf.imageRealFileNames = [NSArray arrayWithArray:filenameArray];
            blockSelf.upLoadFinished = YES;
            
            [blockSelf loopArray:routeArray];
            
            [blockSelf UploadRouteArray:routeArray];
            
        } progress:^(NSUInteger index, CGFloat progress) {
            blockSelf.progressV.progress = progress;
        }];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"图片资源缺失，具体请看log！" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alert show];
    }
}


- (void)loopDictionary:(NSMutableDictionary *)dic
{
    if (!dic)
    {
        return;
    }
    
    NSArray *allKeys = [dic allKeys];
    for (int i = 0; i < allKeys.count; i++)
    {
        NSString *key = [allKeys objectAtIndex:i];
        if (_upLoadFinished)
        {
            [self checkImageToReset:[dic objectForKey:key] inDictionary:dic withKey:key];
        }
        else
        {
            [self checkImageForUpload:[dic objectForKey:key]];
        }
    }
}

- (void)loopArray:(NSMutableArray *)array
{
    if (!array)
    {
        return;
    }
    
    for (int i = 0; i < array.count; i++)
    {
        if (_upLoadFinished)
        {
            [self checkImageToReset:[array objectAtIndex:i] inArray:array];
        }
        else
        {
            [self checkImageForUpload:[array objectAtIndex:i]];
        }
    }
}

- (void)checkImageForUpload:(id)value
{
    if ([value isKindOfClass:[NSMutableDictionary class]])
    {
        [self loopDictionary:value];
    }
    else if([value isKindOfClass:[NSMutableArray class]])
    {
        [self loopArray:value];
    }
    else
    {
        if ([value isKindOfClass:[NSString class]])
        {
            NSString *str = (NSString *)value;
            if ([str hasSuffix:@".jpg"] || [str hasSuffix:@".png"])
            {
                NSBundle *mainBundle = [NSBundle mainBundle];
                NSString *bundlePath = [mainBundle bundlePath];
                NSString *path = [bundlePath stringByAppendingPathComponent:str];
                if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    NSLog(@"ERROR: file not exist! filename = %@" , str);
                }
                else
                {
                    [self.imageResources addObject:str];
                    
                    [self.imagePaths addObject:path];
                }
            }
        }
    }
}

- (void)checkImageToReset:(id)value inDictionary:(NSMutableDictionary *)dic withKey:(NSString *)key
{
    if ([value isKindOfClass:[NSMutableDictionary class]])
    {
        [self loopDictionary:value];
    }
    else if([value isKindOfClass:[NSMutableArray class]])
    {
        [self loopArray:value];
    }
    else
    {
        if ([value isKindOfClass:[NSString class]] && dic && key)
        {
            NSString *str = (NSString *)value;
            if ([str hasSuffix:@".jpg"] || [str hasSuffix:@".png"])
            {
                NSInteger index = [self.imageResources indexOfObject:str];
                NSString *name = [_imageRealFileNames objectAtIndex:index];
                [dic setObject:name forKey:key];
            }
        }
    }
}



- (void)checkImageToReset:(id)value inArray:(NSMutableArray *)array
{
    if ([value isKindOfClass:[NSMutableDictionary class]])
    {
        [self loopDictionary:value];
    }
    else if([value isKindOfClass:[NSMutableArray class]])
    {
        [self loopArray:value];
    }
    else
    {
        if ([value isKindOfClass:[NSString class]] && array)
        {
            NSString *str = (NSString *)value;
            if ([str hasSuffix:@".jpg"] || [str hasSuffix:@".png"])
            {
                NSInteger index = [_imageResources indexOfObject:str];
                NSInteger valueIndex = [array indexOfObject:value];
                [array removeObject:value];
                [array insertObject:[_imageRealFileNames objectAtIndex:index] atIndex:valueIndex];
            }
        }
    }
}

- (void)downloadImage:(id)sender
{
    
    if (self.imageRealFileNames)
    {
        
        if (self.downloadIndex >= self.imageRealFileNames.count)
        {
            self.downloadIndex = 0;
        }
        
        __block UploadViewController *blockSelf = self;
        blockSelf.progressV.hidden = NO;
        
        NSString *imagePath = [self.imageRealFileNames objectAtIndex:self.downloadIndex];
        [BmobProFile downloadFileWithFilename:imagePath block:^(BOOL isSuccessful, NSError *error, NSString *filepath) {
            if (isSuccessful)
            {
                blockSelf.progressV.hidden = YES;
                
                UIImage *img = [UIImage imageNamed:filepath];
                UIImageView *imgView = (UIImageView *)[self.view viewWithTag:KTestDownLoadImageViewTag];
                imgView.image = img;
                
                blockSelf.downloadIndex++;
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.domain message:error.description delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
                [alert show];
            }
        } progress:^(CGFloat progress) {
            blockSelf.progressV.progress = progress;
        }];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"请先上传文件！" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
