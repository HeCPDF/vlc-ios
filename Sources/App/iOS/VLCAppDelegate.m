/*****************************************************************************
 * VLCAppDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Luis Fernandes <zipleen # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Soomin Lee <TheHungryBu # gmail.com>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Pratik Ray <raypratik365@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLC-Swift.h"
#import "VLCAppSceneDelegate.h"
#import "VLCMLMedia+isWatched.h"
#import "VLCPlaybackService.h"
#import <WatchConnectivity/WatchConnectivity.h>

// Keep in sync with Notification.Name.VLCMenuRequestAddSubtitleFile (PlayerViewController.swift).
static NSString *const VLCMenuRequestAddSubtitleFileNotification = @"VLCMenuRequestAddSubtitleFile";

static NSString *const VLCMainMenuIdentifierPlayback = @"org.videolan.vlc-ios.menu.playback";
static NSString *const VLCMainMenuIdentifierSubtitle = @"org.videolan.vlc-ios.menu.subtitle";

@interface VLCAppDelegate ()
{
    BOOL _isComingFromHandoff;
    id<VLCURLHandler> _urlHandlerToExecute;
    NSURL *_urlToHandle;
#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
    VLCSessionDelegate *sessionDelegate;
# endif
}

@end

@implementation VLCAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUInteger appThemeIndex = kVLCSettingAppThemeBright;
    if (@available(iOS 13.0, *)) {
        appThemeIndex = kVLCSettingAppThemeSystem;
    }

    NSDictionary *appDefaults = @{kVLCSettingAppTheme : @(appThemeIndex),
                                  kVLCSettingPasscodeEnableBiometricAuth : @(1),
                                  kVLCSettingContinueAudioInBackgroundKey : @(YES),
                                  kVLCSettingStretchAudio : @(YES),
                                  kVLCSettingDefaultPreampLevel : @(6),
                                  kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue,
                                  kVLCSettingSkipLoopFilter : kVLCSettingSkipLoopFilterNonRef,
                                  kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue,
                                  kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue,
                                  kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue,
                                  kVLCSettingSubtitlesBoldFont: kVLCSettingSubtitlesBoldFontDefaultValue,
                                  kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue,
                                  kVLCSettingHardwareDecoding : kVLCSettingHardwareDecodingDefault,
                                  kVLCSettingNetworkCaching : kVLCSettingNetworkCachingDefaultValue,
                                  kVLCSettingVolumeGesture : @(YES),
                                  kVLCSettingPlayPauseGesture : @(YES),
                                  kVLCSettingBrightnessGesture : @(YES),
                                  kVLCSettingSeekGesture : @(YES),
                                  kVLCSettingCloseGesture : @(YES),
                                  kVLCSettingSnapshotGesture : @(NO),
                                  kVLCSettingPlaybackLongTouchSpeedUp : @(YES),
                                  kVLCSettingVideoFullscreenPlayback : @(YES),
                                  kVLCSettingContinuePlayback : @(1),
                                  kVLCSettingContinueAudioPlayback : @(1),
                                  kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue,
                                  kVLCSettingNetworkRTSPTCP : @(NO),
                                  kVLCSettingNetworkRTSPHTTP : @(NO),
                                  kVLCSettingNetworkSatIPChannelListUrl : @"",
                                  kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue,
                                  kVLCSettingEqualizerProfileDisabled : @(YES),
                                  kVLCSettingPlaybackForwardBackwardEqual: @(YES),
                                  kVLCSettingPlaybackTapSwipeEqual:  @(YES),
                                  kVLCSettingPlaybackForwardSkipLength : kVLCSettingPlaybackForwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLength : kVLCSettingPlaybackBackwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackForwardSkipLengthSwipe : kVLCSettingPlaybackForwardSkipLengthSwipeDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLengthSwipe : kVLCSettingPlaybackBackwardSkipLengthSwipeDefaultValue,
                                  kVLCSettingPlaybackLockscreenSkip : @(NO),
                                  kVLCSettingPlaybackRemoteControlSkip : @(NO),
                                  kVLCSettingOpenAppForPlayback : kVLCSettingOpenAppForPlaybackDefaultValue,
                                  kVLCAutomaticallyPlayNextItem : @(YES),
                                  kVLCPlaylistPlayNextItem: @(YES),
                                  kVLCSettingEnableMediaCellTextScrolling : @(NO),
                                  kVLCSettingShowThumbnails : kVLCSettingShowThumbnailsDefaultValue,
                                  kVLCSettingShowArtworks : kVLCSettingShowArtworksDefaultValue,
                                  kVLCSettingBackupMediaLibrary : kVLCSettingBackupMediaLibraryDefaultValue,
                                  kVLCSettingCastingAudioPassthrough : @(NO),
                                  kVLCSettingCastingConversionQuality : @(2),
                                  kVLCForceSMBV1 : @(NO),
                                  kVLCAudioLibraryGridLayoutALBUMS : @(YES),
                                  kVLCAudioLibraryGridLayoutARTISTS : @(YES),
                                  kVLCAudioLibraryGridLayoutGENRES : @(YES),
                                  kVLCVideoLibraryGridLayoutALL_VIDEOS : @(YES),
                                  kVLCVideoLibraryGridLayoutVIDEO_GROUPS : @(YES),
                                  kVLCVideoLibraryGridLayoutVLCMLMediaGroupCollections : @(YES),
                                  kVLCPlayerShouldRememberState: @(YES),
                                  kVLCPlayerIsShuffleEnabled: kVLCPlayerIsShuffleEnabledDefaultValue,
                                  kVLCPlayerIsRepeatEnabled: kVLCPlayerIsRepeatEnabledDefaultValue,
                                  kVLCSettingPlaybackSpeedDefaultValue: @(1.0),
                                  kVLCPlayerShowPlaybackSpeedShortcut: @(NO),
                                  kVLCSettingAlwaysPlayURLs: @(NO),
                                  kVLCRestoreLastPlayedMedia: @(NO),
                                  kVLCSettingPlayerControlDuration: kVLCSettingPlayerControlDurationDefaultValue,
                                  kVLCSettingPauseWhenShowingControls: @(NO),
                                  kVLCAudioTabIndex: @(0)
    };
    [defaults registerDefaults:appDefaults];
}

- (void)setupTabBarAppearance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self recoverLastPlayingMedia];
    });

    VLCAppCoordinator *appCoordinator = [VLCAppCoordinator sharedInstance];
    void (^setupAppCoordinator)(void) = ^{
        [appCoordinator setTabBarController:(VLCBottomTabBarController *)self->_window.rootViewController];
    };
    [self validatePasscodeIfNeededWithCompletion:setupAppCoordinator];
}

- (void)configureShortCutItemsWithApplication:(UIApplication *)application
{
    /* add our static shortcut items the dynamic way to ease l10n and dynamic elements to be introduced later */
    UIApplicationShortcutItem *localVideoItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutLocalVideo
                                                                                 localizedTitle:NSLocalizedString(@"VIDEO",nil)
                                                                              localizedSubtitle:nil
                                                                                           icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Video"]
                                                                                       userInfo:nil];
    UIApplicationShortcutItem *localAudioItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutLocalAudio
                                                                                 localizedTitle:NSLocalizedString(@"AUDIO",nil)
                                                                              localizedSubtitle:nil
                                                                                           icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Audio"]
                                                                                       userInfo:nil];
    UIApplicationShortcutItem *localplaylistItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutPlaylist
                                                                                    localizedTitle:NSLocalizedString(@"PLAYLISTS",nil)
                                                                                 localizedSubtitle:nil
                                                                                              icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Playlist"]
                                                                                          userInfo:nil];
    UIApplicationShortcutItem *browseItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutNetwork
                                                                             localizedTitle:NSLocalizedString(@"BROWSE",nil)
                                                                          localizedSubtitle:nil
                                                                                       icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Network"]
                                                                                   userInfo:nil];
    application.shortcutItems = @[localVideoItem, localAudioItem, localplaylistItem, browseItem];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if TARGET_OS_IOS
    if (@available(iOS 13.0, *)) {
        APLog(@"Using Scene flow");
    } else {
        APLog(@"Using Traditional flow");
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.window.rootViewController = [VLCBottomTabBarController new];
        [self.window makeKeyAndVisible];
        [VLCAppearanceManager setupAppearanceWithTheme:PresentationTheme.current];
        [self setupTabBarAppearance];
    }
    self.orientationLock = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
