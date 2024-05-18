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
    * (Required)
* `linkcheckerrc`
    * Configuration file for LinkChecker
    * (Default: empty)
* `retries`
    * Maximum number of retries (if there are any errors)
    * (Default: 1)
