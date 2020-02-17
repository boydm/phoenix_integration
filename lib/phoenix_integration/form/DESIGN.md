This code is about the inner workings of this:

        submit_form(form, %{ animal: %{
            name: "Bossie",
            species_id: 1
          }})

It converts a form produced by
[Floki](https://hexdocs.pm/floki/Floki.html) into a map from atoms to
values, one that can be submitted to a Phoenix controller via the usual
ConnTest methods (like `post`):

        post(conn, Route.some_path, %{animal: %{name: "Bossie"}...})

There are three steps:

#### Tree creation ([tree_creation.ex](./tree_creation.ex))

The Floki input contains a sequence of parsed HTML tags. Each of those
is turned into a `Tag` struct ([tag.ex](./tag.ex)). That contains the
relevant attributes of the tag, most importantly the `name` and
`values`. (The `values` field is an empty list for a tag that has no
value, a singleton list for an ordinary tag, or an arbitrary list for
a `Tag` that can produce multiple values - see below for that.)

A `Tag` also contains a `path` derived from the implicit nesting
within the `name`. For example, `name="animal[species_id]"` has a path
of `[:animal, :species_id]`. 

The tree creation step assembles a sequence of `Tag` values into a
tree whose interior nodes are `:path` atoms and whose leaves are
`Tags`. This involves some processing beyond just creating a tree
because there can be relationships between HTML tags with the same
`name`. Two are most important: 

* Tags whose shared name ends in `[]`, like this:

        <input type="checkbox" name="reservation[chosen_ids][]" value="1"/>
        <input type="checkbox" name="reservation[chosen_ids][]" value="2"/>
        <input type="checkbox" name="reservation[chosen_ids][]" value="3"/>
        
  ... are merged into a single `Tag` with the path
  `[:reservation, :chosen_ids]` and marked `has_list_value: true`.

* HTML checkboxes do not by themselves ever return a "false" value.
  The appearance that they do is kludged with a `type="hidden"` tag:
  
        <input type="hidden"   name="some[boolean]" value="false"/>
        <input type="checkbox" name="some[boolean]" value="true" ... />

  The two are merged into a single `Tag`. If the `"checkbox"` tag has
  a `checked` attribute, the `Tag`'s value is `"true"`; otherwise it's
  `"false"`.

#### Tree editing ([tree_edit.ex](./tree_edit.ex))

This phase updates the `Tag` tree, directed by a tree of values like this:

    %{animal: %{
        name: "Bossie",
        species_id: 1
     }}
     
The tree is first converted into a sequence of `Change`
([change.ex](./change.ex)) structs that contain both a `path` and a
`value`. Then each `Change` is processed in turn to (possibly) update
the `values` field of a `Tag` with the same path.

Note that this approach has worse "big-O" performance than a single
pass that descends both trees at once[[fn1]](#fn1), but it means this
module works the same way as the previous one, it makes error
reporting more convenient, and it's not like we're talking about big
trees here.

Speaking of error handling, various errors are reported. Most common
will be trying to `Change` a value with no corresponding `Tag`. The
reporting is done by the `Messages` module
([messages.ex](./messages.ex)), which also handles warnings produced
in the tree-creation step. The warnings are for HTML that almost
certainly doesn't do what its author wanted, such as having two
`"text"` inputs with the same `name` that does *not* end in `[]`. (In
normal Phoenix use, the controller action will never see the first
input's value.)[[fn2]](#fn2)

When the tree contains a struct like `Date` or `Plug.Upload`, the
`Change`-creation step descends into the struct just like it would a
regular map. However, the resulting `Change` values are marked so that
no error is reported if they don't correspond to a `path` in the `Tag`
tree. That is, it's fine if a form has only a
`name="top_level[date][day]"` tag and doesn't use the other fields of
a `Date` that supplies its value.

#### Finishing the tree ([tree_finish.ex](./tree_finish.ex))

The last step descends the tree and just replaces the `Tags` with list
or non-list values, as appropriate. *Except*...

* Non-list leaves with no value are deleted. For example, consider
  radio buttons like this:
  
        <input name="user[role]" type="radio" value="admin">
        <input name="user[role]" type="radio" value="user">
        
  Were the real form to be submitted, it would contain nothing about
  the name `"user[role]"`. Therefore, it would be incorrect for the
  tree given to `ConnTest.post` to produce a HTTP post string like
  `"...&user[role]=&..."`. Deleting empty `values` prevents that. 

* List leaves with an empty (`[]`) value are also deleted. That's the
  behavior HTML has with, for example, a `select` tag where nothing is
  checked. Like this:
  
          <select multiple="" name="animals[stats][roles][]">
            <option value="1">Admin</option>
            <option value="2">Power User</option>
          </select>

Related to the above, we have to avoid cases where the finished tree
looks like this:

     %{animals:
        %{name: "Bossie",
          subtree: %{}}}

There's no form that could deliver values that would result in an
empty map being given to the controller action. So such key-value
pairs are pruned, leaving this:

     %{animals:
        %{name: "Bossie"}}


-------------------
##### [[fn1]](#fn1)

`O(width-of-tree * depth-of-tree)` vs. something like `O(width-of-tree + depth-of-tree)`, though I haven't thought about it much.

##### [[fn2]](#fn2)

Tree-creation warnings will throw away information
from conflicting nodes. That might not be the same information Phoenix
would lose if the original form were submitted. For example, if a form
has both a `name="animal[traits]"` and a `name="animal[traits][]"`,
Phoenix might give the second one precedence while this code gives the
first.
