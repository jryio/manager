# Intentional macOS defaults inventory
- source: `defaults read <domain>` for each domain below
- captured-at: 2026-05-18
- machine: AVA (macOS 15.5)
- captured-by: inventory-defaults agent
- note: D27 defers firewall + Touch ID sudo. Topic 07 (manager-4.17) decides what here is intentional vs. accidental.

Per D16, this is a raw read snapshot of the standard nix-darwin-touched domains so Topic 07 can decide which values to actually declare. Genuinely huge outputs (device pairings in `NSGlobalDomain`, app inventories in `com.apple.dock`, view-settings trees in `com.apple.finder`, the runtime monitor/window/tile state in `com.apple.spaces`, disabled hotkey bindings in `com.apple.symbolichotkeys`, and a noisy `History` log in `com.apple.universalaccess`) have been trimmed inline with explicit `... TRIMMED ...` markers so signal isn't drowned out.

Skipped per D27:
- `com.apple.alf` (Application Layer Firewall) — Topic 09 firewall is explicitly deferred; no read attempted.
- `/etc/pam.d/sudo*` (PAM stack / Touch ID sudo) — Topic 12 is explicitly deferred; would require root anyway.

## NSGlobalDomain
Maps to `system.defaults.NSGlobalDomain.*`.

```
{
    "646F6E7A_00000000_00000001_6E7A6361_696D6963" = 1;
    AKDeviceUnlockState = 1;
    AKLastCheckInAttemptDate = "2019-10-12 17:28:40 +0000";
    AKLastCheckInSuccessDate = "2019-10-12 17:28:40 +0000";
    AKLastIDMSEnvironment = 0;
    AKLastLocale = "en_US";
    AppleAccentColor = 1;
    AppleActionOnDoubleClick = Minimize;
    AppleAntiAliasingThreshold = 4;
    AppleAquaColorVariant = 1;
    AppleEnableSwipeNavigateWithScrolls = 1;
    AppleHighlightColor = "1.000000 0.874510 0.701961 Orange";
    AppleICUForce24HourTime = 1;
    AppleInterfaceStyle = Dark;
    AppleKeyboardUIMode = 2;
    AppleLanguages =     (
        "en-US",
        en,
        "he-US"
    );
    AppleLanguagesDidMigrate = "12.6";
    AppleLanguagesSchemaVersion = 5400;
    AppleLocale = "en_US";
    AppleMeasurementUnits = Inches;
    AppleMetricUnits = 0;
    AppleMiniaturizeOnDoubleClick = 0;
    AppleShowAllExtensions = 1;
    AppleShowScrollBars = WhenScrolling;
    AppleTemperatureUnit = Celsius;
    AppleWindowTabbingMode = always;
    InitialKeyRepeat = 15;
    "KB_DoubleQuoteOption" = "\\U201cabc\\U201d";
    "KB_SingleQuoteOption" = "\\U2018abc\\U2019";
    "KB_SpellingLanguage" =     {
        "KB_SpellingLanguage" =         (
            en,
            Apple
        );
        "KB_SpellingLanguageIsAutomatic" = 0;
    };
    KeyRepeat = 2;
    NSAllowsBaseWritingDirectionKeyBindings = 0;
    NSAutomaticCapitalizationEnabled = 1;
    NSAutomaticDashSubstitutionEnabled = 0;
    NSAutomaticPeriodSubstitutionEnabled = 1;
    NSAutomaticQuoteSubstitutionEnabled = 0;
    NSAutomaticSpellingCorrectionEnabled = 1;
    NSAutomaticTextCompletionEnabled = 1;
    NSLinguisticDataAssetsRequestLastInterval = 86400;
    NSLinguisticDataAssetsRequestTime = "2026-05-18 11:34:30 +0000";
    NSLinguisticDataAssetsRequested =     (
        en, "en_US", es, nl, fr, nb, da, pt, it, pl, de, tr, he, sv, ar, nn,
        "he_US", mul, "mul_Latn", is, ja, "ja_US"
    );
    NSLinguisticDataAssetsRequestedByChecker =     (
        en, it, fr, sv, da, nl, es, de, ar, nb, nn, pt, he, pl, is, "en_US"
    );
    NSNavPanelFileLastListModeForOpenModeKey = 1;
    NSNavPanelFileListModeForOpenMode2 = 1;
    NSNavPanelSidebarKeyForOpen =     ( );
    NSNavPreviewExpanded = 1;
    NSPersonNameDefaultDisplayNameOrder = 0;
    NSPersonNameDefaultShortNameFormat = 0;
    NSPersonNameDefaultShouldPreferNicknamesPreference = 0;
    NSPreferredSpellServerLanguage = en;
    NSPreferredSpellServerVendors =     { en = Apple; };
    NSPreferredWebServices =     {
        NSWebServicesProviderWebSearch =         {
            NSDefaultDisplayName = DuckDuckGo;
            NSProviderIdentifier = "com.duckduckgo";
        };
    };
    NSQuitAlwaysKeepsWindows = 1;
    NSSpellCheckerAutomaticallyIdentifiesLanguages = 0;
    NSSpellCheckerContainerTransitionComplete = 1;
    NSSpellCheckerDictionaryContainerTransitionComplete = 1;
    NSSpellCheckerInputAnalyticsTime = "2024-10-29 16:00:07 +0000";
    NSTableViewDefaultSizeMode = 2;
    NSUserDictionaryReplacementItems =     (
        { on = 1; replace = jryli;    with = "https://linkedin.com/in/jryio"; },
        { on = 1; replace = jryinbox; with = "jryio@inbox.mailbrew.com"; },
        { on = 1; replace = gibben;   with = Gribben; },
        { on = 1; replace = jrycal;   with = "https://cal.com/jryio"; },
        { on = 1; replace = sian;     with = "Si\\U00e2n"; },
        { on = 1; replace = jryzm;    with = "https://us06web.zoom.us/j/5329331265?pwd=FrxZMBjyeNdAdxVaDbezdujuB3GrGS.1"; },
        { on = 1; replace = omw;      with = "On my way!"; },
        { on = 1; replace = "->";     with = "\\U2192"; },
        { on = 1; replace = jpgl;     with = "\\U304c\\U3093\\U3070\\U3063\\U3066"; },
        { on = 1; replace = jpyw;     with = "\\U3069\\U3046\\U3044\\U305f\\U3057\\U307e\\U3057\\U3066"; },
        { on = 1; replace = "<>";     with = "\\U2194"; },
        { on = 1; replace = "<.";     with = "\\U2190"; },
        { on = 1; replace = ".>";     with = "\\U2192"; },
        { on = 1; replace = ooc;      with = "Only output code"; },
        { on = 1; replace = fromgym;  with = "\\U2b05\\Ufe0f Gym"; },
        { on = 1; replace = jpgn;     with = "\\U304a\\U3084\\U3059\\U307f"; },
        { on = 1; replace = jpty;     with = "\\U3042\\U308a\\U304c\\U3068\\U3046\\U3054\\U3056\\U3044\\U307e\\U3059"; },
        { on = 1; replace = flipgod;  with = "<emoji-laden FLIP GOD chant>"; },
        { on = 1; replace = "j@dvc";  with = "jacob@dvcoders.com"; },
        { on = 1; replace = deshit;   with = "Schei\\U00dfe"; },
        { on = 1; replace = "de-shit"; with = "Schei\\U00dfe"; }
    );
    NSUserQuotesArray =     (
        "\\U201c", "\\U201d", "\\U2018", "\\U2019"
    );
    NavPanelFileListModeForOpenMode = 1;
    PKSecureElementAvailableFlags = 3;
    SyncServicesServerWasActive = 1;
    TISRomanSwitchState = 0;
    WebAutomaticSpellingCorrectionEnabled = 1;
    "_AKBAACertMarkerKey" = { length = 32, bytes = 0x... };
    "_HIHideMenuBar" = 0;
    "com.apple.finder.SyncExtensions" =     {
        collaborationMap = { };
        dirMap = { };
    };
    "com.apple.gms.availability.accessNotGrantedUseCases"           = { length = 42, bytes = ... };
    "com.apple.gms.availability.disabledUseCases"                   = { length = 82, bytes = ... };
    "com.apple.gms.availability.disallowedUseCases"                 = { length = 42, bytes = ... };
    "com.apple.gms.availability.essentialAssetReadiness"            = { length = 5,  bytes = "false" };
    "com.apple.gms.availability.key"                                = { length = 46, bytes = ... };
    "com.apple.gms.availability.useCasesWhoseAssetsAreOutOfStorage" = { length = 42, bytes = ... };
    "com.apple.gms.availability.useCasesWhoseAssetsNotReady"        = { length = 1600, bytes = ... };
    "com.apple.keyboard.fnState" = 0;
    "com.apple.mouse.doubleClickThreshold" = "0.15";
    "com.apple.mouse.linear" = 0;
    "com.apple.mouse.scaling" = "1.5";
    "com.apple.scrollwheel.scaling" = "1.7";
    "com.apple.sound.beep.feedback" = 1;
    "com.apple.sound.beep.flash" = 0;
    "com.apple.sound.beep.sound" = "/System/Library/Sounds/Funk.aiff";
    "com.apple.sound.beep.volume" = 0;
    "com.apple.sound.uiaudio.enabled" = 0;
    "com.apple.springing.delay" = "0.5";
    "com.apple.springing.enabled" = 1;
    "com.apple.swipescrolldirection" = 1;
    "com.apple.trackpad.forceClick" = 1;
    "com.apple.trackpad.scaling" = "0.875";
    "com.logitech.akebono.logTags" = "<long Logitech debug-tag string>";
    "com.logitech.akebono.loggingLevel" = 3;
    "com.logitech.devio.logTags" = "-*";
    shouldShowRSVPDataDetectors = 0;
    userMenuExtraStyle = 2;
}
/* trimmed 84 device-pairing entries (printers, USB devices, etc. — pattern "Vendor Model" = 1;) */
```

