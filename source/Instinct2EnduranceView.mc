import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

const WEATHER_CACHE_TIMEOUT_SEC = 300;

class MyWeatherConditions {
    enum {
        CLOUDY,
        CLEAR,
        CLEARNIGHT,
        PARTLY_CLOUDY
    }

    const CONDITION_BITMAP_WIDTH = 18;
    const CONDITION_BITMAP_HEIGHT = 16;

    var conditionsBitmap as BitmapResource;

    var cache as {
        :condition as Weather.CurrentConditions,
        :nextSunsetSunrise as Time.Gregorian.Info or Null,
        :conditionType as Number,
        :lastUpdate as Time.Moment
    } or Null;

    const mappedConditions = {
        Weather.CONDITION_CLEAR => MyWeatherConditions.CLEAR,
        Weather.CONDITION_CLOUDY => MyWeatherConditions.CLOUDY,
        Weather.CONDITION_PARTLY_CLOUDY => MyWeatherConditions.PARTLY_CLOUDY,   
        Weather.CONDITION_PARTLY_CLEAR => MyWeatherConditions.PARTLY_CLOUDY
    };

    function initialize() {
        conditionsBitmap = WatchUi.loadResource(Rez.Drawables.Conditions) as BitmapResource;
    }

    function load() {
        if (cache == null || cache[:lastUpdate].value() < Time.now().value() - WEATHER_CACHE_TIMEOUT_SEC) {
            //System.println("Loading conditions");
            var cnd = Toybox.Weather.getCurrentConditions();
            if (cnd == null) {
                return;
            }
            cache = {
                :condition => cnd,
                :nextSunsetSunrise => getNextSunriseOrSunset(cnd),
                :conditionType => MyWeatherConditions.CLOUDY,
                :lastUpdate => Time.now()
            };
           
            if (mappedConditions[cnd.condition] != null) {
                cache[:conditionType] = mappedConditions[cnd.condition];
            } 
        }
    }

    function drawConditionBitmap(dc, x, y) {
        if (cache != null) {
            var idx = cache[:conditionType];
            dc.setClip(x, y, CONDITION_BITMAP_WIDTH, CONDITION_BITMAP_HEIGHT);
            dc.drawBitmap(x - idx * CONDITION_BITMAP_WIDTH, y, conditionsBitmap);
            dc.clearClip();
        }
    }

    function getNextSunriseOrSunset(cnd as Weather.CurrentConditions) as Time.Gregorian.Info or Null {
        if (cnd != null && cnd.observationLocationPosition != null) {

            var now = Time.now();

            var nextsun = Weather.getSunrise(cnd.observationLocationPosition, now);
            if (nextsun == null) {
                return null;
            }

            if (nextsun.value() < now.value()) {
                nextsun = Weather.getSunset(cnd.observationLocationPosition, now);
                if (nextsun == null) {
                    return null;
                }
            }
            
            if (nextsun.value() < now.value()) {
                nextsun = Weather.getSunrise(cnd.observationLocationPosition, now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY)));
                if (nextsun == null) {
                    return null;
                }
            }

            return Gregorian.info(nextsun, Time.FORMAT_SHORT);

        }
        return null;
    }

}

class MyWeather {
    
}

class Instinct2EnduranceView extends WatchUi.WatchFace {

    enum DisplayedConditions {
        CLOUDY,
        CLEAR,
        CLEARNIGHT,
        PARTLY_CLOUDY
    }

    var myconditions as MyWeatherConditions;
 
    function initialize() {
        WatchFace.initialize();
        myconditions = new MyWeatherConditions();
        
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

        myconditions.load();
        if (myconditions != null) {
            var temp = myconditions.cache[:condition].temperature;
            view = View.findDrawableById("TemperatureLabel") as Text;
            view.setText(Lang.format("$1$°", [temp.format("%d")]));
            //System.println(Lang.format("$1$", [cnd.observationLocationPosition]));

            var sunrs = myconditions.cache[:nextSunsetSunrise];
            BitmapTextDrawer.draw(dc, 50, 24, sunrs.hour.format("%02d"));
            BitmapTextDrawer.draw(dc, 66, 24, sunrs.min.format("%02d"));

            myconditions.drawConditionBitmap(dc, 134, 9);
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
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        System.println("onEnterSleep");
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

