[![Build](https://github.com/Wetbikeboy2500/web_content_parser/actions/workflows/build.yml/badge.svg)](https://github.com/Wetbikeboy2500/web_content_parser/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/Wetbikeboy2500/web_content_parser/branch/main/graph/badge.svg?token=I49J6Q80WP)](https://codecov.io/gh/Wetbikeboy2500/web_content_parser)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Web Content Parser

One goal: Unify web content parsing between projects.

This package is separated into two parts: the scraper and the parser.

The scraper is responsible for extract of data. It can retrieve web pages and execute extraction scripts.

The parser is responsible for transforming the raw data and loading it into a known Dart object structure.

The scraping system is separate from the parsing system and can be used independently. This scraping system allows users to write scripts in [WQL](#wql-web-query-language), a language designed for scraping websites. Custom functions are also implemented in WQL to make scripting easier. These functions that are exposed can also be used in regular Dart projects. There are also methods to get webpages through a headless browser for mobile and desktop. These interfaces are available separately in the packages directory. If you need a dynamic system to parse websites, this is it.

Web Content Parser will not support downloading of any content. This project isn't a download manager. Web Content Parser's goal, from a functionality standpoint, is to be an interface and a system for standardization.

This project is still in development but does have complete functionality. I am working towards refining function names and the structure of the project. There is also always room to explore what scripts can do and how to define new functionality for them. I would recommend to add this project through git with a hash specified. If you want to try out the web_content_headless portion, include a dependency override with the hash to remove dependency errors. Once things are to my standard and stable, I will switch to semantic versioning.

## Focus

Building a versatile system for many different types of content. This includes providing easy integration into other systems and architectures. I also want to explore using headless browsers for more dynamic content that requires scripts and other things to run first.

## Design

Import everything:
```dart
import 'package:web_content_parser/web_content_parser_full.dart';
```

This project can be thought of in three different code bases based on the directories inside lib/src.

* [Util](#util)

    This has most of the utility classes and important enums that work for moving data around. It is the core for making sure calls can be made and wrapping responses with easy to integrate classes instead of throwing exceptions. Most things are shared between the scraper and parser sections.

    Individual import:
    ```dart
    import 'package:web_content_parser/util.dart';
    ```

* [Scraper](#scraper)

    This handles custom sources which are written in [WQL](#wql-web-query-language). It is used to retrieve raw data that is passed to the parser so it can be formatted in a standard format. This is flexible and can be used without the parser part of the project to do web scraping. It is designed to allow developers to completely ignore the opinionated nature of how this project process and builds data in the parser portion. It is also my focus to create a more fluent API for scraping and to address things like dynamic data through webviews and/or sites that require javascript to function.

    Individual import:
    ```dart
    import 'package:web_content_parser/scraper.dart';
    ```

* [Parser](#parser)

    The parser is what takes the raw data from the scraper and converts it into dart classes to be used. This also reinforces data cleaning and validation. This will not be useful for most using this project since much more can be done with the scraper. One important thing it defines is [IDs](#ids) which are very important for making sure sources don't collide. Everything else is a subset for dealing with the data. There is currently only one defined structure for data which is designed for series that have chapters of images. More formats or source types are welcome to be implemented. This is the part of the project with the most room for exploration of what should be done. If you have any suggestions, feel free to share them. I would like this to also include implementations for various APIs so data can be standardized.

    Individual import:
    ```dart
    import 'package:web_content_parser/parser.dart';
    ```

## Util

The util directory has vital code for how things interact with each other.

### Result

The most important part of the project is how data is moved between methods and functions. `Result` is a sealed class that has a `Pass` and `Fail` class to represent the two different object state types. This is used in place of exceptions due to the need to handle failing cases and enforce checking if the data is valid.

The data type annotation for the result can be set like so:

```dart
void Result<String> someFunction() { return Fail() };
```

The `Result<T>` is sealed and cannot be instantiated. This leaves `Result` being either a `Pass` or `Fail` object.

`Fail` does not store any information on what the failure is. It simply indicates that the operation failed.

`Pass<T>` has one attribute:

* `T data`

    T is the type annotation set by the dev. Data is what was given in the object constructor.


Examples:

```dart
Pass<String>('valid'); //valid
Pass<String>(null); //invalid since type cannot be null
Pass<String?>('valid'); //valid
Pass<String?>(null); //valid
const Fail(); //valid
```

The following is the best way to check for if a result has passed or failed. This avoids the need to keep checking if `status` equals a specific `ResultStatus` enum.

```dart
Pass('valid') is Pass; //true
Pass('valid') is Fail; //false
const Fail() is Pass; //false
const Fail() is Fail; //true
//Sometimes type checking is not properly applied using `is`. Instead use `case` for pattern matching which also allows for type checking of the data. The following is not valid dart code but is used to show the idea.
Pass('valid') case Pass(); //true
Pass<String>('valid') case Pass(); //true
Pass<String?>('valid') case Pass<String>(); //false
Pass('valid') case Fail(); //false
const Fail() case Pass(); //false
const Fail() case Fail(); //true
```

```dart
Result<String> result = Pass('valid');
if (result case Pass(data: final data)) { //pattern matching and destructuring
    print(data);
}
```

### ResultExtended

ResultExtended is an extension on result. ResultExtended has static methods that can make creating result objects easier while handling logging inside the project. These are not in the Result class since these methods cannot be considered agnostic.


## Scraper

The scraper handles the interaction with [WQL](#wql-web-query-language) and making sure to provide the nessary functionality to scrape any site.

### Sections

* [Headless Browser Web Scrapers](#headless-browser-web-scrapers)
* [Loading in Scraping Sources](#loading-in-scraping-sources)
    * [Load Functions](#load-functions)

### Headless Browser Web Scrapers

Headless browsers provide a lot of power to scrape dynamic pages. This project currently uses puppeteer and flutter_inappwebview. These two packages provide the power to scrape on any platform.

**Note:** These packages have only been tested on Android, Linux, and Windows systems.

The headless browser system is optional and needs the developer to "add" them to the scraper. This is done for tree shaking and allowing the use of custom headless browsers with the package. The interfaces that need to be initialized in the package can be obtained from `import 'package:web_content_parser/headless.dart';`

#### Mobile:

```dart
WebContentParser.addHeadless(MobileHeadless());
```

#### Desktop:

```dart
WebContentParser.addHeadless(DesktopHeadless());
```

Once the headless browsers are added, they can be used through an interface define for them. The standard interface is implemented through `Future<Result<String>> getDynamicPage(String url) async` function. `getDynamicPage` returns all the HTML of a page as a single string wrapped with a `Result` class to indicate if the operation passed or failed. You can pass the function a `url`, and the supported headless browser will be chosen and used to get the requested information. How multiple requests are handled is up to the headless browser implementation. Current implementations have a basic queue system to only allow one request at a time. The `getDynamicPage` function is exposed through `import 'package:web_content_parser/scraper.dart';`

### Loading in scraping sources

Scraping sources are defined through yaml. The reason you need to use a scraping source is to make sure things stay properly formatted and compliant with other sources.

**Note:** There is a valid version of a scraper source yaml file. It is test/samples/scraper/source.yaml

Scraping sources have the following required attributes:

* **source** source is the unique name for identifying a source

* **baseUrl** baseUrl is the websites hostname. It should not include a subdomain

* **subdomain** subdomain is optional and can be null. This is for if a specific subdomain must be present for a source to work

* **version** version is an int used for tracking what the current source version is. This will help determine if one source is newer than another

* **programType** programType is the current scripting environment you are targeting. The only valid value is currently wql. This ensures incompatible programs can't run when new requirements are needed or changed.

* **requests** requests is a list of all possible scripting calls that can be made. They have a `type` which is the name to call the execute the script. They have a `file` which is the script file that sits in the current directory of the yaml file or deeper. There is also `programType` which is optional as it will inherit its value from the one defined in the parent. This allows for a source to have multiple program types. This is useful for allowing more scripting systems.

All things mentioned can be looked at in the example yaml file at test/samples/scraper/source.yaml

You can also add your own attributes if you want to bundle additional data. It will all be converted to a map that you can access from the ScraperSource object.

If you have any suggestions for how to improve the current format, feel free to share them.

#### Load Functions

The recommended way to load in scraper sources is to use one of the two top level functions. These functions can take a directory and load all .yaml or .yml files it finds. One function will add these sources to a global place you can access by calling `ScraperSource.scrapper('name')` which will return a scraper source object if it exists. This allows you to not have to bother with tracking where you scraper sources are. The other function simply returns all found sources as there objects. It is up to you as the dev to determine what should then be done with those.

```dart
void loadExternalScraperSourcesGlobal(Directory dir)
List<ScraperSource> loadExternalScarperSources(Directory dir)
```

## Parser

The parser converts raw data into a format that I have defined. This is more for myself and projects where I need to implement well structured data while staying up to date with naming schemes. I am trying to make sure there isn't a version dependency created by me having to maintain two separate packages.

### IDs

The core of any content is how they are identified. This project uses an id/source system to create unique ids. The id and source are both strings. An ID can be created through the following:

```dart
ID(id: '', source: '');
```

IDs should contain all the information a source needs to retrieve any relevant information. Extra data can be embedded into the id string to allow finding the item again. IDs are compared using a unique string called `uid`. `uid` is built from combining `source` and `id` with a colon in-between. Example:

```dart
ID id1 = ID(id: 'uniqueid', source: 'test');
ID id2 = ID(id: 'uniqueid', source: 'test');
assert(id1.uid == 'test:uniqueid');
assert(id1 == id2);
```

This format makes ids readable even when stored by their uid. Sources should also not have their names(`source` property) contain colons. This allows for extracting the `source` and `id` based on the location of the first colon. `uid` can also be passed as a parameter to set the uid for the id. Being able to set the uid can allow invalid values for the given ID, but it can reduce string operations from data conversions.

IDs are tied to all information returned.

### ChapterIDs

The next step to content is the subset of information that can exist. ChapterIDs core idea for identification can be applied to other content. It directly holds an ID object but with an added index and url for the content it points to. It currently uses its index for uniqueness.

```dart
ChapterID(id: ID(id: '', source: ''), index: 0, url: '')
```

This also uses a uid like IDs but with an added value added to the end. It adds the index to the end of the uid with a colon so it follows the format of `source:id:index`. This means all info can also be extracted from the uid since it can go off the first and last occurrence of the colon with the id being any value.

When using the fromJson() constructor, the ID can be passed as a map or an object.

### Computing

A ComputeDecorator is a class implementation for allowing different types of computes when converting objects. The decorator currently uses the Computer package which is agnostic to the platform it is run on. This decorator can be changed by setting `ParseSource.computeDecorator` to a different decorator implementation. This can allow for compute, which is available in Flutter, to be used. The ComputeDecorator can be turned off and not used by setting `ParseSource.computeEnabled`. It is enabled by default. Everything will function the same with the compute off, but processing large amounts of objects may perform worse.

## WQL: Web Query Language

WQL is a scripting language built for extracting data from web pages. It is designed to be declarative and quick to change. The goal is to simplify web scraping and reduce the common patterns that a more generic scripting language forms when scraping websites.

### Why use a custom language?

Using a general purpose scripting language within another language is overkill. A general purpose language does allow flexibility but leaves design and access patterns up to the developer. These choices end up adding bloat to scripts that also adds more cognitive load. When there are many scripts for web scraping, a developer must be able to understand them and make changes to them quickly: websites are not a stable source.

There is also the problem of finding a stable scripting language that is cross platform.

Lastly, I can't find a comparable language. From a few iterations while using it for scripts, the current WQL is the best balance I could find between declarativeness, intuitiveness, and flexibility.

### How to use it

Currently, the best examples are written in the test file. There are examples of making requests directly as well as integrating into the scraper system.
