#! /bin/sh

xcrun extractLocStrings -s WMFLocalizedString -o Wikipedia/iOS\ Native\ Localizations/Base.lproj/ Wikipedia/Code/*
xcrun extractLocStrings -s WMFLocalizedString -a -o Wikipedia/iOS\ Native\ Localizations/Base.lproj/ WMF\ Framework/*
xcrun extractLocStrings -s WMFLocalizedString -a -o Wikipedia/iOS\ Native\ Localizations/Base.lproj/ InTheNewsNotification/*
xcrun extractLocStrings -s WMFLocalizedString -a -o Wikipedia/iOS\ Native\ Localizations/Base.lproj/ TopReadWidget/*
xcrun extractLocStrings -s WMFLocalizedString -a -o Wikipedia/iOS\ Native\ Localizations/Base.lproj/ ContinueReadingWidget/*

swift scripts/localization.swift