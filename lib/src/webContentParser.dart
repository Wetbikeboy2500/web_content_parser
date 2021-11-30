import 'scraper/headless.dart';

///Central class for settings
class WebContentParser {
  ///Allow verbose logging
  static bool verbose = false;

  ///Headless browsers that the scrapers can use
  static List<Headless> headlessBrowsers = [];

  ///Adds a headless browser that can be used
  ///
  ///You have to add a headless browser because nothing from the mobile or desktop versions are imported by default.
  ///By not importing within the library, tree shaking of dependencies will be on the developer using the package.
  static void addHeadless(Headless headless) {
    headlessBrowsers.add(headless);
  }
}
