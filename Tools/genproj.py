import hashlib, os, sys

ROOT = "/Users/ramaaa/Documents/Projects/BackUpData/parkir-meter"
PROJ = "Zetrum"
APP_TARGET = "Zetrum"
WID_TARGET = "ZetrumWidget"
APP_ID = "co.id.trikala.zetrum"
WID_ID = APP_ID + ".widget"
DEPLOY = "17.0"

_seen = {}
def uid(key):
    h = hashlib.md5(key.encode()).hexdigest()[:24].upper()
    assert _seen.setdefault(h, key) == key, "uuid collision"
    return h

def swifts(d):
    p = os.path.join(ROOT, d)
    return sorted(f for f in os.listdir(p) if f.endswith(".swift"))

app_root   = swifts("Zetrum")
app_views  = swifts("Zetrum/Views")
app_comps  = swifts("Zetrum/Components")
shared     = swifts("Shared")
wid_root   = swifts("ZetrumWidget")

# (group-relative path, logical group dir)
app_files = [("Zetrum/" + f, f) for f in app_root]
view_files = [("Zetrum/Views/" + f, f) for f in app_views]
comp_files = [("Zetrum/Components/" + f, f) for f in app_comps]
shared_files = [("Shared/" + f, f) for f in shared]
wid_files = [("ZetrumWidget/" + f, f) for f in wid_root]

ASSET_APP = "Zetrum/Assets.xcassets"
ASSET_WID = "ZetrumWidget/Assets.xcassets"

WID_PLIST = "ZetrumWidget/Info.plist"
all_refs = app_files + view_files + comp_files + shared_files + wid_files + \
           [(ASSET_APP, "Assets.xcassets"), (ASSET_WID, "Assets.xcassets"),
            (WID_PLIST, "Info.plist")]

def fref(path): return uid("fileref:" + path)
def bf(path, target): return uid("buildfile:%s:%s" % (target, path))

out = []
w = out.append

w("// !$*UTF8*$!")
w("{")
w("\tarchiveVersion = 1;")
w("\tclasses = {")
w("\t};")
w("\tobjectVersion = 56;")
w("\tobjects = {")

# ---------- PBXBuildFile ----------
w("\n/* Begin PBXBuildFile section */")
def emit_bf(path, name, target, comment="Sources"):
    w("\t\t%s /* %s in %s */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };"
      % (bf(path, target), name, comment, fref(path), name))

for p, n in app_files + view_files + comp_files + shared_files:
    emit_bf(p, n, APP_TARGET)
for p, n in shared_files + wid_files:
    emit_bf(p, n, WID_TARGET)
emit_bf(ASSET_APP, "Assets.xcassets", APP_TARGET, "Resources")
emit_bf(ASSET_WID, "Assets.xcassets", WID_TARGET, "Resources")
# widget appex embedded into app
w("\t\t%s /* %s.appex in Embed Foundation Extensions */ = {isa = PBXBuildFile; fileRef = %s /* %s.appex */; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; };"
  % (uid("embed-appex"), WID_TARGET, uid("product:widget"), WID_TARGET))
w("/* End PBXBuildFile section */")

# ---------- PBXContainerItemProxy ----------
w("\n/* Begin PBXContainerItemProxy section */")
w("""\t\t%s /* PBXContainerItemProxy */ = {
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = %s /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = %s;
\t\t\tremoteInfo = %s;
\t\t};""" % (uid("proxy:widget"), uid("project"), uid("target:widget"), WID_TARGET))
w("/* End PBXContainerItemProxy section */")

# ---------- PBXCopyFilesBuildPhase ----------
w("\n/* Begin PBXCopyFilesBuildPhase section */")
w("""\t\t%s /* Embed Foundation Extensions */ = {
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\t%s /* %s.appex in Embed Foundation Extensions */,
\t\t\t);
\t\t\tname = "Embed Foundation Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};""" % (uid("phase:embed"), uid("embed-appex"), WID_TARGET))
w("/* End PBXCopyFilesBuildPhase section */")

# ---------- PBXFileReference ----------
w("\n/* Begin PBXFileReference section */")
for p, n in all_refs:
    t = ("folder.assetcatalog" if n.endswith(".xcassets")
         else "text.plist.xml" if n.endswith(".plist") else "sourcecode.swift")
    w('\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = %s; path = %s; sourceTree = "<group>"; };'
      % (fref(p), n, t, n))
w('\t\t%s /* %s.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = %s.app; sourceTree = BUILT_PRODUCTS_DIR; };'
  % (uid("product:app"), APP_TARGET, APP_TARGET))
