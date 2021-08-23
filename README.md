[![Build](https://github.com/Wetbikeboy2500/web_content_parser/actions/workflows/build.yml/badge.svg)](https://github.com/Wetbikeboy2500/web_content_parser/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/Wetbikeboy2500/web_content_parser/branch/main/graph/badge.svg?token=I49J6Q80WP)](https://codecov.io/gh/Wetbikeboy2500/web_content_parser)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# Web Content Parser
One goal: unify web content parsing between dart projects.

This will not support downloading of any content. This simply acts as the interface.

## Focus
Building a versitile system for many different types of content. This includes providing easy integration into other systems and architectures. I also want to explore using headless browsers for more dynamic content that requires scripts and other things to run first.

## Design

This project can be thought of in three different code bases based on directory inside src.

* [Util](#util)

    This has most of the utilty classes and important enums that work for moving data around. It is the core for making sure calls can be made, defining expections, and wrapping responses with easy to integrate classes. Most things are shared between the scraper and parser sections.

* [Scraper](#scraper)

    This handles custom sources which are written in [hetu-script](https://github.com/hetu-script/hetu-script). It is used to return raw data to the parser to be formatted in a known format. This is flexible and can be used without the parser part of the project to do web scraping while staying away from predefined data structures. It is desinged this way to allow developers to completely ignore the opinionated nature of how this project process and builds data. It is also my focus to create a more fluent API for scraping and to address things like dynamic data through webviews and/or sites that require javascript to function.

* [Parser](#parser)

    The parser is what takes the raw data from the scraper and converts it into dart classes to be used. This also reinforces data cleaning and validation. One important thing it defines is [IDs](#ids) which are very important for making sure sources don't collide. Everything else is a subset for dealing with the data. There is currently only one defined structure for data which is designed for series that have chapters of images. More formats or source types are welcome to be implemented. This is the part of the project with the most room for exploration of what should be done. If you have any suggestions, create an issue for discussion. I would like this to also include implementations for various APIs so data can be standardized.

## Util

WIP

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
The next step to content is the subset of information that can exist.

WIP