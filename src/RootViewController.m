#import "RootViewController.h"
#import "GeodeInstaller.h"
#import "SettingsController.h"
#import "LCUtils/Shared.h"
#import "LCUtils/LCSharedUtils.h"
#import "LCUtils/LCUtils.h"
#import "Theming.h"
#import "components/ProgressBar.h"
#import "VerifyInstall.h"
#import <objc/runtime.h>
#import "Utils.h"
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <MobileCoreServices/MobileCoreServices.h>

/*
@interface RootViewController () <UIDocumentPickerDelegate>

@end
*/

@interface RootViewController ()

@property (nonatomic, strong) ProgressBar *progressBar;
@property (nonatomic, strong) NSTimer *launchTimer;

@end

@implementation RootViewController {
    NSURLSessionDownloadTask *downloadTask;
}

- (BOOL)progressVisible {
    return ![self.progressBar isHidden];
}

- (void)progressVisibility:(BOOL)hidden {
    if (self.progressBar != nil) {
        [self.progressBar setHidden:hidden];
    }
}
- (void)barProgress:(CGFloat)value {
    if (self.progressBar != nil) {
        [self.progressBar setProgress:value];
    }
}
- (void)updateState {
    self.logoImageView.frame = CGRectMake(self.view.center.x - 70, self.view.center.y - 130, 150, 150);
    self.projectLabel.frame = CGRectMake(0, CGRectGetMaxY(self.logoImageView.frame) + 15, self.view.bounds.size.width, 35);
    //self.optionalTextLabel.frame = CGRectMake(0, CGRectGetMaxY(self.projectLabel.frame) + 15, self.view.bounds.size.width, 20);
    self.optionalTextLabel.frame = CGRectMake(0, CGRectGetMaxY(self.projectLabel.frame) + 10, self.view.bounds.size.width, 40);
    //self.launchButton.frame = CGRectMake(self.view.center.x - 95, CGRectGetMaxY(self.optionalTextLabel.frame), 140, 45);
    //self.settingsButton.frame = CGRectMake(self.view.center.x + 50, CGRectGetMaxY(self.optionalTextLabel.frame), 45, 45);
    self.launchButton.frame = CGRectMake(self.view.center.x - 95, CGRectGetMaxY(self.projectLabel.frame) + 15, 140, 45);
    self.settingsButton.frame = CGRectMake(self.view.center.x + 50, CGRectGetMaxY(self.projectLabel.frame) + 15, 45, 45);
    self.launchButton.backgroundColor = [Theming getAccentColor];//[UIColor colorWithRed: 0.70 green: 0.77 blue: 1.00 alpha: 1.00];
    [self.launchButton setTitleColor:[Theming getTextColor:[Theming getAccentColor]] forState:UIControlStateNormal];
    [self.launchButton setTintColor:[Theming getTextColor:[Theming getAccentColor]]];

    [self.optionalTextLabel setHidden:YES];
    [self.launchButton setEnabled:YES];
    [self.launchButton removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
    if ([VerifyInstall verifyAll]) {
        [self.launchButton setTitle:@"Launch" forState:UIControlStateNormal];
        [self.launchButton setImage:[[UIImage systemImageNamed:@"play.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LOAD_AUTOMATICALLY"]) {
            self.launchTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(launchGame) userInfo:nil repeats:NO];
        } else {
            [self.launchButton addTarget:self action:@selector(launchGame) forControlEvents:UIControlEventTouchUpInside];
        }
    } else {
        [self.optionalTextLabel setHidden:NO];
        if (![VerifyInstall verifyGDAuthenticity]) {
            self.launchButton.frame = CGRectMake(self.view.center.x - 85, CGRectGetMaxY(self.optionalTextLabel.frame) + 15, 110, 45);
            self.settingsButton.frame = CGRectMake(self.view.center.x + 30, CGRectGetMaxY(self.optionalTextLabel.frame) + 15, 45, 45);
            self.optionalTextLabel.text = @"Geometry Dash is not verified.\nYou need to verify that you installed the app.";
            [self.launchButton setTitle:@"Verify" forState:UIControlStateNormal];
            [self.launchButton setImage:[[UIImage systemImageNamed:@"checkmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [self.launchButton addTarget:self action:@selector(verifyGame) forControlEvents:UIControlEventTouchUpInside];
        } else if (![VerifyInstall verifyGDInstalled] || ![VerifyInstall verifyGeodeInstalled]) {
            self.launchButton.frame = CGRectMake(self.launchButton.frame.origin.x, CGRectGetMaxY(self.optionalTextLabel.frame) + 10, 140, 45);
            self.settingsButton.frame = CGRectMake(self.settingsButton.frame.origin.x, CGRectGetMaxY(self.optionalTextLabel.frame) + 10, 45, 45);
            if (![VerifyInstall verifyGDInstalled]) {
                self.optionalTextLabel.text = @"Geometry Dash is not installed.";
            } else {
                self.optionalTextLabel.text = @"Geode is not installed.";
            }
            [self.launchButton setTitle:@"Download" forState:UIControlStateNormal];
            [self.launchButton setImage:[[UIImage systemImageNamed:@"tray.and.arrow.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [self.launchButton addTarget:self action:@selector(downloadGame) forControlEvents:UIControlEventTouchUpInside];
        } else if ([VerifyInstall verifyAll]) {
            self.launchButton.frame = CGRectMake(self.launchButton.frame.origin.x, CGRectGetMaxY(self.optionalTextLabel.frame) + 10, 140, 45);
            self.settingsButton.frame = CGRectMake(self.settingsButton.frame.origin.x, CGRectGetMaxY(self.optionalTextLabel.frame) + 10, 45, 45);
            [self.launchButton setEnabled:NO];
            self.optionalTextLabel.text = @"Checking for updates...";
            [self.launchButton setTitle:@"Update" forState:UIControlStateNormal];
            [self.launchButton setImage:[[UIImage systemImageNamed:@"tray.and.arrow.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [self.launchButton addTarget:self action:@selector(updateGeode) forControlEvents:UIControlEventTouchUpInside];
            [[GeodeInstaller alloc] checkUpdates:self download:YES];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSError* err;
    [LCPath ensureAppGroupPaths:&err];
    if (err) {
        NSLog(@"error while making app paths: %@", err);
    }
    self.logoImageView = [Utils imageViewFromPDF:@"geode_logo"];
    if (self.logoImageView) {
        self.logoImageView.layer.cornerRadius = 50;
        self.logoImageView.clipsToBounds = YES;
        [self.view addSubview:self.logoImageView];
    } else {
        //self.logoImageView.backgroundColor = [UIColor redColor];
        NSLog(@"Image is null");
    }

    self.projectLabel = [[UILabel alloc] init];
    self.projectLabel.text = @"Geode";
    self.projectLabel.textColor = [UIColor whiteColor];
    self.projectLabel.textAlignment = NSTextAlignmentCenter;
    self.projectLabel.font = [UIFont systemFontOfSize:35 weight:UIFontWeightRegular];
    [self.view addSubview:self.projectLabel];

    // for things like if it errored or needs installing...
    self.optionalTextLabel = [[UILabel alloc] init];
    self.optionalTextLabel.numberOfLines = 2;
    self.optionalTextLabel.text = @"Geode is not installed.";
    self.optionalTextLabel.textColor = [UIColor lightGrayColor];
    self.optionalTextLabel.textAlignment = NSTextAlignmentCenter;
    self.optionalTextLabel.font = [UIFont systemFontOfSize:16];
    [self.optionalTextLabel setHidden:YES];
    [self.view addSubview:self.optionalTextLabel];

    // Launch or install button
    self.launchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    self.launchButton.layer.cornerRadius = 22.5;
    self.launchButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    self.launchButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8);
    [self.view addSubview:self.launchButton];

    // Settings button for settings!
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.settingsButton.backgroundColor = [Theming getDarkColor];
    self.settingsButton.clipsToBounds = YES;
    self.settingsButton.layer.cornerRadius = 22.5;
    [self.settingsButton setImage:[[UIImage systemImageNamed:@"gearshape.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.settingsButton setTintColor:[UIColor whiteColor]];
    [self.settingsButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.settingsButton];

    // progress bar for downloading!
    self.progressBar = [[ProgressBar alloc]
        initWithFrame:CGRectMake(self.view.center.x - 140, self.view.center.y + 200, 280, 68)
        progressText:@"Downloading... {percent}%" // note for me, nil for no string
        showCancelButton:YES
        root:self
    ];
    [self.progressBar setHidden:YES];
    [self.view addSubview:self.progressBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self updateState];
}

- (void)openDebFile {
    if (![Utils isJailbroken]) return;
    NSString *debFileName = @"com.somerandomtweak.okay-0.0.1.deb"; // CHANGE THIS
    NSString *debFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:debFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:debFilePath]) {
        NSURL *debFileURL = [NSURL fileURLWithPath:debFilePath];
        UIDocumentInteractionController *controller = [UIDocumentInteractionController interactionControllerWithURL:debFileURL];
        controller.UTI = @"i.have.no.idea"; // there is no documentation... 
        [controller presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
    } else {
        NSLog(@"File does not exist at path: %@", debFilePath);
    }
}

- (void)verifyGame {
    [VerifyInstall startVerifyGDAuth:self];
}

- (void)showSettings {
    if (self.launchTimer != nil) {
        [self.launchTimer invalidate];
        self.launchTimer = nil;
    }
    SettingsController *settings = [[SettingsController alloc] initWithNibName:nil bundle:nil];
    settings.root = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settings];
    [self presentViewController:navController animated:YES completion:nil];
}
- (void)updateGeode {
    [[GeodeInstaller alloc] checkUpdates:self download:YES];
}
- (void)downloadGame {
    /*UIDocumentPickerViewController *documentPickerController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.item"] inMode:UIDocumentPickerModeImport];
    documentPickerController.delegate = self;
    documentPickerController.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:documentPickerController animated:YES completion:nil];*/

    /*
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"notice"
        message:@"currently unimplemented"
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"WHY" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];*/
    [self.launchButton setEnabled:NO];
    if ([VerifyInstall verifyGDInstalled] && ![VerifyInstall verifyGeodeInstalled]) {
        [[[GeodeInstaller alloc] init] startInstall:self ignoreRoot:NO];
    } else {
        [self.progressBar setHidden:NO];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:@"https://jinx.firee.dev/gode/Geometry-2.207.ipa"]];
        [downloadTask resume];
    }
}

- (void)launchGame {
    [self.launchButton setEnabled:NO];
    NSString *openURL = [NSString stringWithFormat:@"geode://geode-launch?bundle-name=%@", [Utils gdBundleName]];
    NSURL* url = [NSURL URLWithString:openURL];
    if([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]){
        [[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
        return;
    }
    //try await signApp(force: false)
    [[NSUserDefaults standardUserDefaults] setValue:[Utils gdBundleName] forKey:@"selected"];
    [[NSUserDefaults standardUserDefaults] setValue:@"GeometryDash" forKey:@"selectedContainer"];
    [LCUtils launchToGuestApp];
}

/*
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    NSLog(@"Selected URL: %@", url);
    [VerifyInstall startGDInstall:url];
    // Use the selected URL as needed
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"cancelled"
        message:@"twas cancel"
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"WHY" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
    NSLog(@"Document picker was cancelled");
}
*/

// download part because im too lazy to impl delegates in the other class
// updating
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = (CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite * 100.0;
        [self.progressBar setProgress:progress];
    });
}

// finish
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    dispatch_async(dispatch_get_main_queue(), ^{
        // so apparently i have to run this asynchronously or else it wont work... WHY
        NSLog(@"start installing ipa!");
        self.optionalTextLabel.text = @"Extracting...";
        [self.progressBar setHidden:YES];
    });
    // and i cant run this asynchronously!? this is... WHY
    [VerifyInstall startGDInstall:self url:location];
}

// error
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            [Utils showError:self title:@"Download failed" error:error];
            [self.progressBar setHidden:YES];
        }
    });
}

- (void)cancelDownload {
    if (downloadTask != nil) {
        [downloadTask cancel];
    }
    [self.progressBar setHidden:YES];
}

@end