#endif

    [self configureShortCutItemsWithApplication:application];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:([defaults integerForKey:kVLCNumberOfLaunches] + 1) forKey:kVLCNumberOfLaunches];

    UIApplicationShortcutItem *shortcutItem = launchOptions[UIApplicationLaunchOptionsShortcutItemKey];
    if (shortcutItem) {
        [[VLCAppCoordinator sharedInstance] handleShortcutItem:shortcutItem];
    }

#if (TARGET_OS_IOS || TARGET_OS_WATCH) && !NO_WATCH
    if ([WCSession isSupported]) {
        sessionDelegate = [[VLCSessionDelegate alloc] init];
        [WCSession defaultSession].delegate = sessionDelegate;
        [[WCSession defaultSession] activateSession];
    }
#endif

    return YES;
}

#pragma mark - Handoff

#if !TARGET_OS_TV
- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType
{
    return [userActivityType isEqualToString:kVLCUserActivityPlaying];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *))restorationHandler
{
    VLCMLMedia *media = [[VLCAppCoordinator sharedInstance] mediaForUserActivity:userActivity];
    if (!media) return NO;

    [self validatePasscodeIfNeededWithCompletion:^{
        [[VLCPlaybackService sharedInstance] playMedia:media];
    }];
    return YES;
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType
              error:(NSError *)error
{
    if (error.code != NSUserCancelledError){
        //TODO: present alert
    }
}
#endif

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    for (id<VLCURLHandler> handler in URLHandlers.handlers) {
        if ([handler canHandleOpenWithUrl:url options:options]) {
            /* if no passcode is set, immediately execute the handler
             * otherwise, store it for later use by the passcode controller's completion function */
            if (![[VLCKeychainCoordinator passcodeService] hasSecret]) {
                return [handler performOpenWithUrl:url options:options];
            } else {
                _urlHandlerToExecute = handler;
                _urlToHandle = url;
                return YES;
            }
        }
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self validatePasscodeIfNeededWithCompletion:^{
        //TODO: handle updating the videoview and
        if ([VLCPlaybackService sharedInstance].isPlaying){
            //TODO: push playback
        }

        /* execute a potential URL handler that was set when the app was moved into foreground */
        if (self->_urlHandlerToExecute) {
            if (![self->_urlHandlerToExecute performOpenWithUrl:self->_urlToHandle options:@{}]) {
                APLog(@"Failed to execute %@", self->_urlToHandle);
            }
            self->_urlHandlerToExecute = nil;
            self->_urlToHandle = nil;
        }
    }];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!_isComingFromHandoff) {
        [[VLCPlaybackService sharedInstance] recoverDisplayedMetadata];
    } else if(_isComingFromHandoff) {
        _isComingFromHandoff = NO;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /* save the playback position before the user kills the app */
    VLCPlaybackService *vps = [VLCPlaybackService sharedInstance];
    if (vps.isPlaying || vps.playerIsSetup) {
        VLCAppCoordinator *appCoordinator = [VLCAppCoordinator sharedInstance];
        [appCoordinator.mediaLibraryService saveMetaDataOf:nil from:vps];
    }

    VLCFavoriteService *fs = [[VLCAppCoordinator sharedInstance] favoriteService];
    [fs storeContentSynchronously];

    [self savePlayingMediaIdentifier];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    [[VLCAppCoordinator sharedInstance] handleShortcutItem:shortcutItem];
}