## com.apple.dock
Maps to `system.defaults.dock.*`.

```
{
    autohide = 1;
    "expose-group-apps" = 1;
    largesize = 82;
    "last-analytics-stamp" =     ( "800671622.51916" );
    "last-messagetrace-stamp" = "640976633.129187";
    lastShowIndicatorTime = "717012754.915926";
    launchanim = 0;
    loc = "en_US:US";
    magnification = 0;
    mineffect = scale;
    "minimize-to-application" = 1;
    "mod-count" = 2633;
    "persistent-apps" =     ( ... TRIMMED: dock app inventory (per-app GUIDs, bookmarks, labels) ... );
    "persistent-others" =     ( ... TRIMMED: trash/downloads/spacer tiles ... );
    "recent-apps" =     ( ... TRIMMED ... );
    region = US;
    "show-process-indicators" = 1;
    "show-recents" = 0;
    showAppExposeGestureEnabled = 1;
    showMissionControlGestureEnabled = 1;
    tilesize = 52;
    "trash-full" = 1;
    version = 1;
    "wvous-br-corner" = 1;
    "wvous-br-modifier" = 0;
}
```

## com.apple.finder
Maps to `system.defaults.finder.*`.

```
{
    AppleShowAllFiles = TRUE;
    BackupTabState = 0;
    BulkLastFormatter = 0;
    BulkRenameAddNumberTo = 0;
    BulkRenameAddTextText = ".pdf";
    BulkRenameAddTextTo = 0;
    BulkRenameFindText = " ";
    BulkRenameName = "File ";
    BulkRenamePlaceNumberAt = 0;
    BulkRenameReplaceText = "";
    BulkRenameStartIndex = 1;
    ComputerViewSettings =     { ... TRIMMED: view-settings block (column widths, font sizes, sort) ... };
    CopyProgressWindowLocation = "{976, 334}";
    CreateDesktop = FALSE;
    DataSeparatedDisplayNameCache = "";
    DeleteTagProgressWindowLocation = "{330, -1415}";
    DesktopViewSettings =     { ... TRIMMED: view-settings block ... };
    DownloadsFolderListViewSettingsVersion = 1;
    EmptyTrashProgressWindowLocation = "{1239, 761}";
    "FK_AppCentricShowSidebar" = 1;
    "FK_ArrangeBy" = "Date Added";
    FK_DefaultIconViewSettings =     { ... TRIMMED ... };
    FK_DefaultListViewSettings =     { ... TRIMMED ... };
    "FK_SidebarWidth" = 144;
    FK_StandardViewOptions2 =     { ... TRIMMED ... };
    FK_StandardViewSettings =     { ... TRIMMED ... };
    FXArrangeGroupViewBy = Name;
    FXAtLeastOneScreenHasBeenInHIDPI = 1;
    FXConnectToBounds = "{{1570, 1054}, {486, 231}}";
    FXConnectToLastURL = "vnc://aim-0353.apple.ops.archiveintel.com";
    FXDefaultSearchScope = SCcf;
    FXDesktopTouchBarUpgradedToTenTwelveOne = 1;
    FXDesktopVolumePositions =     { ... TRIMMED ... };
    FXICloudDriveDeclinedUpgrade = 0;
    FXICloudDriveDesktop = 0;
    FXICloudDriveDocuments = 0;
    FXICloudDriveEnabled = 1;
    FXICloudDriveFirstSyncDownComplete = 1;
    FXICloudLoggedIn = 1;
    FXInfoPanesExpanded =     { ... TRIMMED ... };
    FXInfoWindowWidth = 400;
    FXLastSearchScope = SCcf;
    FXMyDocumentsArrangeGroupViewBy = "Date Last Opened";
    "FXPreferencesWindow.Location" = "{{792, 667}, {377, 380}}";
    FXPreferredGroupBy = None;
    FXPreferredSearchViewStyle = clmv;
    FXPreferredSearchViewStyleVersion = "%00%00%00%01";
    FXPreferredViewStyle = clmv;
    FXQuickActionsConfigUpgradeLevel = 3;
    FXRecentFolders =     ( ... TRIMMED: recent-history list ... );
    FXSidebarUpgradedSharedSearchToTwelve = 1;
    FXSidebarUpgradedToTenFourteen = 1;
    FXSidebarUpgradedToTenTen = 1;
    FXSyncExtensionToolbarItemsAutomaticallyAdded =     (
        "com.getdropbox.dropbox.garcon",
        "mega.mac.MEGAShellExtFinder",
        "com.synology.SynologyDrive.FinderSync"
    );
    FXSyncExtensionToolbarItemsPendingAdd =     ( );
    FXSyncExtensionToolbarItemsPendingRemove =     (
        "app.cyan.markedit.finder-extension",
        "com.getdropbox.dropbox.garcon"
    );
    FXToolbarUpgradedToTenEight = 1;
    FXToolbarUpgradedToTenNine = 2;
    FXToolbarUpgradedToTenSeven = 1;
    FavoriteTagNames =     ( ... TRIMMED ... );
    FlowViewHeight = 584;
    FontSizeCategory = Custom;
    GoToField = "/Users/CASE/code/professional/tdna/test-sv/src";
    GoToFieldHistory =     ( ... TRIMMED ... );
    ICloudViewSettings =     { ... TRIMMED ... };
    "InspectorWindow.Location" = "{569, 295}";
    LastTrashState = 1;
    MeetingRoomViewSetting =     { ... TRIMMED ... };
    MountProgressWindowLocation = "{1480, 475}";
    MyDocsLibrarySavedViewStyleVersion = "%00%00%00%01";
    MyDocsLibrarySearchViewSettings =     { ... TRIMMED ... };
    NSNavBrowserPreferedColumnContentWidth = 186;
    NSNavLastUserSetHideExtensionButtonState = 0;
    NSNavPanelExpandedSizeForOpenMode = "{784, 1095}";
    NSOSPLastRootDirectory = { length = 588, bytes = ... };
    "NSToolbar Configuration Browser" =     {
        "TB Default Item Identifiers" =         (
            "com.apple.finder.BACK",
            "com.apple.finder.SWCH",
            NSToolbarSpaceItem,
            "com.apple.finder.ARNG",
            "com.apple.finder.SHAR",
            "com.apple.finder.LABL",
            "com.apple.finder.ACTN",
            NSToolbarSpaceItem,
            "com.apple.finder.SRCH"
        );
        "TB Display Mode" = 2;
        "TB Icon Size Mode" = 1;
        "TB Is Shown" = 1;
        "TB Item Identifiers" =         (
            "com.apple.finder.BACK",
            NSToolbarFlexibleSpaceItem,
            "com.apple.finder.SWCH",
            NSToolbarSpaceItem,
            "com.apple.finder.ARNG",
            "com.apple.finder.ACTN",
            NSToolbarSpaceItem,
            "com.apple.finder.SHAR",
            "com.apple.finder.LABL",
            NSToolbarFlexibleSpaceItem,
            NSToolbarFlexibleSpaceItem,
            "mega.mac.MEGAShellExtFinder",
            "com.apple.finder.SRCH"
        );
        "TB Size Mode" = 1;
    };
    "NSTouchBarConfig: ..." =     {
        CurrentItems =         ( );
        DefaultItems =         (
            "com.apple.finder.dfr.kDFRBackForwardButtonIdentifier",
            "com.apple.finder.dfr.kDFRViewOptionsButtonIdentifier",
            NSTouchBarItemIdentifierFlexibleSpace,
            "com.apple.finder.dfr.kDFRQuickLookButtonIdentifier",
            "com.apple.finder.dfr.kDFRShareButtonIdentifier",
            "com.apple.finder.dfr.kDFRAddTagsButtonIdentifier",
            NSTouchBarItemIdentifierFlexibleSpace
        );
    };
    "NSWindow Frame GoToSheet" = "1359 -567 460 180 561 -1329 2056 1285 ";
    "NSWindow Frame NSNavPanelAutosaveName" = "362 95 784 1010 0 0 3360 1865 ";
    "NSWindow Frame SearchAttributeSheet" = "921 616 643 415 0 0 1920 1178 ";
    NetworkViewSettings =     { ... TRIMMED ... };
    NewWindowTarget = PfHm;
    NewWindowTargetPath = "file:///Users/case/";
    "PreferencesWindow.LastSelection" = ADVD;
    PreviewPaneGalleryWidth = 250;
    PreviewPaneInfoExpanded = 1;
    PreviewPaneWidth = 250;
    RecentMoveAndCopyDestinations =     ( ... TRIMMED ... );
    RecentsArrangeGroupViewBy = "Date Last Opened";
    SGTRecentFileSearches =     ( ... TRIMMED ... );
    SearchRecentsSavedViewStyle = clmv;
    SearchRecentsSavedViewStyleVersion = "%00%00%00%01";
    SearchRecentsViewSettings =     { ... TRIMMED ... };
    SearchViewSettings =     { ... TRIMMED ... };
    ShowExternalHardDrivesOnDesktop = 0;
    ShowHardDrivesOnDesktop = 0;
    ShowMountedServersOnDesktop = 0;
    ShowPathbar = 1;
    ShowPreviewPane = 0;
    ShowRecentTags = 0;
    ShowRemovableMediaOnDesktop = 0;
    ShowSidebar = 1;
    ShowStatusBar = 0;
    ShowTabView = 0;
    SidebarDevicesSectionDisclosedState = 1;
    SidebarMediaBrowserSectionDisclosedState = 1;
    SidebarPlacesSectionDisclosedState = 1;
    SidebarSharedSectionDisclosedState = 0;
    SidebarShowingSignedIntoiCloud = 1;
    SidebarShowingiCloudDesktop = 0;
    SidebarTagsSctionDisclosedState = 1;
    SidebarWidth = 144;
    SidebariCloudDriveSectionDisclosedState = 1;
    SlicesRootAttributes =     (
        kMDItemDisplayName,
        "com_omnigroup_OmniFocus_ContainingFolderNames",
        kMDItemLastUsedDate,
        kMDItemTextContent,
        kMDItemContentCreationDate,
        kMDItemContentModificationDate,
        kMDItemKind,
        "com_apple_FileExtensionAttribute"
    );
    SmartSharedSearchViewSettings =     { ... TRIMMED ... };
    StandardViewOptions =     { ... TRIMMED ... };
    StandardViewSettings =     { ... TRIMMED ... };
    TagsCloudSerialNumber = 27;
    TagsColumnWidth = 190;
    TrashViewSettings =     { ... TRIMMED ... };
    "ViewOptionsWindow.Location" = "{735, 658}";
    ViewSettingsDictionary =     { ... TRIMMED ... };
    "_FXSortFoldersFirst" = 1;
    iCloudProgressWindowLocation = "{1304, 426}";
}
```

