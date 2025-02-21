#import "RootViewController.h"
#include "src/Utils.h"
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation RootViewController
- (void)viewDidLoad {
    [super viewDidLoad];

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
    self.optionalTextLabel.text = @"";
    self.optionalTextLabel.textColor = [UIColor lightGrayColor];
    self.optionalTextLabel.textAlignment = NSTextAlignmentCenter;
    self.optionalTextLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:self.optionalTextLabel];

    // Launch or install button
    self.launchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.launchButton setTitle:@"Launch" forState:UIControlStateNormal];
    [self.launchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.launchButton.backgroundColor = [UIColor colorWithRed: 0.70 green: 0.77 blue: 1.00 alpha: 1.00];
    self.launchButton.layer.cornerRadius = 22.5;

    [self.launchButton setImage:[[UIImage systemImageNamed:@"play.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.launchButton setTintColor:[UIColor blackColor]];
    self.launchButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    self.launchButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8);
    [self.launchButton addTarget:self action:@selector(launchGame) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.launchButton];

    // Settings button for settings!
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.settingsButton.backgroundColor = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 1.00];
    self.settingsButton.clipsToBounds = YES;
    self.settingsButton.layer.cornerRadius = 22.5;
    [self.settingsButton setImage:[[UIImage systemImageNamed:@"gearshape.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.settingsButton setTintColor:[UIColor whiteColor]];
    [self.view addSubview:self.settingsButton];

    // Info Button for Credits and other
    self.infoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.infoButton setTitle:@"?" forState:UIControlStateNormal];
    [self.infoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.infoButton.backgroundColor = [UIColor colorWithRed: 0.1 green: 0.1 blue: 0.1 alpha: 1.00];
    self.infoButton.clipsToBounds = YES;
    self.infoButton.layer.cornerRadius = 22.5;
    [self.view addSubview:self.infoButton];


}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.logoImageView.frame = CGRectMake(self.view.center.x - 70, self.view.center.y - 130, 150, 150);
    self.projectLabel.frame = CGRectMake(0, CGRectGetMaxY(self.logoImageView.frame) + 15, self.view.bounds.size.width, 35);
    self.optionalTextLabel.frame = CGRectMake(0, CGRectGetMaxY(self.projectLabel.frame) + 5, self.view.bounds.size.width, 20);
    self.launchButton.frame = CGRectMake(self.view.center.x - 95, CGRectGetMaxY(self.optionalTextLabel.frame), 140, 45);
    self.settingsButton.frame = CGRectMake(self.view.center.x + 50, CGRectGetMaxY(self.optionalTextLabel.frame), 45, 45);
    self.infoButton.frame = CGRectMake((self.view.bounds.size.width) - 60, 50, 45, 45);
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

- (void)launchGame {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"placeholder"
        message:@"this is a placeholder for when you click launch. what? did you think you could just *launch* gd? also you're not jailbroken"
        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"yes i did" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    if ([Utils isJailbroken]) {
        NSString *appBundleIdentifier = @"com.robtop.geometryjump";
        [[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:appBundleIdentifier];
    } else {
        [self presentViewController:alert animated:YES completion:nil];
    }
    
}
@end
