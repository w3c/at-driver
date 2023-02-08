# ARIA-AT Automation API Explainer

**aria-at-automation** &middot; [aria-at-automation-harness](https://github.com/w3c/aria-at-automation-harness) &middot; [aria-at-automation-driver](https://github.com/w3c/aria-at-automation-driver) &middot; [aria-at-automation-results-viewer](https://github.com/w3c/aria-at-automation-results-viewer)

## Authors

* Mike Pennisi
* Simon Pieters


## Overview

[The WebDriver protocol](https://w3c.github.io/webdriver/#extensions-0) is a [W3C](https://www.w3.org/) standard created for automating web browsers. The goal of [the ARIA-AT project](https://aria-at.w3.org/) is to enable the automation of screen readers and web browsers, and for that purpose, WebDriver is insufficient.

We review the needs of the ARIA-AT project’s automated tests through the lens of the WebDriver protocol. We identify which needs are already met by WebDriver and which needs require new infrastructure. Finally, we outline alternative proposals that we have considered.


## Motivating Use Cases

* It is difficult for web developers to know whether a particular design pattern or web platform feature is supported by all of the accessibility stack (browser, operating system, screen reader) without manually testing.
* It is difficult for screen reader implementers to compare their product’s compliance to web standards to their competitors’ products without manually testing.


## Goals

* Automate testing of screen reader + web browser combinations.
    * Ability to start and quit the screen reader.
    * Ability to start and quit the web browser.
    * Ability to change settings in the screen reader in a robust way.
    * Ability to access the spoken output of the screen reader.
    * Ability to access the internal state of the screen reader, e.g. virtual focus position, mode (interaction mode vs. reading mode).
* A common API shared by all screen readers.
* Do not duplicate functionality where WebDriver is already suitable.


## Requirements

The future ARIA-AT tests will need to trigger specific behaviors in web browsers and screen readers. This section enumerates all such behaviors and differentiates those which are already possible today from those which will require non-trivial development effort.


### Start browser (already possible today)

ARIA-AT tests will need to create web browser instances before testing can begin.

The WebDriver protocol already provides this feature through [its "New Session" command](https://w3c.github.io/webdriver/#new-session).


### Visit web page (already possible today)

ARIA-AT tests will need to navigate web browser instances to documents designed to demonstrate accessibility behaviors.

The WebDriver protocol already provides this feature through [its "Navigate To" command](https://w3c.github.io/webdriver/#navigate-to).


### Quit browser (already possible today)

ARIA-AT tests will need to destroy web browser instances after testing is complete.

The WebDriver protocol already provides this feature through [its "Delete Session" command](https://w3c.github.io/webdriver/#delete-session).


### Configure screen reader

ARIA-AT tests will need to set initial conditions for the screen reader under test, e.g. instructing the screen reader to convey mode changes in speech instead of via sound files.

The WebDriver protocol already provides a mechanism for altering characteristics of the testing session via [its "Capabilities" mechanism](https://w3c.github.io/webdriver/#capabilities), but screen reader settings are not included in the set of capabilities.


### Press keyboard keys

ARIA-AT tests will need to simulate keyboard key presses which can be received by a screen reader.

Although the WebDriver protocol already provides two commands for simulating key presses (["Element Send Keys"](https://w3c.github.io/webdriver/#element-send-keys) and ["Perform Actions"](https://w3c.github.io/webdriver/#dfn-perform-actions)), those commands are unsuitable for the purposes of ARIA-AT automation because they operate by simulating input within the web browser instance. The operating system and screen reader cannot observe keyboard interaction simulated using these commands.

### Inspect screen reader internal state

ARIA-AT tests will need to verify certain aspects of screen readers' status which are not directly observable by end users. The properties of interest have not yet been identified (nor have they been standardized across screen readers), but they may include, for instance, whether [so-called "modal" screen readers](https://github.com/w3c/aria-at/wiki/Screen-Reader-Terminology-Translation) are in "interaction mode" or "reading mode."

WebDriver currently does not provide a mechanism for retrieving this information.


### Observe spoken text

ARIA-AT tests will need to verify the correctness of the words that the screen reader vocalizes to the end user. The screen reader under test may attempt to vocalize at any moment (e.g. due to [ARIA live regions](https://www.w3.org/TR/wai-aria/#dfn-live-region) or due to screen reader implementation bugs), and this unique aspect warrants special consideration when evaluating potential paths forward.

WebDriver currently does not provide a mechanism for retrieving this information.


## Proposal: Specify a new service to compliment WebDriver

The required functionality which is _not_ available in WebDriver could be provided by a new service. In the immediate term, this service could be implemented as a standalone process, similar to the “WebDriver servers” which operate in parallel to the web browsers under test. In contrast to the alternatives described below, the software architecture would not necessarily be restricted by the design of the WebDriver standard, potentially reducing the overall complexity.

As the solution matures, it could become a part of the assistive technology itself, obviating the need for an additional process. In the longer term, developer ergonomics could be further improved by [extending the WebDriver standard](https://w3c.github.io/webdriver/#extensions-0) with commands to integrate with this new specification.

We feel this is the most promising direction for a standardization effort.


## Considered alternatives


### Extend WebDriver with desired functionality

The required functionality could be specified in terms of the WebDriver standard. Initially, [the WebDriver standard’s built-in extension mechanism](https://w3c.github.io/webdriver/#extensions-0) could be used to publish normative text that is adjacent to WebDriver. As the text matures and becomes implemented, it might be moved into the WebDriver standard itself.

We advise against proceeding in this direction because it extends the responsibilities of the WebDriver server in a way that the maintainers are unlikely to support. In addition to integrating with their respective web browser, implementations like [GeckoDriver](https://github.com/mozilla/geckodriver) and [ChromeDriver](https://chromedriver.chromium.org/) would need to integrate with every available screen reader.

A second hurdle to this approach concerns the state of the relevant standard. The particular needs of spoken text retrieval could not be met by the WebDriver standard in its current form. Standardizing this feature would require extending [the nascent bi-directional version of WebDriver](https://w3c.github.io/webdriver-bidi/). Since this version is more volatile than the traditional (that is, uni-directional) version, there is more risk in building on it.


### Extend one or more existing WebDriver servers

The required functionality could be built into an existing WebDriver server (e.g. [GeckoDriver](https://github.com/mozilla/geckodriver) or [ChromeDriver](https://chromedriver.chromium.org/)) using appropriate vendor prefixes. This would limit the number of subsystems involved, and like any reduction in complexity, it would help mitigate bugs.

We advise against proceeding in this direction because while we are interested in testing multiple browsers, integrating with multiple browsers directly (instead of building "on top" of multiple browsers) will increase the development effort required to achieve that goal. Further, none of the participants in this effort have the expertise necessary to rapidly implement a solution so tightly-coupled to the existing technology.


### Simulate OS-level key presses and intercept spoken output

At the OS-level (as opposed to the browser-level, as in WebDriver), simulate key presses to give actions for the screen reader and browser. Also at the OS-level, install a custom voice that intercepts the spoken output, and make that text available to the test runner so that it can compare actual output with expected output.

This is what we’re experimenting with currently at Bocoup. We believe this is a reasonable starting point because it allows us to start testing without changes to screen readers, but it’s not the ideal long-term solution because there are some limitations.

#### Pros

* Not blocked on screen readers implementing a new API to start testing.
* It should be possible to access everything that users can access (with a keyboard).

#### Cons

* Changing screen reader settings in this way is likely not going to be robust.
* No access to screen readers’ internal state.


## References

* [ARIA-AT](https://aria-at.w3.org/)
* [WebDriver](https://w3c.github.io/webdriver/)

---

### aria-at-automation

A collection of projects for automating assistive technology tests from [w3c/aria-at](https://github.com/w3c/aria-at) and beyond

**[aria-at-automation-harness](https://github.com/w3c/aria-at-automation-harness)**
A command-line utility for executing test plans from [w3c/aria-at](https://github.com/w3c/aria-at) without human intervention using [the aria-at-automation-driver](https://github.com/w3c/aria-at-automation-driver)

**[aria-at-automation-driver](https://github.com/w3c/aria-at-automation-driver)**
A WebSocket server which allows clients to observe the text enunciated by a screen reader and to simulate user input

**[aria-at-automation-results-viewer](https://github.com/w3c/aria-at-automation-results-viewer)**
A tool which translates the JSON-formatted data produced by the [aria-at-automation-harness](https://github.com/w3c/aria-at-automation-harness) into a human-readable form
