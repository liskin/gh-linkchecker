# GitHub Action: linkchecker

GitHub Action that checks links using
[LinkChecker](https://linkchecker.github.io/linkchecker/).

Features:

* [LinkChecker features](https://linkchecker.github.io/linkchecker/#features)
* retry failures
* output to GitHub as error/warning/notice annotations
* custom [jq](https://jqlang.github.io/jq/) filters that can be used to
  implement complex ignore rules that can't be expressed in linkcheckerrc,
  such as turning warnings or ignoring only temporary redirects but not
  permanent redirects

## Usage

### Basic Example - check external links and anchors of your GitHub Pages

```yaml
name: Check for broken links

on:
  workflow_dispatch:
  schedule:
    # Run every weekend
    - cron: '0 2 * * 6'

jobs:
  linkchecker:
    runs-on: ubuntu-latest
    steps:
      - uses: liskin/gh-linkchecker@v0.1.0
        with:
          retries: 3
          linkcheckerrc: |
            [filtering]
            checkextern=1
            [AnchorCheck]
```

### Advanced Example - tweak severity of redirects

```yaml
      - uses: liskin/gh-linkchecker@v0.1.0
        with:
          # …
          linkcheckerrc: |
            [filtering]
            checkextern=1
          custom-jq-filter-post: |
            def moved_permanently_to_error:
                if is_warning and (.warning | contains("status: 301 ")) then
                    to_error
                end;

            def moved_temporarily_to_info:
                if is_warning and (.warning | contains("status: 302 ")) then
                    to_info
                end;

            map(
                moved_permanently_to_error |
                moved_temporarily_to_info
            )
```

Other examples of advanced custom jq filter usage:

* <https://github.com/liskin/work.lisk.in/blob/master/.github/workflows/linkchecker.yaml>

### Parameters

* `urls`
    * Space-separated list of URLs to crawl
    * (Default: GitHub Pages URL of the invoking repository)
* `linkcheckerrc`
    * Configuration file for LinkChecker
    * (Default: empty)
* `custom-jq-filter`
    * Custom jq filter/program that can be used to implement complex ignore
      rules that can't be expressed in linkcheckerrc.
      This filter is run after every linkchecker attempt, so using it to
      upgrade warnings to errors will cause retries.
    * Helper functions from [linkchecker.jq](linkchecker.jq) are available.
    * (Default: `.`)
* `custom-jq-filter-post`
    * Custom jq filter/program that can be used to implement complex ignore
      rules that can't be expressed in linkcheckerrc, such as turning warnings
      into errors or ignoring only temporary redirects but not permanent
      redirects.
      This filter is run after a successful (no errors) linkchecker attempt.
    * Helper functions from [linkchecker.jq](linkchecker.jq) are available.
    * (Default: `.`)
* `retries`
    * Maximum number of retries (if there are any errors)
    * (Default: 1)