- (id)application:(UIApplication *)application handlerForIntent:(INIntent *)intent
{
    if (@available(iOS 14.0, *)) {
        if ([intent isKindOfClass:[INPlayMediaIntent class]] || [intent isKindOfClass:[INAddMediaIntent class]] || [intent isKindOfClass:[INSearchForMediaIntent class]]) {
            return [[SirikitIntentCoordinator alloc] initWithMediaLibraryService: [[VLCAppCoordinator sharedInstance] mediaLibraryService]];;
        }
    }
    return NULL;
}

#pragma mark - pass code validation
- (void)validatePasscodeIfNeededWithCompletion:(void(^)(void))completion
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingPasscodeOnKey] &&
        [[VLCKeychainCoordinator passcodeService] hasSecret]) {
        //TODO: Dismiss playback
        BOOL allowBiometricAuthentication = [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingPasscodeEnableBiometricAuth];

        [[VLCKeychainCoordinator passcodeService]
         validateSecretWithAllowBiometricAuthentication:allowBiometricAuthentication
         isCancellable:NO
         completion:^(BOOL success){
            completion();
        }];
    } else {
        completion();
    }
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return self.orientationLock;
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0))
{
    UISceneSessionRole role = connectingSceneSession.role;
    if ([role isEqualToString:@"CPTemplateApplicationSceneSessionRoleApplication"]) {
        return [[UISceneConfiguration alloc] initWithName:@"VLCCarPlayScene" sessionRole:role];
    }
    if ([role isEqualToString:@"UIWindowSceneSessionRoleExternalDisplayNonInteractive"] ||
        [role isEqualToString:@"UIWindowSceneSessionRoleExternalDisplay"]) {
        return [[UISceneConfiguration alloc] initWithName:@"VLCNonInteractiveWindowScene" sessionRole:role];
    }
    return [[UISceneConfiguration alloc] initWithName:@"VLCDefaultAppScene" sessionRole:role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0))
{
}

