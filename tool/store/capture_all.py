"""Capture the 7 store screens in every app language on emulator-5554."""
import os, subprocess, sys, time

ADB = [os.path.expandvars(r'%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe'), '-s', 'emulator-5554']
PKG = 'com.crazypenguin.doctorfilter'
OUT = os.path.join(os.path.dirname(__file__), 'raw')
RTL = {'ar', 'he', 'fa', 'ur'}
LANGS = sys.argv[1].split(',') if len(sys.argv) > 1 else (
    'en tr de es fr it pt ru uk pl nl ja ko zh ar he fa hi bn id ms vi th fil ur af az be bg ca cs da el et eu fi gl gu '
    'hr hu hy is ka kk kn ky lo lt lv mk ml mn mr my ne pa ro si sk sl sq sr sv sw ta te zu').split()


def sh(*a):
    return subprocess.run(ADB + ['shell', *a], capture_output=True)


def tap(x, y, rtl):
    sh('input', 'tap', str(1080 - x if rtl else x), str(y))


def cap(lang, name):
    d = os.path.join(OUT, lang)
    os.makedirs(d, exist_ok=True)
    png = subprocess.run(ADB + ['exec-out', 'screencap', '-p'], capture_output=True).stdout
    open(os.path.join(d, name + '.png'), 'wb').write(png)


def back():
    sh('input', 'keyevent', '4')
    time.sleep(1.5)


for lang in LANGS:
    rtl = lang in RTL
    sh('cmd', 'locale', 'set-app-locales', PKG, '--locales', lang)
    sh('am', 'force-stop', PKG)
    sh('am', 'start', '-n', PKG + '/.MainActivity')
    time.sleep(7)
    tap(413, 895, rtl); time.sleep(1.5)
    cap(lang, '1_home')
    tap(405, 1752, rtl); time.sleep(2.5); cap(lang, '2_presets'); back()
    tap(675, 1752, rtl); time.sleep(2.5); cap(lang, '4_schedule'); back()
    tap(945, 1752, rtl); time.sleep(2.5); cap(lang, '5_learn'); back()
    tap(1006, 147, rtl); time.sleep(2.5); cap(lang, '6_settings'); back()
    tap(210, 354, rtl); time.sleep(3); cap(lang, '8_filter_on')
    sh('cmd', 'statusbar', 'expand-notifications'); time.sleep(3); cap(lang, '7_notification')
    sh('cmd', 'statusbar', 'collapse'); time.sleep(1.5)
    tap(210, 354, rtl); time.sleep(1.5)
    print(lang, flush=True)
print('done')