## com.apple.controlcenter
Maps to `system.defaults.controlcenter.*`. Mostly menu-bar status-item positions/visibility.

```
{
    "LastHeartbeatDateString.daily" = "2026-05-18T11:33:12Z";
    "NSStatusItem Preferred Position AudioVideoModule" = 910;
    "NSStatusItem Preferred Position Battery" = 333;
    "NSStatusItem Preferred Position BentoBox" = 135;
    "NSStatusItem Preferred Position Bluetooth" = 183;
    "NSStatusItem Preferred Position Clock" = 80;
    "NSStatusItem Preferred Position Display" = 11097;
    "NSStatusItem Preferred Position FaceTime" = 1366;
    "NSStatusItem Preferred Position FocusModes" = 161;
    "NSStatusItem Preferred Position NowPlaying" = 11403;
    "NSStatusItem Preferred Position ScreenMirroring" = 6195;
    "NSStatusItem Preferred Position Shortcuts" = 11547;
    "NSStatusItem Preferred Position Sound" = 276;
    "NSStatusItem Preferred Position UserSwitcher" = 11480;
    "NSStatusItem Preferred Position WiFi" = 217;
    "NSStatusItem Visible AudioVideoModule" = 0;
    "NSStatusItem Visible Battery" = 0;
    "NSStatusItem Visible BentoBox" = 1;
    "NSStatusItem Visible Bluetooth" = 1;
    "NSStatusItem Visible Clock" = 1;
    "NSStatusItem Visible Display" = 1;
    "NSStatusItem Visible DoNotDisturb" = 0;
    "NSStatusItem Visible FaceTime" = 0;
    "NSStatusItem Visible FocusModes" = 1;
    "NSStatusItem Visible Item-0" = 0;
    "NSStatusItem Visible Item-1" = 0;
    "NSStatusItem Visible Item-10" = 0;
    "NSStatusItem Visible Item-11" = 0;
    "NSStatusItem Visible Item-2" = 0;
    "NSStatusItem Visible Item-3" = 0;
    "NSStatusItem Visible Item-4" = 0;
    "NSStatusItem Visible Item-5" = 0;
    "NSStatusItem Visible Item-6" = 0;
    "NSStatusItem Visible Item-7" = 0;
    "NSStatusItem Visible Item-8" = 0;
    "NSStatusItem Visible Item-9" = 0;
    "NSStatusItem Visible NowPlaying" = 1;
    "NSStatusItem Visible ScreenMirroring" = 0;
    "NSStatusItem Visible Shortcuts" = 1;
    "NSStatusItem Visible Sound" = 1;
    "NSStatusItem Visible UserSwitcher" = 1;
    "NSStatusItem Visible WiFi" = 1;
    missionControlTooltipCount = 3;
}
```

