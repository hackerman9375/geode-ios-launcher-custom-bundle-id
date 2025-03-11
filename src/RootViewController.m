#import "GeodeInstaller.h"
#import "LCUtils/LCSharedUtils.h"
#import "LCUtils/LCUtils.h"
#import "LCUtils/Shared.h"
#import "RootViewController.h"
#import "SettingsVC.h"
#import "Theming.h"
#import "Utils.h"
#import "VerifyInstall.h"
#import "components/LogUtils.h"
#import "components/ProgressBar.h"
#import "src/LCUtils/LCAppInfo.h"
#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <dlfcn.h>
#import <objc/runtime.h>

@interface RootViewController ()

@property(nonatomic, strong) ProgressBar* progressBar;
@property(nonatomic, strong) NSTimer* launchTimer;
@property(nonatomic, assign) NSInteger countdown;

@end

@implementation RootViewController {
	NSURLSessionDownloadTask* downloadTask;
}

- (BOOL)progressVisible {
	return ![self.progressBar isHidden];
}

- (void)progressVisibility:(BOOL)hidden {
	if (self.progressBar != nil) {
		[self.progressBar setHidden:hidden];
		[self.progressBar setCancelHidden:NO];
	}
}
- (void)barProgress:(CGFloat)value {
	if (self.progressBar != nil) {
		[self.progressBar setProgress:value];
	}
}

- (void)countdownUpdate {
	self.countdown--;
	if (self.countdown < 0)
		self.countdown = 0;
	self.optionalTextLabel.text = [@"launcher.status.automatic-launch" localizeWithFormat:[NSString stringWithFormat:@"%ld", (long)self.countdown]];

	if (self.countdown <= 0) {
		self.optionalTextLabel.text = @"launcher.status.automatic-launch.end".loc;
		[self.launchTimer invalidate];
		self.launchTimer = nil;
		[self launchGame];
	}
}

