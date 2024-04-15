import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

module EnduranceWatchFace {

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
	
}