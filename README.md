# AT Driver API Explainer

**at-driver** &middot; [aria-at-automation-harness](https://github.com/w3c/aria-at-automation-harness) &middot; [aria-at-automation-driver](https://github.com/w3c/aria-at-automation-driver) &middot; [aria-at-automation-results-viewer](https://github.com/w3c/aria-at-automation-results-viewer)

## Overview

[The WebDriver protocol](https://w3c.github.io/webdriver/#extensions-0) is a [W3C](https://www.w3.org/) standard created for automating web browsers. The goal of [the ARIA-AT project](https://aria-at.w3.org/) is to enable the automation of screen readers and web browsers, and for that purpose, WebDriver is insufficient.

We review the needs of the ARIA-AT project’s automated tests through the lens of the WebDriver protocol. We identify which needs are already met by WebDriver and which needs require new infrastructure. Finally, we outline alternative proposals that we have considered.


## Motivating Use Cases

* It is difficult for web developers to know whether a particular design pattern or web platform feature is supported by all of the accessibility stack (browser, operating system, screen reader) without manually testing.
* It is difficult for screen reader implementers to compare their product’s compliance to web standards to their competitors’ products without manually testing.


## Goals

* Enable automation of screen reader and web browser combinations.
    * Ability to start and quit the screen reader.
    * Ability to change settings in the screen reader in a robust way.
    * Ability to access the spoken output of the screen reader.
    * Ability to access the internal state of the screen reader, e.g. virtual focus position, mode (interaction mode vs. reading mode).
* Define an API that can be consistently implemented by all screen readers.
* Enable open experimentation across a large set of platforms and by a diverse group of consumers.
* Do not duplicate functionality where WebDriver is already suitable.


## Requirements

Web developers will need to trigger specific behaviors in web browsers and screen readers. This section enumerates a minimal set of such behaviors. It differentiates the features which are already available through standard interfaces (as of 2023) from those which can only be accessed through proprietary interfaces (if at all).


### Start browser (already possible today)

Web developers will need to create web browser instances before testing can begin.

The WebDriver protocol already provides this feature through [its "New Session" command](https://w3c.github.io/webdriver/#new-session).


### Visit web page (already possible today)

Web developers will need to navigate web browser instances to documents designed to demonstrate accessibility behaviors.

The WebDriver protocol already provides this feature through [its "Navigate To" command](https://w3c.github.io/webdriver/#navigate-to).


### Quit browser (already possible today)

Web developers will need to destroy web browser instances after testing is complete.

The WebDriver protocol already provides this feature through [its "Delete Session" command](https://w3c.github.io/webdriver/#delete-session).


### Configure screen reader

Web developers will need to set initial conditions for the screen reader under test, e.g. instructing the screen reader to convey mode changes in speech instead of via sound files.

The WebDriver protocol already provides a mechanism for altering characteristics of the testing session via [its "Capabilities" mechanism](https://w3c.github.io/webdriver/#capabilities), but screen reader settings are not included in the set of capabilities.


### Press keyboard keys

Web developers will need to simulate keyboard key presses which can be received by a screen reader.

Although the WebDriver protocol already provides two commands for simulating key presses (["Element Send Keys"](https://w3c.github.io/webdriver/#element-send-keys) and ["Perform Actions"](https://w3c.github.io/webdriver/#dfn-perform-actions)), those commands are unsuitable for the purposes of AT Driver because they operate by simulating input within the web browser instance. The operating system and screen reader cannot observe keyboard interaction simulated using these commands.

### Inspect screen reader internal state

Web developers will need to verify certain aspects of screen readers' status which are not directly observable by end users. The properties of interest have not yet been identified (nor have they been standardized across screen readers), but they may include, for instance, whether [so-called "modal" screen readers](https://github.com/w3c/aria-at/wiki/Screen-Reader-Terminology-Translation) are in "interaction mode" or "reading mode."

WebDriver currently does not provide a mechanism for retrieving this information.


### Observe spoken text

Web developers will need to verify the correctness of the words that the screen reader vocalizes to the end user. The screen reader under test may attempt to vocalize at any moment (e.g. due to [ARIA live regions](https://www.w3.org/TR/wai-aria/#dfn-live-region) or due to screen reader implementation bugs), and this unique aspect warrants special consideration when evaluating potential paths forward.

WebDriver currently does not provide a mechanism for retrieving this information.


## Proposal: Specify a new service to compliment WebDriver

The required functionality which is _not_ available in WebDriver could be provided by a new service. In the immediate term, this service could be implemented as a standalone process, similar to the “WebDriver servers” which operate in parallel to the web browsers under test. In contrast to the alternatives described below, the software architecture would not necessarily be restricted by the design of the WebDriver standard, potentially reducing the overall complexity.

As the solution matures, it could become a part of the assistive technology itself, obviating the need for an additional process. In the longer term, developer ergonomics could be further improved by [extending the WebDriver standard](https://w3c.github.io/webdriver/#extensions-0) with commands to integrate with this new specification.

We feel this is the most promising direction for a standardization effort.


## Considered alternatives


### Extend WebDriver with desired functionality

The required functionality could be specified in terms of the WebDriver standard. Initially, [the WebDriver standard’s built-in extension mechanism](https://w3c.github.io/webdriver/#extensions-0) could be used to publish normative text in a distinct document. As the text matures and becomes implemented, it might be moved into the WebDriver standard itself.

We have chosen not to proceed in this direction because it extends the responsibilities of the WebDriver server in a way that the maintainers are unlikely to support. In addition to integrating with their respective web browser, implementations like [GeckoDriver](https://github.com/mozilla/geckodriver) and [ChromeDriver](https://chromedriver.chromium.org/) would need to integrate with every available screen reader.

A second hurdle to this approach concerns the state of the relevant standard. The particular needs of spoken text retrieval could not be met by the WebDriver standard in its current form. Standardizing this feature would require extending [WebDriver BiDi, the bi-directional version of WebDriver](https://w3c.github.io/webdriver-bidi/). WebDriver BiDi is still being designed in 2023, making it a more volatile basis for extension.


### Extend one or more existing WebDriver servers

The required functionality could be built into an existing WebDriver server (e.g. [GeckoDriver](https://github.com/mozilla/geckodriver) or [ChromeDriver](https://chromedriver.chromium.org/)) using appropriate vendor prefixes. This would limit the number of subsystems involved, and like any reduction in complexity, it would help mitigate bugs.

We have chosen not to proceed in this direction because while we are interested in testing multiple browsers, integrating with multiple browsers directly (instead of building "on top" of multiple browsers) will increase the development effort required to achieve that goal. Further, none of the participants in this effort have the expertise necessary to rapidly implement a solution so tightly-coupled to the existing technology.


### Build a tool which integrates with operating systems to observe and control screen readers

Some of the required functionality could be provided by a tool that does not integrate with screen reader directly. Such a tool could give instructions to the screen reader by simulating keyboard key presses at the level of the operating system (OS). Also at the OS-level, the tool could implement a text-to-speech "voice" which exposes the vocalizations as a stream of textual data. A general audience could benefit from this work if the source code and documentation were published under a free-and-open-source-software license.

It is unclear whether some requirements (namely, configuring screen readers and observing their state) could be satisfied using this approach because there are no consistent operating-system-level facilities for these features. Even within the subset of required capabilities which can be realized via these means, the absence of a standard would undermine stability, and the commitment to a concrete implementation would limit adoption. While we recognize that this approach may yield helpful implementation experience in advance of consensus around a standard (see [the at-driver-driver project](https://github.com/w3c/at-driver-driver)), we recognize that it is fundamentally insufficient.


### Promote nascent standard for introspecting accessibility properties

[The Accessibility Object Model](https://wicg.github.io/aom/) is an effort whose goal is "to create a JavaScript API to allow developers to modify (and eventually explore) the accessibility tree for an HTML page." Developers empowered in this way could validate their code in terms of the data structure which the browser provides to the screen reader, giving them some confidence about the accessibility of their work.

We have chosen not to proceed in this direction because we believe developers would be well-served by being able to observe the complete user experience *alongside* the low-level accessibility primitives. Assistive technologies play a critical role in shaping user experience, and this proposal's "end-to-end" nature (which encompasses the assistive technology in addition to the developer's code and the web browser) will give developers insight into that experience. Also, because this proposal exposes information about the end-user's experience (rather than a diagnostic data structure), we expect more people will be able to participate in the design and maintenance of systems built on it.


## References

* [ARIA-AT](https://aria-at.w3.org/)
* [WebDriver](https://w3c.github.io/webdriver/)

---

### at-driver

A collection of projects for automating assistive technology tests from [w3c/aria-at](https://github.com/w3c/aria-at) and beyond

**[aria-at-automation-harness](https://github.com/w3c/aria-at-automation-harness)**
A command-line utility for executing test plans from [w3c/aria-at](https://github.com/w3c/aria-at) without human intervention using [the aria-at-automation-driver](https://github.com/w3c/aria-at-automation-driver)

**[aria-at-automation-driver](https://github.com/w3c/aria-at-automation-driver)**
A WebSocket server which allows clients to observe the text enunciated by a screen reader and to simulate user input

**[aria-at-automation-results-viewer](https://github.com/w3c/aria-at-automation-results-viewer)**
A tool which translates the JSON-formatted data produced by the [aria-at-automation-harness](https://github.com/w3c/aria-at-automation-harness) into a human-readable form
