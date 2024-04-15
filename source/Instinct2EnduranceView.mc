import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

import EnduranceWatchFace;

class Instinct2EnduranceView extends WatchUi.WatchFace {

    enum DisplayedConditions {
        CLOUDY,
        CLEAR,
        CLEARNIGHT,
        PARTLY_CLOUDY
    }

    var conditions as WeatherConditions;
    var sleeping as Boolean = false;
 
    function initialize() {
        WatchFace.initialize();
        conditions = new WeatherConditions();
        
        System.println((("0").toCharArray()[0]).toNumber());
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
         //System.println("onLayout");
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        //System.println("onShow");
       BitmapTextDrawer.load();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get and show the current time
        // System.println("onUpdate");
        var clockTime = System.getClockTime();
        var hourString = Lang.format("$1$", [clockTime.hour.format("%02d")]);
        var minString = Lang.format("$1$", [clockTime.min.format("%02d")]);
        var view = View.findDrawableById("HourLabel") as Text;
        view.setText(hourString);
        view = View.findDrawableById("MinuteLabel") as Text;
        view.setText(minString);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        if (!sleeping) {
            BitmapTextDrawer.draw(dc, 59, 121, clockTime.sec.format("%02d"));
        }

        var cnd = conditions.get();
        if (cnd != null) {
            var tempText = Lang.format("$1$°", [cnd[:condition].temperature.format("%d")]);
            var xpos = 145 - (dc.getTextWidthInPixels(tempText, Graphics.FONT_NUMBER_MILD) + 8) / 2;
            dc.drawText(xpos + 8, 22, Graphics.FONT_NUMBER_MILD, tempText, Graphics.TEXT_JUSTIFY_LEFT);

            var sunrs = cnd[:nextSunsetSunrise];
            BitmapTextDrawer.draw(dc, 50, 24, sunrs.hour.format("%02d"));
            BitmapTextDrawer.draw(dc, 66, 24, sunrs.min.format("%02d"));

            conditions.drawConditionBitmap(dc, 134, 9);
            BitmapTextDrawer.draw(dc, xpos, 30, cnd[:windCardinalDirection].format("%d"));
            BitmapTextDrawer.draw(dc, xpos, 40, cnd[:windBeaufort].format("%d"));
        }

        BitmapTextDrawer.draw(dc, 50, 143, System.getSystemStats().battery.format("%02d"));

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.setPenWidth(1);
        dc.drawLine(13, 1, 13, 175);
        dc.drawLine(54, 1, 54, 175);

        dc.drawLine(0, 84, 88, 84);
        dc.drawLine(0, 92, 88, 92);

        //dc.drawLine(114, 27, 176, 27);

        
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        System.println("onHide");
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        System.println("onExitSleep");
        sleeping = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        System.println("onEnterSleep");
        sleeping = true;
    }

}

class BitmapTextDrawer {

    static var numbersBitmap;

    static function load() {
        if (BitmapTextDrawer.numbersBitmap == null) {
            BitmapTextDrawer.numbersBitmap = WatchUi.loadResource(Rez.Drawables.XXTinyNumbers) as BitmapResource;
        }
    }

    static function draw(dc as Dc, x as Number, y as Number, str as String) {

        var arr = str.toCharArray();
        var i;
        for (i = 0; i < arr.size(); i++) {
            var c = arr[i];
            var numidx = c.toNumber() - 48;
            if (numidx >= 0 && numidx < 10) {
                dc.setClip(x + i * 6, y, 5, 9);
                dc.drawBitmap(x + i * 6 - numidx * 6, y, BitmapTextDrawer.numbersBitmap);
            }
        }
        dc.clearClip();
    }
}