- (void)updateState {
	self.logoImageView.frame = CGRectMake(self.view.center.x - 75, self.view.center.y - 130, 150, 150);
	self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.logoImageView.frame) + 15, self.view.bounds.size.width, 35);
	self.optionalTextLabel.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame) + 10, self.view.bounds.size.width, 40);
	self.launchButton.frame = CGRectMake(self.view.center.x - 95, CGRectGetMaxY(self.titleLabel.frame) + 15, 140, 45);
	self.settingsButton.frame = CGRectMake(self.view.center.x + 50, CGRectGetMaxY(self.titleLabel.frame) + 15, 45, 45);

	NSString* errStr = [[Utils getPrefs] stringForKey:@"error"];
	if (errStr != nil) {
		AppLog(@"[Geode] Found error: %@", errStr);
		[Utils showError:self title:[@"launcher.error.gd" localizeWithFormat:errStr] error:nil];
		[[Utils getPrefs] setObject:nil forKey:@"error"];
	}

	self.launchButton.backgroundColor = [Theming getAccentColor];
	[self.launchButton setTitleColor:[Theming getTextColor:[Theming getAccentColor]] forState:UIControlStateNormal];
	[self.launchButton setTintColor:[Theming getTextColor:[Theming getAccentColor]]];

	[self.optionalTextLabel setHidden:YES];
	[self.launchButton setEnabled:YES];
	[self.launchButton removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
	if ([VerifyInstall verifyAll]) {
		[UIApplication sharedApplication].idleTimerDisabled = NO;
		[self.launchButton setTitle:@"launcher.launch".loc forState:UIControlStateNormal];
		[self.launchButton setImage:[[UIImage systemImageNamed:@"play.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
		if ([[Utils getPrefs] boolForKey:@"LOAD_AUTOMATICALLY"]) {
			[self.optionalTextLabel setHidden:NO];
			self.launchButton.frame = CGRectMake(self.view.center.x - 95, CGRectGetMaxY(self.optionalTextLabel.frame) + 15, 140, 45);
			self.settingsButton.frame = CGRectMake(self.view.center.x + 50, CGRectGetMaxY(self.optionalTextLabel.frame) + 15, 45, 45);
			self.countdown = 3;
			[self countdownUpdate];
			self.launchTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdownUpdate) userInfo:nil repeats:YES];
		} else {
			[self.launchButton addTarget:self action:@selector(launchGame) forControlEvents:UIControlEventTouchUpInside];
		}
	} else {
		[self.optionalTextLabel setHidden:NO];
		if (![VerifyInstall verifyGDAuthenticity]) {
			self.launchButton.frame = CGRectMake(self.view.center.x - 85, CGRectGetMaxY(self.optionalTextLabel.frame) + 15, 110, 45);
			self.settingsButton.frame = CGRectMake(self.view.center.x + 30, CGRectGetMaxY(self.optionalTextLabel.frame) + 15, 45, 45);
			self.optionalTextLabel.text = @"launcher.status.not-verified".loc;
			[self.launchButton setTitle:@"launcher.verify-gd".loc forState:UIControlStateNormal];
			[self.launchButton setImage:[[UIImage systemImageNamed:@"checkmark.circle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
			[self.launchButton addTarget:self action:@selector(verifyGame) forControlEvents:UIControlEventTouchUpInside];
		} else if (![VerifyInstall verifyGDInstalled] || ![VerifyInstall verifyGeodeInstalled]) {
			self.launchButton.frame = CGRectMake(self.launchButton.frame.origin.x, CGRectGetMaxY(self.optionalTextLabel.frame) + 10, 140, 45);
			self.settingsButton.frame = CGRectMake(self.settingsButton.frame.origin.x, CGRectGetMaxY(self.optionalTextLabel.frame) + 10, 45, 45);
			self.optionalTextLabel.text = @"launcher.status.not-installed".loc;
			[self.launchButton setTitle:@"launcher.download".loc forState:UIControlStateNormal];
			[self.launchButton setImage:[[UIImage systemImageNamed:@"tray.and.arrow.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
							   forState:UIControlStateNormal];
			[self.launchButton addTarget:self action:@selector(downloadGame) forControlEvents:UIControlEventTouchUpInside];
		} else if ([VerifyInstall verifyAll]) {
			self.launchButton.frame = CGRectMake(self.launchButton.frame.origin.x, CGRectGetMaxY(self.optionalTextLabel.frame) + 10, 140, 45);
			self.settingsButton.frame = CGRectMake(self.settingsButton.frame.origin.x, CGRectGetMaxY(self.optionalTextLabel.frame) + 10, 45, 45);
			[self.launchButton setEnabled:NO];
			self.optionalTextLabel.text = @"launcher.status.check-updates".loc;
			[self.launchButton setTitle:@"launcher.update".loc forState:UIControlStateNormal];
			[self.launchButton setImage:[[UIImage systemImageNamed:@"tray.and.arrow.down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
							   forState:UIControlStateNormal];
			[self.launchButton addTarget:self action:@selector(updateGeode) forControlEvents:UIControlEventTouchUpInside];
			[[GeodeInstaller alloc] checkUpdates:self download:YES];
		}
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[Utils increaseLaunchCount];
	[LogUtils clearLogs];

	NSError* err;
	[LCPath ensureAppGroupPaths:&err];
	if (err) {
		AppLog(@"[Geode] error while making app paths: %@", err);
	}
	self.logoImageView = [Utils imageViewFromPDF:@"geode_logo"];
	if (self.logoImageView) {
		self.logoImageView.layer.cornerRadius = 50;
		self.logoImageView.clipsToBounds = YES;
		[self.view addSubview:self.logoImageView];
	} else {
		// self.logoImageView.backgroundColor = [UIColor redColor];
		AppLog(@"[Geode] Image is null");
	}

	self.titleLabel = [[UILabel alloc] init];
	self.titleLabel.text = @"Geode";
	self.titleLabel.textColor = [Theming getWhiteColor];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.titleLabel.font = [UIFont systemFontOfSize:35 weight:UIFontWeightRegular];
	[self.view addSubview:self.titleLabel];

	// for things like if it errored or needs installing...
	self.optionalTextLabel = [[UILabel alloc] init];
	self.optionalTextLabel.numberOfLines = 2;
	self.optionalTextLabel.text = @"launcher.status.not-installed".loc;
	self.optionalTextLabel.textColor = [Theming getFooterColor];
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
	[self.settingsButton setTintColor:[Theming getWhiteColor]];
	[self.settingsButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:self.settingsButton];

	// progress bar for downloading!
	self.progressBar = [[ProgressBar alloc] initWithFrame:CGRectMake(self.view.center.x - 140, self.view.center.y + 200, 280, 68)
											 progressText:@"launcher.progress.text".loc // note for me, nil for no string
										 showCancelButton:YES
													 root:self];
	[self.progressBar setHidden:YES];
	[self.view addSubview:self.progressBar];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	[self updateState];
}

- (void)verifyGame {
	[VerifyInstall startVerifyGDAuth:self];
}

- (void)showSettings {
	if (self.launchTimer != nil) {
		[self.launchTimer invalidate];
		self.launchTimer = nil;
	}
	SettingsVC* settings = [[SettingsVC alloc] initWithNibName:nil bundle:nil];
	settings.root = self;
	UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:settings];
	[self presentViewController:navController animated:YES completion:nil];
}
- (void)updateGeode {
	[[GeodeInstaller alloc] checkUpdates:self download:YES];
}
- (void)downloadGame {
	[self.launchButton setEnabled:NO];
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	if ([VerifyInstall verifyGDInstalled] && ![VerifyInstall verifyGeodeInstalled]) {
		[[[GeodeInstaller alloc] init] startInstall:self ignoreRoot:NO];
	} else {
		[self.progressBar setHidden:NO];
		NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
		downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:@"https://jinx.firee.dev/gode/Geometry-2.207.ipa"]];
		[downloadTask resume];
	}
}

- (void)signApp:(BOOL)force completionHandler:(void (^)(BOOL success, NSString* error))completionHandler {
	if (![[Utils getPrefs] boolForKey:@"JITLESS"])
		return completionHandler(YES, nil);
	LCAppInfo* app = [[LCAppInfo alloc] initWithBundlePath:[[LCPath bundlePath] URLByAppendingPathComponent:@"com.robtop.geometryjump.app"].path];
	app.signer = [[Utils getPrefs] boolForKey:@"USE_ZSIGN"] ? 1 : 0;
	[app patchExecAndSignIfNeedWithCompletionHandler:^(BOOL signSuccess, NSString* signError) {
		if (signError)
			return completionHandler(NO, signError);
		[LCUtils signTweaks:[LCPath tweakPath] force:force signer:app.signer progressHandler:^(NSProgress* progress) {} completion:^(NSError* error) {
			if (error != nil) {
				AppLog(@"[Geode] Detailed error for signing tweaks: %@", error);
				return completionHandler(
					NO, [NSString stringWithFormat:@"Couldn't sign tweaks. Please make sure that you have either patched %@, or imported a certificate in settings.",
												   [LCUtils getStoreName]]);
			}
			[LCUtils signMods:[[LCPath dataPath] URLByAppendingPathComponent:@"GeometryDash/Documents/game/geode"] force:force signer:app.signer
				progressHandler:^(NSProgress* progress) {} completion:^(NSError* error) {
					if (error != nil) {
						AppLog(@"[Geode] Detailed error for signing mods: %@", error);
						return completionHandler(
							NO, [NSString stringWithFormat:@"Couldn't sign mods. Please make sure that you have either patched %@, or imported a certificate in settings.",
														   [LCUtils getStoreName]]);
					}
					completionHandler(YES, nil);
				}];
		}];
	} progressHandler:^(NSProgress* signProgress) {} forceSign:force];
}

- (void)launchGame {
	[self.launchButton setEnabled:NO];
	if ([[Utils getPrefs] boolForKey:@"MANUAL_REOPEN"] && ![[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
		[[Utils getPrefs] setValue:[Utils gdBundleName] forKey:@"selected"];
		[[Utils getPrefs] setValue:@"GeometryDash" forKey:@"selectedContainer"];
		[[Utils getPrefs] setBool:NO forKey:@"safemode"];
		NSFileManager* fm = [NSFileManager defaultManager];
		[fm createFileAtPath:[[LCPath docPath] URLByAppendingPathComponent:@"jitflag"].path contents:[[NSData alloc] init] attributes:@{}];
		// get around NSUserDefaults because sometimes it works and doesnt work when relaunching...
		[Utils showNotice:self title:@"launcher.relaunch-notice".loc];
		return;
	}
	if ([[Utils getPrefs] boolForKey:@"USE_TWEAK"]) {
		[Utils tweakLaunch_withSafeMode:false];
		return;
	}
	NSString* openURL = [NSString stringWithFormat:@"geode://launch"];
	NSURL* url = [NSURL URLWithString:openURL];
	if ([[NSClassFromString(@"UIApplication") sharedApplication] canOpenURL:url]) {
		[[NSClassFromString(@"UIApplication") sharedApplication] openURL:url options:@{} completionHandler:nil];
		return;
	}
	/*
		[[Utils getPrefs] setValue:[Utils gdBundleName] forKey:@"selected"];
		[[Utils getPrefs] setValue:@"GeometryDash" forKey:@"selectedContainer"];
		[[Utils getPrefs] setBool:NO forKey:@"safemode"];
		[self signApp:NO completionHandler:^(BOOL success, NSString *error){
			if (!success) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[Utils showError:self title:error error:nil];
					[self updateState];
				});
				return;
			}
			if (![LCUtils launchToGuestApp]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					NSFileManager *fm = [NSFileManager defaultManager];
					[fm createFileAtPath:
						[[LCPath docPath] URLByAppendingPathComponent:@"jitflag"].path
						contents:[[NSData alloc] init]
						attributes:@{}
					];
					 // get around NSUserDefaults because sometimes it works and doesnt work when relaunching...
					[Utils showNotice:self title:@"Relaunch the app with JIT to start Geode!"];
				});
			}
		}];
		*/
}

// download part because im too lazy to impl delegates in the other class
// updating
- (void)URLSession:(NSURLSession*)session
				 downloadTask:(NSURLSessionDownloadTask*)downloadTask
				 didWriteData:(int64_t)bytesWritten
			totalBytesWritten:(int64_t)totalBytesWritten
	totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	dispatch_async(dispatch_get_main_queue(), ^{
		CGFloat progress = (CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite * 100.0;
		[self.progressBar setProgress:progress];
	});
}

// finish
- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask didFinishDownloadingToURL:(NSURL*)location {
	dispatch_async(dispatch_get_main_queue(), ^{
		// so apparently i have to run this asynchronously or else it wont work... WHY
		AppLog(@"[Geode] start installing ipa!");
		self.optionalTextLabel.text = @"launcher.status.extracting".loc;
		[self.progressBar setHidden:NO];
		[self.progressBar setCancelHidden:YES];
	});
	// and i cant run this asynchronously!? this is... WHY
	[VerifyInstall startGDInstall:self url:location];
}

// error
- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didCompleteWithError:(NSError*)error {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (error) {
			[Utils showError:self title:@"launcher.error.download-fail".loc error:error];
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