#pragma mark - Recover last playing media

- (void)savePlayingMediaIdentifier {
    VLCMLMedia *libraryMedia = [[VLCPlaybackService sharedInstance] currentlyPlayingLibraryMedia];
    VLCMLIdentifier identifier = libraryMedia ? libraryMedia.identifier : -1;

    [[NSUserDefaults standardUserDefaults] setInteger:identifier forKey:kVLCLastPlayedMediaIdentifier];
}

- (void)recoverLastPlayingMedia {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![defaults boolForKey:kVLCRestoreLastPlayedMedia]) {
        return;
    }

    VLCMLIdentifier identifier = [defaults integerForKey:kVLCLastPlayedMediaIdentifier];
    VLCMLMedia *media = [[[VLCAppCoordinator sharedInstance] mediaLibraryService] mediaFor:identifier];

    if (media.isExternalMedia) {
        // Do not recover the last playing media if it is an external one
        return;
    }

    // If media exists and not watched, recover it.
    if (media && ![media isWatched]) {
        [[VLCPlaybackService sharedInstance] playMedia:media openInMiniPlayer:YES];

        // only recover a given media once
        [defaults setInteger:-1 forKey:kVLCLastPlayedMediaIdentifier];
    }
}

#pragma mark - iPadOS main menu

// Ports a subset of the macOS VLC app's Playback/Subtitle menus to iPadOS as a real,
// mouse/trackpad-clickable top menu bar (visible in Stage Manager windowed mode, and
// via the Cmd-hold shortcuts overlay). Restricted to iPad: on iPhone this menu bar is
// never shown to the user, so building it would be dead code that's easy to get wrong
// without ever surfacing a bug.
- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder API_AVAILABLE(ios(13.0))
{
    [super buildMenuWithBuilder:builder];

    if (builder.system != UIMenuSystem.mainSystem) {
        return;
    }
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        return;
    }

    UICommand *playPause = [UIKeyCommand commandWithTitle:NSLocalizedString(@"PLAY_PAUSE_BUTTON", nil)
                                                      image:nil
                                                     action:@selector(vlc_menuPlayPause)
                                                      input:@" "
                                              modifierFlags:0
                                               propertyList:nil];
    UICommand *stop = [UIKeyCommand commandWithTitle:NSLocalizedString(@"MENU_STOP", nil)
                                                image:nil
                                               action:@selector(vlc_menuStop)
                                                input:@"."
                                        modifierFlags:UIKeyModifierCommand
                                         propertyList:nil];
    UICommand *next = [UIKeyCommand commandWithTitle:NSLocalizedString(@"MENU_NEXT", nil)
                                                image:nil
                                               action:@selector(vlc_menuNext)
                                                input:UIKeyInputRightArrow
                                        modifierFlags:UIKeyModifierCommand
                                         propertyList:nil];
    UICommand *previous = [UIKeyCommand commandWithTitle:NSLocalizedString(@"MENU_PREVIOUS", nil)
                                                    image:nil
                                                   action:@selector(vlc_menuPrevious)
                                                    input:UIKeyInputLeftArrow
                                            modifierFlags:UIKeyModifierCommand
                                             propertyList:nil];
    UICommand *jumpForward = [UIKeyCommand commandWithTitle:NSLocalizedString(@"MENU_JUMP_FORWARD", nil)
                                                        image:nil
                                                       action:@selector(vlc_menuJumpForward)
                                                        input:UIKeyInputRightArrow
                                                modifierFlags:UIKeyModifierAlternate
                                                 propertyList:nil];
    UICommand *jumpBackward = [UIKeyCommand commandWithTitle:NSLocalizedString(@"MENU_JUMP_BACKWARD", nil)
                                                         image:nil
                                                        action:@selector(vlc_menuJumpBackward)
                                                         input:UIKeyInputLeftArrow
                                                 modifierFlags:UIKeyModifierAlternate
                                                  propertyList:nil];
    UICommand *toggleRepeat = [UICommand commandWithTitle:NSLocalizedString(@"REPEAT_MODE", nil)
                                                     image:nil
                                                    action:@selector(vlc_menuToggleRepeat)
                                              propertyList:nil];
    UICommand *toggleShuffle = [UICommand commandWithTitle:NSLocalizedString(@"SHUFFLE", nil)
                                                      image:nil
                                                     action:@selector(vlc_menuToggleShuffle)
                                               propertyList:nil];
    UICommand *togglePiP = [UICommand commandWithTitle:NSLocalizedString(@"MENU_TOGGLE_PIP", nil)
                                                  image:nil
                                                 action:@selector(vlc_menuTogglePictureInPicture)
                                           propertyList:nil];
    UICommand *cycleAspectRatio = [UICommand commandWithTitle:NSLocalizedString(@"VIDEO_ASPECT_RATIO_BUTTON", nil)
                                                         image:nil
                                                        action:@selector(vlc_menuCycleAspectRatio)
                                                  propertyList:nil];

    UIMenu *playbackMenu = [UIMenu menuWithTitle:NSLocalizedString(@"MENU_PLAYBACK", nil)
                                            image:nil
                                       identifier:VLCMainMenuIdentifierPlayback
                                          options:0
                                         children:@[playPause, stop, previous, next,
                                                    jumpBackward, jumpForward,
                                                    toggleRepeat, toggleShuffle,
                                                    togglePiP, cycleAspectRatio]];
    [builder insertSiblingMenu:playbackMenu afterMenuForIdentifier:UIMenuFile];

    UICommand *addSubtitleFile = [UICommand commandWithTitle:NSLocalizedString(@"LOAD_EXTERNAL", nil)
                                                        image:nil
                                                       action:@selector(vlc_menuAddSubtitleFile)
                                                 propertyList:nil];
    UICommand *increaseSubtitleDelay = [UIKeyCommand commandWithTitle:NSLocalizedString(@"INCREASE_SUBTITLES_DELAY", nil)
                                                                 image:nil
                                                                action:@selector(vlc_menuIncreaseSubtitleDelay)
                                                                 input:@"="
                                                         modifierFlags:UIKeyModifierCommand
                                                          propertyList:nil];
    UICommand *decreaseSubtitleDelay = [UIKeyCommand commandWithTitle:NSLocalizedString(@"DECREASE_SUBTITLES_DELAY", nil)
                                                                 image:nil
                                                                action:@selector(vlc_menuDecreaseSubtitleDelay)
                                                                 input:@"-"
                                                         modifierFlags:UIKeyModifierCommand
                                                          propertyList:nil];

    UIMenu *subtitleMenu = [UIMenu menuWithTitle:NSLocalizedString(@"SUBTITLES", nil)
                                            image:nil
                                       identifier:VLCMainMenuIdentifierSubtitle
                                          options:0
                                         children:@[addSubtitleFile, increaseSubtitleDelay, decreaseSubtitleDelay]];
    [builder insertSiblingMenu:subtitleMenu afterMenuForIdentifier:VLCMainMenuIdentifierPlayback];
}

