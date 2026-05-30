import QtQuick

QtObject {
    //  Power
    readonly property string powerShutdown: "\ue000"
    readonly property string powerReboot:   "\ue001"
    readonly property string powerSuspend:  "\ue002"
    readonly property string powerLogoff:   "\ue003"

    //  Battery
    readonly property string batNone:     "\ue004"
    readonly property string batCritical: "\ue005"
    readonly property string batLow:      "\ue006"
    readonly property string batNormal:   "\ue007"
    readonly property string batHigh:     "\ue008"
    readonly property string batFull:     "\ue009"
    readonly property string batUnknown:  "\ue00a"
    readonly property string batCharging: "\ue00b"
    readonly property string batCharged:  "\ue00c"

    //  Media
    readonly property string mediaMusic:    "\ue00d"
    readonly property string mediaPrevious: "\ue00e"
    readonly property string mediaNext:     "\ue00f"
    readonly property string mediaPause:    "\ue010"
    readonly property string mediaPlay:     "\ue011"
    readonly property string mediaShuffle:  "\ue012"
    readonly property string mediaLoop:     "\ue041"

    //  Audio
    readonly property string audioMuted:    "\ue013"
    readonly property string audioDecrease: "\ue014"
    readonly property string audioIncrease: "\ue015"
    readonly property string changeSource: "\uf144"

    //  Microphone
    readonly property string micMuted:    "\ue016"
    readonly property string micDecrease: "\ue017"
    readonly property string micIncrease: "\ue018"

    //  Arrows
    readonly property string arrowRight: "\ue019"
    readonly property string arrowDown:  "\ue01a"
    readonly property string arrowLeft:  "\ue01b"
    readonly property string arrowUp:    "\ue01c"

    //  Utils
    readonly property string utilsMagnifier: "\ue01d"
    readonly property string utilsHamburger: "\ue01e"

    //  Titlebar
    readonly property string titlePin:      "\ue01f"
    readonly property string titleClose:    "\ue020"
    readonly property string titleMaximize: "\ue021"
    readonly property string titleMinimize: "\ue022"

    //  Network
    readonly property string wifiHigh:   "\ue023"
    readonly property string wifiNormal: "\ue024"
    readonly property string wifiLow:    "\ue025"
    readonly property string wifiNone:   "\ue026"
    readonly property string wiredNormal: "\ue027"
    readonly property string wiredNone:   "\ue028"
    readonly property string networkNone: "\ue029"

    //  Bluetooth
    readonly property string bluezOff:      "\ue02a"
    readonly property string bluezScanning: "\ue02b"
    readonly property string bluezOn:       "\ue02c"

    //  Weather — day
    readonly property string dayClear:       "\ue02d"
    readonly property string dayPartCloudy:  "\ue02e"
    readonly property string dayCloudy:      "\ue02f"
    readonly property string dayLightRain:   "\ue030"
    readonly property string dayRain:        "\ue031"
    readonly property string dayStorm:       "\ue032"
    readonly property string daySnow:        "\ue033"
    readonly property string dayFog:         "\ue034"

    //  Weather — night
    readonly property string nightClear:      "\ue035"
    readonly property string nightPartCloudy: "\ue036"
    readonly property string nightCloudy:     "\ue037"
    readonly property string nightLightRain:  "\ue038"
    readonly property string nightRain:       "\ue039"
    readonly property string nightStorm:      "\ue03a"
    readonly property string nightSnow:       "\ue03b"
    readonly property string nightFog:        "\ue03c"

    //  Layout
    readonly property string layoutFloating: "\ue03d"
    readonly property string layoutTileBot:  "\ue03e"
    readonly property string layoutTile:     "\ue03f"
    readonly property string layoutTileLeft: "\ue040"

    function weatherGlyph(code, isDay) {
        const d = isDay
        const map = {
            "113": d ? dayClear      : nightClear,
            "116": d ? dayPartCloudy : nightPartCloudy,
            "119": d ? dayCloudy     : nightCloudy,
            "122": d ? dayCloudy     : nightCloudy,
            "143": d ? dayFog        : nightFog,
            "248": d ? dayFog        : nightFog,
            "260": d ? dayFog        : nightFog,
            "176": d ? dayLightRain  : nightLightRain,
            "263": d ? dayLightRain  : nightLightRain,
            "266": d ? dayLightRain  : nightLightRain,
            "293": d ? dayLightRain  : nightLightRain,
            "296": d ? dayLightRain  : nightLightRain,
            "299": d ? dayRain       : nightRain,
            "302": d ? dayRain       : nightRain,
            "305": d ? dayRain       : nightRain,
            "308": d ? dayRain       : nightRain,
            "200": d ? dayStorm      : nightStorm,
            "386": d ? dayStorm      : nightStorm,
            "389": d ? dayStorm      : nightStorm,
            "227": d ? daySnow       : nightSnow,
            "230": d ? daySnow       : nightSnow,
            "179": d ? daySnow       : nightSnow,
            "182": d ? daySnow       : nightSnow,
            "281": d ? daySnow       : nightSnow,
            "317": d ? daySnow       : nightSnow,
            "320": d ? daySnow       : nightSnow,
            "368": d ? daySnow       : nightSnow,
            "392": d ? dayStorm      : nightStorm,
            "395": d ? daySnow       : nightSnow,
        }
        return map[code] ?? (d ? dayCloudy : nightCloudy)
    }
}
