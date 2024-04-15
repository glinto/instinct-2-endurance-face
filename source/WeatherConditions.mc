import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

module EnduranceWatchFace {

	typedef ExtendedConditions as {
		:condition as Weather.CurrentConditions,
		:nextSunsetSunrise as Time.Gregorian.Info or Null,
		:conditionType as Number,
		:windBeaufort as Number,
		:windCardinalDirection as Number,
		:lastUpdate as Time.Moment,
	};

	const WEATHER_CACHE_TIMEOUT_SEC = 10;

	class WeatherConditions {
		
		enum {
			CLOUDY,
			CLEAR,
			CLEARNIGHT,
			PARTLY_CLOUDY
		}

		enum {
			NORTH,
			NORTHEAST,
			EAST,
			SOUTHEAST,
			SOUTH,
			SOUTHWEST,
			WEST,
			NORTHWEST
		}

		private const CONDITION_BITMAP_WIDTH = 18;
		private const CONDITION_BITMAP_HEIGHT = 16;

		private var conditionsBitmap as BitmapResource;

		private var cache as ExtendedConditions or Null;

		private const mappedConditions = {
			Weather.CONDITION_CLEAR => WeatherConditions.CLEAR,
			Weather.CONDITION_CLOUDY => WeatherConditions.CLOUDY,
			Weather.CONDITION_PARTLY_CLOUDY => WeatherConditions.PARTLY_CLOUDY,   
			Weather.CONDITION_PARTLY_CLEAR => WeatherConditions.PARTLY_CLOUDY
		};

		function initialize() {
			conditionsBitmap = WatchUi.loadResource(Rez.Drawables.Conditions) as BitmapResource;
		}

		function get() as ExtendedConditions or Null {
			if (cache == null || cache[:lastUpdate].value() < Time.now().value() - WEATHER_CACHE_TIMEOUT_SEC) {
				//System.println("Loading conditions");
				var cnd = Toybox.Weather.getCurrentConditions();
				if (cnd == null) {
					return null;
				}
				cache = {
					:condition => cnd,
					:nextSunsetSunrise => getNextSunriseOrSunset(cnd),
					:conditionType => WeatherConditions.CLOUDY,
					:windBeaufort => beaufortIndex(cnd.windSpeed),
					:windCardinalDirection => getCardinalDirection(cnd.windBearing),
					:lastUpdate => Time.now()
				};
			
				if (mappedConditions[cnd.condition] != null) {
					cache[:conditionType] = mappedConditions[cnd.condition];
				} 
			}
			return cache;
		}

		function drawConditionBitmap(dc, x, y) {
			if (cache != null) {
				var idx = cache[:conditionType];
				dc.setClip(x, y, CONDITION_BITMAP_WIDTH, CONDITION_BITMAP_HEIGHT);
				dc.drawBitmap(x - idx * CONDITION_BITMAP_WIDTH, y, conditionsBitmap);
				dc.clearClip();
			}
		}

		private function getNextSunriseOrSunset(cnd as Weather.CurrentConditions) as Time.Gregorian.Info or Null {
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

		private function beaufortIndex(windSpeed as Float) as Number {
			if (windSpeed < 0.3) {return 0;}
			if (windSpeed <= 1.5) {return 1;}
			if (windSpeed <= 3.3) {return 2;}
			if (windSpeed <= 5.4) {return 3;}
			if (windSpeed <= 7.9) {return 4;}
			if (windSpeed <= 10.7) {return 5;}
			if (windSpeed <= 13.8) {return 6;}
			if (windSpeed <= 17.1) {return 7;}
			if (windSpeed <= 20.7) {return 8;}
			if (windSpeed <= 24.4) {return 9;}
			if (windSpeed <= 28.4) {return 10;}
			if (windSpeed <= 32.6) {return 11;}
			return 12;
		}

		private function getCardinalDirection(bearing as Number) as Number {
			if (bearing < 22.5 || bearing >= 337.5) {return WeatherConditions.NORTH;}
			if (bearing < 67.5) {return WeatherConditions.NORTHEAST;}
			if (bearing < 112.5) {return WeatherConditions.EAST;}
			if (bearing < 157.5) {return WeatherConditions.SOUTHEAST;}
			if (bearing < 202.5) {return WeatherConditions.SOUTH;}
			if (bearing < 247.5) {return WeatherConditions.SOUTHWEST;}
			if (bearing < 292.5) {return WeatherConditions.WEST;}
			return WeatherConditions.NORTHWEST;
		}

	}

}