#pragma mark - iPadOS main menu actions

- (void)vlc_menuPlayPause
{
    [[VLCPlaybackService sharedInstance] playPause];
}

- (void)vlc_menuStop
{
    [[VLCPlaybackService sharedInstance] stopPlayback];
}

- (void)vlc_menuNext
{
    [[VLCPlaybackService sharedInstance] next];
}

- (void)vlc_menuPrevious
{
    [[VLCPlaybackService sharedInstance] previous];
}

- (void)vlc_menuJumpForward
{
    [[VLCPlaybackService sharedInstance] jumpForward:10];
}

- (void)vlc_menuJumpBackward
{
    [[VLCPlaybackService sharedInstance] jumpBackward:10];
}

- (void)vlc_menuToggleRepeat
{
    [[VLCPlaybackService sharedInstance] toggleRepeatMode];
}

- (void)vlc_menuToggleShuffle
{
    VLCPlaybackService *service = [VLCPlaybackService sharedInstance];
    service.shuffleMode = !service.shuffleMode;
}

- (void)vlc_menuTogglePictureInPicture
{
    [[VLCPlaybackService sharedInstance] togglePictureInPicture];
}

- (void)vlc_menuCycleAspectRatio
{
    [[VLCPlaybackService sharedInstance] switchAspectRatio:NO];
}

- (void)vlc_menuAddSubtitleFile
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCMenuRequestAddSubtitleFileNotification
                                                         object:nil];
}

- (void)vlc_menuIncreaseSubtitleDelay
{
    VLCPlaybackService *service = [VLCPlaybackService sharedInstance];
    service.subtitleDelay = service.subtitleDelay + 50.f;
}

- (void)vlc_menuDecreaseSubtitleDelay
{
    VLCPlaybackService *service = [VLCPlaybackService sharedInstance];
    service.subtitleDelay = service.subtitleDelay - 50.f;
}

@end