w('\t\t%s /* %s.appex */ = {isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = %s.appex; sourceTree = BUILT_PRODUCTS_DIR; };'
  % (uid("product:widget"), WID_TARGET, WID_TARGET))
w("/* End PBXFileReference section */")

# ---------- PBXFrameworksBuildPhase ----------
w("\n/* Begin PBXFrameworksBuildPhase section */")
for key, name in [("phase:fw:app", APP_TARGET), ("phase:fw:widget", WID_TARGET)]:
    w("""\t\t%s /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};""" % uid(key))
w("/* End PBXFrameworksBuildPhase section */")

# ---------- PBXGroup ----------
def group(key, name, children, path=None):
    lines = ["\t\t%s /* %s */ = {" % (uid(key), name),
             "\t\t\tisa = PBXGroup;",
             "\t\t\tchildren = («CHILDREN»"]
    kids = "".join("\n\t\t\t\t%s /* %s */," % (c_uid, c_name) for c_uid, c_name in children)
    body = "\n".join(lines).replace("(«CHILDREN»", "(" + kids + "\n\t\t\t)" if kids else "(\n\t\t\t)")
    body += ";\n"
    if path:
        body += "\t\t\tpath = %s;\n" % path
    elif name:
        body += "\t\t\tname = %s;\n" % name
    body += '\t\t\tsourceTree = "<group>";\n\t\t};'
    w(body)

w("\n/* Begin PBXGroup section */")
group("group:views", "Views", [(fref(p), n) for p, n in view_files], path="Views")
group("group:components", "Components", [(fref(p), n) for p, n in comp_files], path="Components")
group("group:app", APP_TARGET,
      [(fref(p), n) for p, n in app_files] +
      [(uid("group:components"), "Components"), (uid("group:views"), "Views"),
       (fref(ASSET_APP), "Assets.xcassets")],
      path=APP_TARGET)
group("group:widget", WID_TARGET,
      [(fref(p), n) for p, n in wid_files] +
      [(fref(ASSET_WID), "Assets.xcassets"), (fref(WID_PLIST), "Info.plist")],
      path=WID_TARGET)
group("group:shared", "Shared", [(fref(p), n) for p, n in shared_files], path="Shared")
group("group:products", "Products",
      [(uid("product:app"), APP_TARGET + ".app"), (uid("product:widget"), WID_TARGET + ".appex")])
group("group:root", "", [(uid("group:app"), APP_TARGET),
                          (uid("group:widget"), WID_TARGET),
                          (uid("group:shared"), "Shared"),
                          (uid("group:products"), "Products")])
w("/* End PBXGroup section */")

# ---------- PBXNativeTarget ----------
w("\n/* Begin PBXNativeTarget section */")
w("""\t\t%s /* %s */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget "%s" */;
\t\t\tbuildPhases = (
\t\t\t\t%s /* Sources */,
\t\t\t\t%s /* Frameworks */,
\t\t\t\t%s /* Resources */,
\t\t\t\t%s /* Embed Foundation Extensions */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t%s /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = %s;
\t\t\tproductName = %s;
\t\t\tproductReference = %s /* %s.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t};""" % (uid("target:app"), APP_TARGET, uid("conflist:app"), APP_TARGET,
             uid("phase:src:app"), uid("phase:fw:app"), uid("phase:res:app"), uid("phase:embed"),
             uid("dep:widget"), APP_TARGET, APP_TARGET, uid("product:app"), APP_TARGET))
w("""\t\t%s /* %s */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget "%s" */;
\t\t\tbuildPhases = (
\t\t\t\t%s /* Sources */,
\t\t\t\t%s /* Frameworks */,
\t\t\t\t%s /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = %s;
\t\t\tproductName = %s;
\t\t\tproductReference = %s /* %s.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t};""" % (uid("target:widget"), WID_TARGET, uid("conflist:widget"), WID_TARGET,
             uid("phase:src:widget"), uid("phase:fw:widget"), uid("phase:res:widget"),
             WID_TARGET, WID_TARGET, uid("product:widget"), WID_TARGET))
w("/* End PBXNativeTarget section */")

# ---------- PBXProject ----------
w("\n/* Begin PBXProject section */")
w("""\t\t%s /* Project object */ = {
\t\t\tisa = PBXProject;
\t\t\tattributes = {
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {
\t\t\t\t\t%s = {
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t};
\t\t\t\t\t%s = {
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t};
\t\t\t\t};
\t\t\t};
\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXProject "%s" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = %s;
\t\t\tproductRefGroup = %s /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t%s /* %s */,
\t\t\t\t%s /* %s */,
\t\t\t);
\t\t};""" % (uid("project"), uid("target:app"), uid("target:widget"),
             uid("conflist:project"), PROJ, uid("group:root"), uid("group:products"),
             uid("target:app"), APP_TARGET, uid("target:widget"), WID_TARGET))
