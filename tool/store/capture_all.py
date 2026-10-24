"""Capture the raw store screens in every app language on an Android emulator.

Needs the STORE_SCREENSHOTS debug build installed:
  flutter build apk --debug --dart-define=STORE_SCREENSHOTS=true
Screens are opened by name through the df_store_screen preference (written
with run-as), so no taps and no screen-size coordinates are involved.

usage: python capture_all.py [serial] [lang,lang...|all] [screen,screen...]
Output: raw/android/<lang>/<screen>.png
"""
import os, subprocess, sys, time

SERIAL = sys.argv[1] if len(sys.argv) > 1 else 'emulator-5554'
ADB = [os.path.expandvars(r'%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe'), '-s', SERIAL]
PKG = 'com.crazypenguin.doctorfilter'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'raw', 'android')
LANGS = sys.argv[2].split(',') if len(sys.argv) > 2 and sys.argv[2] != 'all' else (
    'en tr de es fr it pt ru uk pl nl ja ko zh zh-TW ar he fa hi bn id ms vi th fil ur af az be bg ca cs da el et eu fi gl gu '
    'hr hu hy is ka kk kn ky lo lt lv mk ml mn mr my ne pa ro si sk sl sq sr sv sw ta te zu').split()
# Raw screen name -> df_store_screen value ('' = home).
SCREENS = {'1_home': '', '2_presets': 'presets', '4_schedule': 'schedule', '5_learn': 'learn', '6_settings': 'settings'}
if len(sys.argv) > 3:  # optional: only these raw screens, e.g. 5_learn
    SCREENS = {k: v for k, v in SCREENS.items() if k in sys.argv[3].split(',')}


def sh(*a, check=False):
    return subprocess.run(ADB + ['shell', *a], capture_output=True, text=True, check=check)


def prefs(screen, kelvin=3400, enabled=False):
    xml = ("<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n<map>\n"
           '<boolean name="flutter.df_onboarding_done" value="true" />\n'
           f'<long name="flutter.df_filter_kelvin" value="{kelvin}" />\n'
           '<long name="flutter.df_filter_density_percent" value="25" />\n'
           f'<boolean name="flutter.df_filter_enabled" value="{str(enabled).lower()}" />\n'
           f'<string name="flutter.df_store_screen">{screen}</string>\n</map>\n')
    sh('am', 'force-stop', PKG)
    p = subprocess.run(ADB + ['shell', 'run-as', PKG, 'sh', '-c',
                              "'mkdir -p shared_prefs && cat > shared_prefs/FlutterSharedPreferences.xml'"],
                       input=xml, text=True, capture_output=True)
    if p.returncode:
        raise SystemExit(p.stderr)


def cap(lang, name):
    d = os.path.join(OUT, lang)
    os.makedirs(d, exist_ok=True)
    png = subprocess.run(ADB + ['exec-out', 'screencap', '-p'], capture_output=True).stdout
    open(os.path.join(d, name + '.png'), 'wb').write(png)


def demo_bar():
    sh('settings', 'put', 'global', 'sysui_demo_allowed', '1')
    for cmd in (['enter'], ['clock', '-e', 'hhmm', '0941'], ['battery', '-e', 'level', '100', '-e', 'plugged', 'false'],
                ['network', '-e', 'wifi', 'show', '-e', 'level', '4'], ['network', '-e', 'mobile', 'show', '-e', 'level', '4'],
                ['notifications', '-e', 'visible', 'false']):
        sh('am', 'broadcast', '-a', 'com.android.systemui.demo', '-e', 'command', *cmd)


def snooze_others():
    """Hide every other app's notification so the shade shows only ours."""
    out = sh('dumpsys', 'notification', '--noredact').stdout
    import re
    for key in set(re.findall(r'key=(\S+)', out)):
        if PKG not in key:
            sh('cmd', 'notification', 'snooze', '--for', '3600000', key)


def launch(wait=25):
    sh('am', 'start', '-n', PKG + '/.MainActivity')
    time.sleep(wait)


demo_bar()
sh('appops', 'set', PKG, 'SYSTEM_ALERT_WINDOW', 'allow')
sh('pm', 'grant', PKG, 'android.permission.POST_NOTIFICATIONS')
for lang in LANGS:
    demo_bar()
    sh('cmd', 'locale', 'set-app-locales', PKG, '--locales', lang)
    for name, screen in SCREENS.items():
        prefs(screen)
        launch()
        cap(lang, name)
    print(lang, flush=True)
sh('am', 'broadcast', '-a', 'com.android.systemui.demo', '-e', 'command', 'exit')
print('done')
