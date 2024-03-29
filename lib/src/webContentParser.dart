import 'scraper/headless/headless.dart';
import 'util/log.dart';

///Central class for settings
class WebContentParser {
  ///Allow verbose logging
  static LogLevel verbose = const LogLevel.silent();

  ///Headless browsers that the scrapers can use
  static List<Headless> headlessBrowsers = [];

  ///Duration for how long a request will persist
  ///This is in-memory caching used to help alleviate duplicate requests hitting the same endpoint
  ///
  ///This will cause the application to wait for the timer to end before the application ends
  ///If a request single request is made and the duration is set to a minute, it will take at least a minute for the application to close
  ///
  static Duration cacheTime = const Duration(milliseconds: 1000);

  ///Adds a headless browser that can be used
  ///
  ///You have to add a headless browser because nothing from the mobile or desktop versions are imported by default.
  ///By not importing within the library, tree shaking of dependencies will be on the developer using the package.
  static void addHeadless(Headless headless) {
    headlessBrowsers.add(headless);
  }
}