## com.apple.menuextra.clock
Maps to `system.defaults.menuExtraClock.*`.

```
{
    FlashDateSeparators = 0;
    IsAnalog = 0;
    Show24Hour = 1;
    ShowDate = 1;
    ShowDayOfWeek = 1;
}
```

## com.apple.universalaccess
Maps to `system.defaults.universalaccess.*`.

```
{
    AssistiveControlType = 2;
    FontSizeCategory =     {
        "com.apple.MobileSMS" = L;
        "com.apple.Notes" = UseGlobal;
        "com.apple.finder" = Custom;
        "com.apple.iBooksX" = UseGlobal;
        "com.apple.iCal" = UseGlobal;
        "com.apple.mail" = UseGlobal;
        "com.apple.news" = UseGlobal;
        "com.apple.stocks" = UseGlobal;
        "com.apple.weather" = UseGlobal;
        global = DEFAULT;
        version = "3.0";
    };
    History =     ( ... TRIMMED: noisy event log (MouseKeys reset events), not policy-relevant ... );
    customFonts = 1;
    displaysLastCursorLocation =     {
        0 =         { X = "2974.91796875"; Y = 1800; };
        1 =         { X = 1900; Y = 1324; };
        4 =         { X = "1361.859375"; Y = "1541.69921875"; };
    };
    dwellEnabled = 0;
    dwellHideUIEnabled = 1;
    dwellHideUITimeout = 30;
    flashScreen = 0;
    grayscale = 0;
    hoverTextEnabled = 0;
    hoverTypingEnabled = 0;
    hudNotifiedConstrast = 0;
    increaseContrast = 0;
    keyboardAccessFocusRingTimeout = 15;
    login = 0;
    reduceMotion = 0;
    reduceTransparency = 0;
    selectedTab = 13;
    sessionChange = 0;
    slowKey = 0;
    slowKeyDelay = 250;
    speakItemUnderMouseAfterDelayMode = 0;
    spokenContentPreferredVoiceForLanguage =     { en = "com.apple.ttsbundle.gryphon-neural_Nora_en-US_premium"; };
    spokenContentSpeakingRateForVoice =     { "com.apple.voice.compact.en-US.Samantha" = 175; };
    spokenContentSpeakingVolumeForVoice =     { "com.apple.voice.compact.en-US.Samantha" = 1; };
    stickyKey = 0;
    switchAutoScanElementInterval = "0.5";
    switchAutoScanPanelInterval = "0.5";
    switchCoalescePressesDuration = 0;
    switchFirstElementDelay = 0;
    switchHideUITimeout = 15;
    switchHoldBeforeRepeatDuration = 3;
    switchMinimumPressDuration = 0;
    switchOnOffKey = 0;
    switchSweepingCursorSpeed = 5;
    useStickyKeysShortcutKeys = 0;
    virtualKeyboardOnOff = 0;
    voiceOverOnOffKey = 0;
    whiteOnBlack = 0;
}
```

