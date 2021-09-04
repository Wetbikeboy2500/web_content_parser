[![Build](https://github.com/Wetbikeboy2500/web_content_parser/actions/workflows/build.yml/badge.svg)](https://github.com/Wetbikeboy2500/web_content_parser/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/Wetbikeboy2500/web_content_parser/branch/main/graph/badge.svg?token=I49J6Q80WP)](https://codecov.io/gh/Wetbikeboy2500/web_content_parser)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Web Content Parser

One goal: unify web content parsing between dart projects.

This will not support downloading of any content. This simply acts as the interface.

This project is still in development but does have complete functionality. I am working towards refining function names and the structure of the project. There is also always room to explore what scripts can do and how to define new functionality for them. I would recommend to add this project through git with a hash specified. Once things are to my standard, I will switch to semantic versioning.

## Focus

Building a versitile system for many different types of content. This includes providing easy integration into other systems and architectures. I also want to explore using headless browsers for more dynamic content that requires scripts and other things to run first.

## Design

This project can be thought of in three different code bases based on directory inside src.

* [Util](#util)

    This has most of the utilty classes and important enums that work for moving data around. It is the core for making sure calls can be made and wrapping responses with easy to integrate classes instead of throwing exceptions. Most things are shared between the scraper and parser sections.

* [Scraper](#scraper)

    This handles custom sources which are written in [hetu-script](https://github.com/hetu-script/hetu-script). It is used to return raw data to the parser to be formatted in a known format. This is flexible and can be used without the parser part of the project to do web scraping while staying away from predefined data structures. It is desinged this way to allow developers to completely ignore the opinionated nature of how this project process and builds data. It is also my focus to create a more fluent API for scraping and to address things like dynamic data through webviews and/or sites that require javascript to function.

* [Parser](#parser)

    The parser is what takes the raw data from the scraper and converts it into dart classes to be used. This also reinforces data cleaning and validation. One important thing it defines is [IDs](#ids) which are very important for making sure sources don't collide. Everything else is a subset for dealing with the data. There is currently only one defined structure for data which is designed for series that have chapters of images. More formats or source types are welcome to be implemented. This is the part of the project with the most room for exploration of what should be done. If you have any suggestions, create an issue for discussion. I would like this to also include implementations for various APIs so data can be standardized.

## Util

The util directory has vital code for how things interact with each other.

### Result

The most important part of the project is how data is moved between methods and functions. Result is a class that defines if data passes or fails which indicated if data can be trusted. This is used in place of exception for this project due to catches having very bad performance. This also enforces a practice of checking if the data is valid.

The data type annotation for the result can be set like so:

```
void Result<String> someFunction() { return Result.error() };
```

The result class has two attributes:

* `ResultStatus status`

    The `Result` class only has two constructors that sets the `status` to either `ResultStatus.pass` or `ResultStatus.fail`. You should check what the status is by calling the '.pass' or '.fail' getters on the `Result` class.

* `T? data`

    T is the type annotation set by the dev. With the `?`, data will always be nullable while the type annotation can be non-nullable, but checking status is how to avoid any unintentional nulls.

```
Result<String>.pass('valid'); //valid
Result<String>.pass(null); //invalid
Result<String?>.pass('valid'); //valid
Result<String?>.pass(null); //valid
Result<String>.fail(); //valid
```

Note that the `pass` constructor type will always reflect the type annotation while data will always be nullable.

The following is the best way to check for if a result has passed or failed. This avoids the need to keep checking if `status` equals a specific `ResultStatus` enum.

```
Result<String>.pass('valid').pass; //returns true
Result<String>.pass('valid').fail; //returns false
Result<String>.fail().pass; //returns false
Result<String>.fail().fail; //retuns true
```

```
Result<String> result = Result<String>.pass('valid');
if (result.pass) {
    result.data!; //use ! so dart knows that this is null-safe
}
```

If the result is passing, then the data can be trusted and will be the expected type. No need to worry about it being null unless it has been specificed in the intial type annotation.



## Scraper

WIP

## Parser

### IDs

The core of any content is how they are identified. This project uses an id/source system to create unique ids. The id and source are both strings. An ID can be created through the folloing:

```
ID(id: '', source: '');
```

IDs should contain all the information a source needs to retrieve any relevant information. Extra data can be embedded into the id string to allow finding the item again. IDs compare and use a unqiue string called `uid`. `uid` is built from combining `source` and `id` with a colon inbetween. Example:

```
ID id1 = ID(id: 'uniqueid', source: 'test');
ID id2 = ID(id: 'uniqueid', source: 'test');
assert(id1.uid == 'test:uniqueid');
assert(id1 == id2);
```

This format makes ids readable even when stored by their uid. Sources should also not have their names(`source` property) with colons in them. This allows for extracting the `source` and `id` based on the location of the first colon. `uid` can also be passed as a parameter to set the uid for the id. Being able to set the uid can allow invalid values for the given ID, but it is there for data conversions and reducing the amount of string operations.

IDs are tied to all information returned.

### ChapterIDs

The next step to content is the subset of information that can exist. ChapterIDs core idea for identification can be applied to other content. It directly holds an ID object but with an added index and url for the content it points to. It currently uses its index for uniqness.

```
ChapterID(id: ID(id: '', source: ''), index: 0, url: '')
```

This also uses a uid like IDs but with an added value added to the end. It adds the index to the end of the uid with a colon so it follows the format of 'source:id:index'. This means all info can also be extracted from the uid since it can go off the first and last occurance of the colon with the id being any value.

When using the fromJson() constructor, the ID can be passed as a map or an object.