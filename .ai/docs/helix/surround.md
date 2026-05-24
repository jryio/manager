Surround

Helix includes built-in functionality similar to vim-surround. The keymappings have been inspired from vim-sandwich:

Surround demo
Key Sequence	Action
ms<char> (after selecting text)	Add surround characters to selection
mr<char_to_replace><new_char>	Replace the closest surround characters
md<char_to_delete>	Delete the closest surround characters

You can use counts to act on outer pairs.

Surround can also act on multiple selections. For example, to change every occurrence of (use) to [use]:

    % to select the whole file
    s to split the selections on a search term
    Input use and hit Enter
    mr([ to replace the parentheses with square brackets

Multiple characters are currently not supported, but planned for future release.