## com.apple.screencapture
Maps to `system.defaults.screencapture.*`.

```
{
    "last-analytics-stamp" = "800747641.031682";
    "last-messagetrace-stamp" = "606553772.276417";
    "last-selection" =     {
        Height = 1445;
        Width = 1104;
        X = 393;
        Y = 143;
    };
    "last-selection-display" = 0;
    location = "/Users/CASE/Dropbox/media/screenshots";
    "show-thumbnail" = 0;
    style = display;
    video = 1;
}
```

## com.apple.HIToolbox
Input source / keyboard. nix-darwin support is limited (no first-class module for input sources); Topic 07 will likely keep this out of declarative scope.

```
{
    AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.US";
    AppleDictationAutoEnable = 1;
    AppleEnabledInputSources =     (
                {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = 0;
            "KeyboardLayout Name" = "U.S.";
        },
                {
            "Bundle ID" = "com.apple.PressAndHold";
            InputSourceKind = "Non Keyboard Input Method";
        },
                {
            "Bundle ID" = "com.apple.CharacterPaletteIM";
            InputSourceKind = "Non Keyboard Input Method";
        },
                {
            "Bundle ID" = "com.apple.inputmethod.ironwood";
            InputSourceKind = "Non Keyboard Input Method";
        },
                {
            "Bundle ID" = "com.apple.50onPaletteIM";
            InputSourceKind = "Non Keyboard Input Method";
        },
                {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = "-18432";
            "KeyboardLayout Name" = Hebrew;
        }
    );
    AppleFnUsageType = 0;
    AppleInputSourceHistory =     (
                { InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 0; "KeyboardLayout Name" = "U.S."; },
                { InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = "-18432"; "KeyboardLayout Name" = Hebrew; }
    );
    AppleInputSourceUpdateTime = "2026-05-19 03:03:20 +0000";
    AppleSelectedInputSources =     (
                { "Bundle ID" = "com.apple.PressAndHold"; InputSourceKind = "Non Keyboard Input Method"; },
                { InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 0; "KeyboardLayout Name" = "U.S."; }
    );
}
```

## com.apple.symbolichotkeys
Keyboard shortcuts. Trimmed to enabled bindings only (26 explicitly-disabled bindings omitted). The full record is the `AppleSymbolicHotKeys` dict where each numeric key is a Carbon hotkey ID; `params` is `[char-code, virtual-keycode, modifier-mask]`. See Apple's hotkey-id table for human meanings.

