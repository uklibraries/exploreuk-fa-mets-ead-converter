# ExploreUK finding aid METS+EAD converter

This code demonstrates one potential mapping of METS and EAD to
an intermediate JSON format to be used as input for the
finding aid viewer
in
[ExploreUK](https://exploreuk.uky.edu) as developed by people at the
[University of Kentucky Libraries](https://libraries.uky.edu) (UKL).

## Usage

Once installed, run within working directory with `bundle exec ruby exe/process-mets-ead`.

```
Options:
  -e, --environment=<s>    Environment (prod or test) (default: test)
  -i, --id=<s>             Document to process (leave blank to process all)
  -l, --log=<s>            Error log
  -h, --help               Show this message
```

## Installation

Prerequisites:

* Ruby
* Bundler

Procedure:

* Check out a copy of the code, or `git pull` it up to date.
* Run `bundle install`.
* Copy `config/config.yml.example` to `config/config.yml` and edit to match local conditions. The `prod` and `test` sections refer to production and test ExploreUK and have consequences for some of the links in the output.
  - `search_url_prefix`: for production ExploreUK, this is `https://exploreuk.uky.edu`, although `https://exploreuk.uky.edu/catalog` will also work.
  - `dip_url_prefix`: for production ExploreUK, this is `https://exploreuk.uky.edu/dips`.
  - `dip_root`: (input) where is the Pairtree root for the web content storage node ("DIP store")?
  - `id_list`: where can a list of identifiers for finding aid objects be found?
  - `json_root`: (output) where is the Pairtree root for the JSON intermediate output storage node?

## Restrictions on use

This package is primarily intended for use by UKL employees. 
We license it under the MIT license. See LICENSE.txt for details.

## Who built this

This was originally written by MLE Slone.
