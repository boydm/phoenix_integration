## phoenix_integration Changelist

### 0.4.0
  * add the fetch_form function to the Request module
  * support for nested forms. Thank you https://github.com/bitboxer
  * support follow_link for phoenix_html 2.10. Thank you https://github.com/andreapavoni
  * bump up to Elixir 1.4
  * update docs

### 0.3.0
  * added a new :value assertion type that checks the result of a callback for truthyness
  * relaxed requirement on floki version

### 0.2.0
  * Updated Dependencies to use version 0.13 of Floki (the html parsing enging)
  * Use updated Floki syntax when searching for links and forms by text content.
  * Errors while running a form test now display the path that was associated with the form.
    should aid in resolving issues on pages with more than one form.
    Thank you goes to https://github.com/Mbuckley0 for sorting this out.
  * Change the readme to suggest only loading phoenix_integration in test mode
  * Added support for DateTime fields in forms. Again thank you https://github.com/Mbuckley0
    for adding this feature in.

### 0.1.2
  * Add support for file upload fields in forms

### 0.1.1
  * Added `:assigns` option to both `Assertions.assert_response` and `Assertions.refute_response`.
  * Added `Requests.follow_fn`
  * cleaning up readme and docs

### 0.1.0
  First release