```
{
    AppleSymbolicHotKeys (enabled bindings only; format: id params=[param1,param2,modifier-mask]) =
        id=7    params=[65535,120,8650752]
        id=8    params=[65535,99,8650752]
        id=9    params=[65535,118,8650752]
        id=10   params=[65535,96,8650752]
        id=11   params=[65535,97,8650752]
        id=12   params=[65535,122,8650752]
        id=13   params=[65535,98,8650752]
        id=27   params=[96,50,1048576]
        id=32   params=[65535,126,8650752]
        id=33   params=[65535,125,8650752]
        id=34   params=[65535,126,8781824]
        id=35   params=[65535,125,8781824]
        id=36   params=[65535,103,8388608]
        id=37   params=[65535,103,8519680]
        id=51   params=[39,50,1572864]
        id=53   params=[65535,107,8388608]
        id=54   params=[65535,113,8388608]
        id=55   params=[65535,107,8912896]
        id=56   params=[65535,113,8912896]
        id=57   params=[65535,100,8650752]
        id=59   params=[65535,96,9437184]
        id=60   params=[32,49,262144]
        id=61   params=[32,49,786432]
        id=62   params=[65535,111,8388608]
        id=63   params=[65535,111,8519680]
        id=79   params=[65535,123,8650752]
        id=80   params=[65535,123,8781824]
        id=81   params=[65535,124,8650752]
        id=82   params=[65535,124,8781824]
        id=98   params=[47,44,1179648]
        id=162  params=[65535,96,9961472]
        id=175  params=[65535,65535,0]
        id=176  params=[32,49,8388608]
        id=181  params=[54,22,1179648]
        id=182  params=[54,22,1441792]
        id=190  params=[113,12,8388608]
    /* 26 disabled bindings omitted (enabled=0) */
}
```

## com.apple.spaces
Mission Control / Spaces. The bulk of this domain (`SpacesDisplayConfiguration`) is runtime monitor/window/tile state, not declarable policy. The only policy-shaped key is `app-bindings` (per-app space pinning).

```
{
    SpacesDisplayConfiguration =     { ... TRIMMED: runtime monitor/window/tile state (per-display Spaces, window IDs, tile layouts). Not declarable policy. ... };
    "app-bindings" =     {
        "com.apple.finder" = AllSpaces;
        "com.apple.ichat" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "com.apple.itunes" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "com.cloudmagic.macmail" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "com.culturedcode.thingsmac" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "com.happenapps.quiver" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "com.nylas.nylas-mail" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "com.spotify.client" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "com.tinyspeck.slackmacgap" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "com.todoist.mac.todoist" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "keybase.electron" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
        "org.mozilla.firefox" = "3BB0EA7D-E6B2-4108-9A18-70CEA242D8F3";
    };
}
```

Note: most of the bundle IDs in `app-bindings` are for apps that are no longer installed (Things, Quiver, Cloudmagic Mail, Nylas, Todoist, Keybase). Drift from old configuration.

## com.apple.SoftwareUpdate
Maps to `system.defaults.SoftwareUpdate.*`.

```
{
    AutoUpdateMajorOSVersion = 15;
    AutoUpdateRetryCount =     {
        "061-18879" = 7;
        "071-10831" = 7;
        "EXTERNAL_UPDATE_Apple Studio Display" = 7;
        "MSU_UPDATE_23E224_patch_14.4.1_minor" = 7;
        "MSU_UPDATE_23F79_patch_14.5_minor" = 7;
        "MSU_UPDATE_24B2091_patch_15.1.1_minor" = 7;
    };
    AvailableUpdatesNotificationCountKey = 2;
    AvailableUpdatesNotificationProductKey = "MSU_UPDATE_25D125_patch_26.3_major";
    UserNotificationDate = "2026-03-23 13:26:40 +0000";
}
```

## com.apple.LaunchServices
The user-domain `com.apple.LaunchServices` returns `Domain ... does not exist`. The actual handler map lives under `com.apple.LaunchServices/com.apple.launchservices.secure`. Flattened to `KIND  scheme/uti -> bundle-id  [role]` for readability. nix-darwin has no first-class file-handler module; Topic 07 likely leaves this out of scope.

Raw error for `com.apple.LaunchServices`:
```
2026-05-18 23:24:23.026 defaults[46453:4651934]
Domain com.apple.LaunchServices does not exist
```

