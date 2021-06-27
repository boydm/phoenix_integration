# Changelog

## 0.9.2
  * Supports phoenix_html 3.0. Thank you @hzeus and @ZombieHarvester
  * :jason and :floki warnings resolved by making them dependent applications @ZombieHarvester
  * Improve regex matching. @adz
  * Added the Apache 2.0 license

## v0.9.1 - 2021-06-15
  * Loosen name identification to allow form field names with characters like ? in them. Thank you @arnodirlam

## v0.9.0 - 2021-04-26
  * Fixs bug in refute_response. Thank you @StanisLove
  * update flow_assertions. Thank you @marick
  * now requires Elixir 1.10+ bumping to 0.9.0 accordingly

## v0.8.2 - 2020-04-29
  * Fixes issue #39. Nice improvements to fetch_form. Thank you @marick
  * Fix issue #41. Support phoenix 1.5 which deprecated "use Phoenix.ConnTest" in favor of "import Phoenix.ConnTest"

## v0.8.1 - 2020-02-25
  * Fixes issue #36, correctly handle other form input types. Thank you @marick for the fix.

## v0.8.0 - 2020-02-17
  * Fairly large update to handle forms with hidden fields. This update treats forms as parsed
    trees and has more informative output, and is generally more flexible. This entire update
    is brought to you by the hard work of Brian Marick (@marick on GitHub). Thank you!

## v0.7.0 - 2020-01-29
  * __Marking this as 0.7.0 because it is requires a minor version update to Floki. Otherwise
    the actual changes in phoenix_markdown are more patch-like...__
  * Changed a private functions "is_struct" to "do_is_struct" to avoid a conflict with
    the new Kernel.is_struct function in Elixir v1.10
  * Change the minimum required version of Floki to 0.24.0 and then use the new
    Floki.parse_document pattern to get rid of the deprecation warnings.
  * add .formatter.exs and format the code

## v0.6.0 - 2018-12-18
  * Moved from Poison to Jason for json parsing

## v0.5.3 - 2018-07-30
  * Merged pull request #23 from jonasschmidt to support deeply nested forms.
  * Add Travis tests for elixir 1.7

## v0.5.2 - 2018-06-11
  * Merged pull request #22 from wooga to allow single-character input names in forms

## v0.5.1 - 2018-02-01
  * fixed bug (issue #20) where it didn't find radio input fields if none were intially checked
  * removed dependency on DeepMerge

## v0.5.0 - 2018-01-16
  * added Request.click_button to find and click simple buttons on the page
  * added Request.follow_button to find, click, and follow simple buttons on the page
  * improved error message when usinga link, while asking for the wrong method.

## v0.4.1 - 2018-01-17
  * run the code through the elixir 1.6 formatter
  * update travis tests

## v0.4.0 - 2018-01-16
  * fix issue #11, was incorrectly reading the method of the form in the case of a get
  * add the fetch_form function to the Request module
  * support for nested forms. Thank you https://github.com/bitboxer
  * support follow_link for phoenix_html 2.10. Thank you https://github.com/andreapavoni
  * bump up to Elixir 1.4
  * update docs

## v0.3.0 - 2017-07-04
  * added a new :value assertion type that checks the result of a callback for truthyness
  * relaxed requirement on floki version

## v0.2.0 - 2017-01-07
  * Updated Dependencies to use version 0.13 of Floki (the html parsing enging)
  * Use updated Floki syntax when searching for links and forms by text content.
  * Errors while running a form test now display the path that was associated with the form.
    should aid in resolving issues on pages with more than one form.
    Thank you goes to https://github.com/Mbuckley0 for sorting this out.
  * Change the readme to suggest only loading phoenix_integration in test mode
  * Added support for DateTime fields in forms. Again thank you https://github.com/Mbuckley0
    for adding this feature in.

## v0.1.2 - 2016-10-03
  * Add support for file upload fields in forms

## v0.1.1 - 2016-08-13
  * Added `:assigns` option to both `Assertions.assert_response` and `Assertions.refute_response`.
  * Added `Requests.follow_fn`
  * cleaning up readme and docs

## v0.1.0 - 2016-07-28
  * First release