w("/* End PBXProject section */")

# ---------- PBXResourcesBuildPhase ----------
w("\n/* Begin PBXResourcesBuildPhase section */")
for key, asset, target in [("phase:res:app", ASSET_APP, APP_TARGET),
                           ("phase:res:widget", ASSET_WID, WID_TARGET)]:
    w("""\t\t%s /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t%s /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};""" % (uid(key), bf(asset, target)))
w("/* End PBXResourcesBuildPhase section */")

# ---------- PBXSourcesBuildPhase ----------
w("\n/* Begin PBXSourcesBuildPhase section */")
def sources(key, items, target):
    body = "\t\t%s /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n" % uid(key)
    for p, n in items:
        body += "\t\t\t\t%s /* %s in Sources */,\n" % (bf(p, target), n)
    body += "\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};"
    w(body)
sources("phase:src:app", app_files + comp_files + view_files + shared_files, APP_TARGET)
sources("phase:src:widget", wid_files + shared_files, WID_TARGET)
w("/* End PBXSourcesBuildPhase section */")

# ---------- PBXTargetDependency ----------
w("\n/* Begin PBXTargetDependency section */")
w("""\t\t%s /* PBXTargetDependency */ = {
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = %s /* %s */;
\t\t\ttargetProxy = %s /* PBXContainerItemProxy */;
\t\t};""" % (uid("dep:widget"), uid("target:widget"), WID_TARGET, uid("proxy:widget")))
w("/* End PBXTargetDependency section */")

# ---------- XCBuildConfiguration ----------
BASE_COMMON = """\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = %s;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
""" % DEPLOY

PROJ_DEBUG = BASE_COMMON + """\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
"""
PROJ_RELEASE = BASE_COMMON + """\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
"""

APP_SETTINGS = """\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Zetrum";
\t\t\t\tINFOPLIST_KEY_NSCameraUsageDescription = "Kamera dipakai untuk memindai kode QR di badan charger SPKLU.";\n\t\t\t\tINFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "Lokasi dipakai untuk mengurutkan SPKLU dari yang terdekat.";\n\t\t\t\tINFOPLIST_KEY_NSSupportsLiveActivities = YES;
\t\t\t\tINFOPLIST_KEY_NSSupportsLiveActivitiesFrequentUpdates = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIStatusBarStyle = UIStatusBarStyleLightContent;
\t\t\t\tINFOPLIST_KEY_UIUserInterfaceStyle = Dark;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = %s;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
""" % APP_ID

WID_SETTINGS = """\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Zetrum";
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "";
\t\t\t\tINFOPLIST_FILE = ZetrumWidget/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = %s;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
""" % WID_ID

w("\n/* Begin XCBuildConfiguration section */")
def cfg(key, name, settings):
    w("""\t\t%s /* %s */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
%s\t\t\t};
\t\t\tname = %s;
\t\t};""" % (uid(key), name, settings, name))

cfg("cfg:project:debug", "Debug", PROJ_DEBUG)
cfg("cfg:project:release", "Release", PROJ_RELEASE)
cfg("cfg:app:debug", "Debug", APP_SETTINGS)
cfg("cfg:app:release", "Release", APP_SETTINGS)
cfg("cfg:widget:debug", "Debug", WID_SETTINGS)
cfg("cfg:widget:release", "Release", WID_SETTINGS)
w("/* End XCBuildConfiguration section */")

# ---------- XCConfigurationList ----------
w("\n/* Begin XCConfigurationList section */")
def conflist(key, label, dbg, rel):
    w("""\t\t%s /* Build configuration list for %s */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t%s /* Debug */,
\t\t\t\t%s /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};""" % (uid(key), label, uid(dbg), uid(rel)))

conflist("conflist:project", 'PBXProject "%s"' % PROJ, "cfg:project:debug", "cfg:project:release")
conflist("conflist:app", 'PBXNativeTarget "%s"' % APP_TARGET, "cfg:app:debug", "cfg:app:release")
conflist("conflist:widget", 'PBXNativeTarget "%s"' % WID_TARGET, "cfg:widget:debug", "cfg:widget:release")
w("/* End XCConfigurationList section */")

w("\t};")
w("\trootObject = %s /* Project object */;" % uid("project"))
w("}")

d = os.path.join(ROOT, PROJ + ".xcodeproj")
os.makedirs(d, exist_ok=True)
open(os.path.join(d, "project.pbxproj"), "w").write("\n".join(out) + "\n")
print("wrote", d)