Flattened content of `com.apple.LaunchServices/com.apple.launchservices.secure`:
```
    URL  airtable                                   -> com.formagrid.airtable  [all]
    URL  alfred                                     -> com.runningwithcrayons.alfred  [all]
    URL  anythingllm                                -> com.anythingllm  [all]
    URL  anytype                                    -> com.anytype.anytype  [all]
    URL  apple-reference-documentation              -> com.apple.dt.xcode  [all]
    URL  claude                                     -> com.anthropic.claudefordesktop  [all]
    URL  clay-app                                   -> com.clay.mac  [all]
    URL  cleanshot                                  -> pl.maketheweb.cleanshotx  [all]
    URL  codex                                      -> com.openai.codex  [all]
    URL  com.logitech.logioptionsplus               -> com.logi.cp-dev-mgr  [all]
    URL  cron                                       -> com.cron.electron  [all]
    URL  doc                                        -> com.apple.dt.xcode  [all]
    URL  docker-desktop                             -> com.docker.docker  [all]
    URL  dropbox-paper                              -> com.dropbox.paper  [all]
    URL  faraday                                    -> com.ahoylabs.faraday  [all]
    URL  figma                                      -> com.figma.desktop  [all]
    URL  gamecenter                                 -> com.apple.gamecenter.gamecenteruiservice  [all]
    URL  gather                                     -> com.gather.gather  [all]
    URL  git                                        -> com.apple.dt.xcode  [all]
    URL  git+ssh                                    -> com.apple.dt.xcode  [all]
    URL  github-mac                                 -> com.github.githubclient  [all]
    URL  gitify                                     -> com.electron.gitify  [all]
    URL  http                                       -> com.choosyosx.choosy  [all]
    URL  https                                      -> com.choosyosx.choosy  [all]
    URL  insomnia                                   -> com.insomnia.app  [all]
    URL  itms-gc                                    -> com.apple.gamecenter.gamecenteruiservice  [all]
    URL  itms-gcs                                   -> com.apple.gamecenter.gamecenteruiservice  [all]
    URL  keybase                                    -> keybase.electron  [all]
    URL  lens                                       -> com.electron.kontena-lens  [all]
    URL  linear                                     -> com.linear  [all]
    URL  lmstudio                                   -> ai.elementlabs.lmstudio  [all]
    URL  mailspring                                 -> com.mailspring.mailspring  [all]
    URL  mailto                                     -> com.hey.app.desktop  [all]
    URL  mesh                                       -> com.clay.mac  [all]
    URL  mochi                                      -> com.msteedman.mochi  [all]
    URL  neatapp                                    -> com.electron.neat  [all]
    URL  notion                                     -> notion.id  [all]
    URL  nylas                                      -> com.nylas.nylas-mail  [all]
    URL  openvpn                                    -> org.openvpn.client.app  [all]
    URL  openvpn-connect                            -> org.openvpn.client.app  [all]
    URL  pdfexpert                                  -> com.readdle.pdfexpert-mac  [all]
    URL  pie                                        -> io.httpie.desktop  [all]
    URL  postman                                    -> com.postmanlabs.mac  [all]
    URL  sgnl                                       -> org.whispersystems.signal-desktop  [all]
    URL  signalcaptcha                              -> org.whispersystems.signal-desktop  [all]
    URL  steam                                      -> com.valvesoftware.steam  [all]
    URL  steambeta                                  -> com.valvesoftware.steam  [all]
    URL  steamlink                                  -> com.valvesoftware.steam  [all]
    URL  svn                                        -> com.apple.dt.xcode  [all]
    URL  svn+ssh                                    -> com.apple.dt.xcode  [all]
    URL  web+stellar                                -> keybase.electron  [all]
    URL  x-choosy                                   -> com.choosyosx.choosy  [all]
    URL  x-choosy-reg                               -> com.choosyosx.choosy  [all]
    URL  x-github-client                            -> com.github.githubclient  [all]
    URL  x-github-desktop-auth                      -> com.github.githubclient  [all]
    URL  x-postbox-message                          -> com.postbox-inc.postbox  [all]
    URL  x-source-tag                               -> com.apple.dt.xcode  [all]
    URL  x-swift-package-repository-authentication  -> com.apple.dt.xcode  [all]
    URL  x-xcode-ci-build-report-feedback           -> com.apple.dt.xcode  [all]
    URL  x-xcode-documentation                      -> com.apple.dt.xcode  [all]
    URL  xcarchive                                  -> com.apple.dt.xcode  [all]
    URL  xcbot                                      -> com.apple.dt.xcode  [all]
    URL  xcdevice                                   -> com.apple.dt.xcode  [all]
    URL  xcdoc                                      -> com.apple.dt.xcode  [all]
    URL  xcode                                      -> com.apple.dt.xcode  [all]
    URL  xcode-ci                                   -> com.apple.dt.xcode  [all]
    URL  xcode-ci-handler                           -> com.apple.dt.xcode  [all]
    URL  xcpref                                     -> com.apple.dt.xcode  [all]
    URL  zed                                        -> dev.zed.zed  [all]
    URL  zoomcontactcentercall                      -> us.zoom.xos  [all]
    URL  zoomphonecall                              -> us.zoom.xos  [all]
    URL  zoomphonesms                               -> us.zoom.xos  [all]
    UTI  com.apple.default-app.mail-client          -> com.hey.app.desktop  [all]
    UTI  com.apple.default-app.web-browser          -> com.choosyosx.choosy  [all]
    UTI  com.apple.documentation.doccarchive        -> com.kapeli.dashdoc  [all]
    UTI  com.apple.dt.document.gpx                  -> com.sublimetext.3  [all]
    UTI  com.apple.ical.backup-package              -> com.apple.ical  [all]
    UTI  com.apple.m4v-video                        -> com.colliderli.iina  [all]
    UTI  com.apple.xcode.docset                     -> com.kapeli.dashdoc  [all]
    UTI  com.fuji.raw-image                         -> com.apple.preview  [all]
    UTI  com.runningwithcrayons.alfred.appearance   -> com.runningwithcrayons.alfred  [editor]
    UTI  com.runningwithcrayons.alfred.preferences  -> com.runningwithcrayons.alfred  [editor]
    UTI  com.runningwithcrayons.alfred.snippets     -> com.runningwithcrayons.alfred  [editor]
    UTI  com.runningwithcrayons.alfred.workflow     -> com.runningwithcrayons.alfred  [editor]
    UTI  com.unknown.md                             -> com.uranusjr.macdown  [all]
    UTI  net.daringfireball.markdown                -> com.uranusjr.macdown  [all]
    UTI  org.videolan.mkv                           -> com.colliderli.iina  [all]
    UTI  org.videolan.webm                          -> com.colliderli.iina  [all]
    UTI  public.comma-separated-values-text         -> com.microsoft.excel  [all]
    UTI  public.html                                -> com.choosyosx.choosy  [all]
    UTI  public.json                                -> com.sublimetext.4  [all]
    UTI  public.mpeg-4                              -> com.colliderli.iina  [all]
    UTI  public.plain-text                          -> com.sublimetext.4  [all]
    UTI  public.python-script                       -> com.sublimetext.4  [all]
    UTI  public.svg-image                           -> org.mozilla.firefox  [all]
    UTI  public.unix-executable                     -> com.mitchellh.ghostty  [all]
    UTI  public.url                                 -> com.google.chrome  [viewer]
    UTI  public.xhtml                               -> com.letsgo.handler  [all]
    UTI  public.yaml                                -> com.sublimetext.4  [all]

    /* 99 handler bindings (URL schemes + content types) */
```

