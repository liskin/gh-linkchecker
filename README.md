# GitHub Action: linkchecker

GitHub Action that …

## Usage

```yaml
jobs:
  somejob:
    runs-on: ubuntu-latest
    steps:
      # …
      - uses: liskin/gh-linkchecker@v1
        with:
          urls: https://example.com/
          linkcheckerrc: |
            [filtering]
            checkextern=1
            # …
      # …
```

### Parameters

* `urls`
    * Space-separated list of URLs to crawl
    * (Default: GitHub Pages URL of the invoking repository)
* `linkcheckerrc`
    * Configuration file for LinkChecker
    * (Default: empty)
* `custom-jq-filter`
    * Custom jq filter/program that can be used to implement complex ignore
      rules that can't be expressed in linkcheckerrc, such as turning warnings
      into errors or ignoring only temporary redirects but not permanent
      redirects.
    * (Default: `.`)
* `retries`
    * Maximum number of retries (if there are any errors)
    * (Default: 1)