## com.apple.TextEdit
Editor defaults. No first-class nix-darwin module; small surface.

```
{
    NSDocumentSuppressTempVersionStoreWarning = 1;
    NSNavPanelExpandedSizeForOpenMode = "{799, 448}";
    NSOSPLastRootDirectory = { length = 900, bytes = ... };
    "NSWindow Frame NSNavPanelAutosaveName" = "1200 995 799 388 0 0 3200 1775 ";
}
```

## com.apple.commerce
App Store auto-update. nix-darwin exposes a small subset (e.g. `AutoUpdate`); the rest is timestamps/state.

```
{
    AppUpdatesToInstallLater =     ( );
    AutoUpdateStartedTimestamp = "2019-10-12 19:47:13 +0000";
    AvailableUpdatesAtLastNotification =     ( "061-21549" );
    ISLastUpdatesQueueCheck = "2019-10-12 19:47:13 +0000";
    LastAutoUpdateInvocation = "2019-10-12 19:47:09 +0000";
    LastUpdateNotificationOSMajorVersion = "10.14";
    NextClientIDPingDate = "2017-09-28 02:26:51 +0000";
    PurchaseByTouchID = 1;
    PurchaseByTouchIDEnabledDate = "2019-03-30 23:00:18 +0000";
    PurchasesInflight = 0;
    UserNotificationDate = "2019-10-05 05:05:00 +0000";
}
```

The 2017-2019 timestamps suggest commerce auto-update activity has been quiet since macOS 10.14 — likely no longer actively used.

## Notes for Topic 07

These look obviously intentional based on the values themselves (non-default settings, clearly opinionated). Topic 07 / `manager-4.17` will confirm.

1. **`NSGlobalDomain.AppleInterfaceStyle = Dark`** — Dark mode is on. Standard `system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark"`.
2. **`NSGlobalDomain.AppleICUForce24HourTime = 1` + `com.apple.menuextra.clock.Show24Hour = 1`** — explicit 24-hour clock everywhere.
3. **`NSGlobalDomain.AppleShowAllExtensions = 1`** — show all file extensions in Finder (paired with `com.apple.finder.AppleShowAllFiles = TRUE`, which surfaces dotfiles too — both clearly deliberate developer settings).
4. **`NSGlobalDomain.InitialKeyRepeat = 15` + `KeyRepeat = 2`** — fast keyboard repeat, well below macOS defaults (typical defaults are 25/6). Standard "I am a power user" tweak.
5. **`NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = 0` + `NSAutomaticDashSubstitutionEnabled = 0`** — smart quotes and em-dash substitution off (desirable for code/Markdown writing). Note the contrast: spelling correction and capitalization remain on.
6. **`com.apple.dock.autohide = 1` + `tilesize = 52` + `mineffect = scale` + `launchanim = 0` + `show-recents = 0`** — a tight, opinionated dock: auto-hide, no bouncing launch animation, no recents tray, small tiles, scale (not genie) minimize.
7. **`com.apple.dock.wvous-br-corner = 1`** — bottom-right hot corner explicitly disabled (`1` = no-op). Likely intentional to prevent accidental triggers.
8. **`com.apple.finder.CreateDesktop = FALSE` + `ShowHardDrivesOnDesktop = 0` + `ShowExternalHardDrivesOnDesktop = 0` + `ShowMountedServersOnDesktop = 0` + `ShowRemovableMediaOnDesktop = 0`** — clean desktop policy: no desktop icons at all.
9. **`com.apple.finder.NewWindowTarget = PfHm` + `NewWindowTargetPath = file:///Users/case/`** — new Finder windows open at `$HOME`, not the default "Recents".
10. **`com.apple.finder._FXSortFoldersFirst = 1` + `FXPreferredViewStyle = clmv`** — folders sorted first; column view as default.
11. **`com.apple.screencapture.location = /Users/CASE/Dropbox/media/screenshots` + `show-thumbnail = 0` + `style = display` + `video = 1`** — screenshots redirected into Dropbox, thumbnail preview off (uncommon, opinionated). The `style = display` and `video = 1` keys imply the last-used capture mode persisted there.
12. **`com.apple.menuextra.clock.ShowDate = 1` + `ShowDayOfWeek = 1`** — both date and day-of-week visible in the menu bar clock (non-default in compact bars).
13. **`com.apple.SoftwareUpdate.AutoUpdateMajorOSVersion = 15`** — auto-update pinned to macOS 15.x major, not chasing 26.x. Defers OS upgrades deliberately.

Caveats Topic 07 should weigh:
- `NSGlobalDomain.NSUserDictionaryReplacementItems` (21 entries) is a personal text-expansion shortcut list (`omw` -> "On my way!", multiple `jpgl`/`jpyw` Japanese phrases, etc.). Declarative-or-not is a judgment call: useful but personal, and managing 21 entries by hand in Nix is high-friction.
- The dock's `persistent-apps` list is large and changes when the user reorders the dock. Topic 07 may want to defer dock contents to a runtime asset rather than declarative state.
- `com.apple.spaces.app-bindings` references several long-uninstalled apps (Things, Quiver, Cloudmagic Mail, Nylas, Todoist, Keybase). Drift candidate — likely accidental residue, not intentional config.
- `NSGlobalDomain.com.apple.mouse.scaling = 1.5` and `com.apple.trackpad.scaling = 0.875` look intentional (custom pointer speeds) but are also things macOS rewrites when devices change.
