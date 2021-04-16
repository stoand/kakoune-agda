# http://agda.org
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](agda) %{
    set-option buffer filetype agda
    
    set-option buffer comment_line '--'

	# Mixing tabs and spaces will break
	# indentation sensitive syntax checking
    hook buffer InsertChar \t %{ try %{
      execute-keys -draft "h<a-h><a-k>\A\h+\z<ret><a-;>;%opt{indentwidth}@"
    }}

    hook buffer InsertDelete ' ' %{ try %{
      execute-keys -draft 'h<a-h><a-k>\A\h+\z<ret>i<space><esc><lt>'
    }}
}


# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/agda regions
add-highlighter shared/agda/code default-region group
add-highlighter shared/agda/string       region (?<!'\\)(?<!')"                 (?<!\\)(\\\\)*"  fill string
add-highlighter shared/agda/macro        region ^\h*?\K#                        (?<!\\)\n        fill meta
add-highlighter shared/agda/pragma       region -recurse \{- \{-#               '#-\}'           fill meta
add-highlighter shared/agda/comment      region -recurse \{- \{-                  -\}            fill comment
add-highlighter shared/agda/line_comment region --(?:[^!#$%&*+./<>?@\\\^|~=]|$) $                fill comment
add-highlighter shared/agda/line_comment2 region \|\|\|(?:[^!#$%&*+./<>?@\\\^|~=]|$) $           fill comment

add-highlighter shared/agda/code/ regex (?<!')\b0x+[A-Fa-f0-9]+ 0:value
add-highlighter shared/agda/code/ regex (?<!')\b\d+([.]\d+)? 0:value

add-highlighter shared/agda/code/ regex (?<!')\b(abstract|data|hiding|import|as|infix|infixl|infixr|module|mutual|open|primitive|private|public|record|renaming|rewrite|using|where|with|field|constructor|instance|syntax|pattern|inductive|coinductive)(?!')\b 0:keyword
add-highlighter shared/agda/code/ regex (?<!')\b(postulate|codata|let|in|forall)\b 0:keyword

# Idris Tactic - TODO: restrict tactic keywords to their context
add-highlighter shared/agda/code/ regex (?<!')\b(intros|rewrite|exact|refine|trivial|let|focus|try|compute|solve|attack|reflect|fill|applyTactic)(?!')\b 0:keyword

# The complications below is because period has many uses:
# As function composition operator (possibly without spaces) like "." and "f.g"
# Hierarchical modules like "Data.Maybe"
# Qualified imports like "Data.Maybe.Just", "Data.Maybe.maybe", "Control.Applicative.<$>"
# Quantifier separator in "forall a . [a] -> [a]"
# Enum comprehensions like "[1..]" and "[a..b]" (making ".." and "Module..." illegal)

# matches uppercase identifiers:  Monad Control.Monad
# not non-space separated dot:    Just.const
add-highlighter shared/agda/code/ regex \b([A-Z]['\w]*\.)*[A-Z]['\w]*(?!['\w])(?![.a-z]) 0:variable

# matches infix identifier: `mod` `Apa._T'M`
add-highlighter shared/agda/code/ regex `\b([A-Z]['\w]*\.)*[\w]['\w]*` 0:operator
# matches imported operators: M.! M.. Control.Monad.>>
# not operator keywords:      M... M.->
add-highlighter shared/agda/code/ regex \b[A-Z]['\w]*\.[~<=>|:!?/.@$*&#%+\^\-\\]+ 0:operator
# matches dot: .
# not possibly incomplete import:  a.
# not other operators:             !. .!
add-highlighter shared/agda/code/ regex (?<![\w~<=>|:!?/.@$*&#%+\^\-\\])\.(?![~<=>|:!?/.@$*&#%+\^\-\\]) 0:operator
# matches other operators: ... > < <= ^ <*> <$> etc
# not dot: .
# not operator keywords:  @ .. -> :: ~
add-highlighter shared/agda/code/ regex (?<![~<=>|:!?/.@$*&#%+\^\-\\])[~<=>|:!?/.@$*&#%+\^\-\\]+ 0:operator

# matches operator keywords: @ ->
add-highlighter shared/agda/code/ regex (?<![~<=>|:!?/.@$*&#%+\^\-\\])(@|~|<-|->|=>|::|=|:|[|])(?![~<=>|:!?/.@$*&#%+\^\-\\]) 1:keyword
# matches: forall [..variables..] .
# not the variables
add-highlighter shared/agda/code/ regex \b(forall)\b[^.\n]*?(\.) 1:keyword 2:keyword

# matches 'x' '\\' '\'' '\n' '\0'
# not incomplete literals: '\'
# not valid identifiers:   w' _'
add-highlighter shared/agda/code/ regex \B'([^\\]|[\\]['"\w\d\\])' 0:string
# this has to come after operators so '-' etc is correct

# Commands
# ‾‾‾‾‾‾‾‾

# http://en.wikibooks.org/wiki/Haskell/Indentation

define-command -hidden agda-trim-indent %{
    # remove trailing white spaces
    try %{ execute-keys -draft -itersel <a-x> s \h+$ <ret> d }
}

define-command -hidden agda-indent-on-new-line %{
    evaluate-commands -draft -itersel %{
        # copy -- comments prefix and following white spaces
        try %{ execute-keys -draft k <a-x> s ^\h*\K--\h* <ret> y gh j P }
        # preserve previous line indent
        try %{ execute-keys -draft \; K <a-&> }
        # align to first clause
        try %{ execute-keys -draft \; k x X s ^\h*(if|then|else)?\h*(([\w']+\h+)+=)?\h*(case\h+[\w']+\h+of|do|let|where)\h+\K.* <ret> s \A|.\z <ret> & }
        # filter previous line
        try %{ execute-keys -draft k : agda-trim-indent <ret> }
        # indent after lines beginning with condition or ending with expression or =(
        try %{ execute-keys -draft \; k x <a-k> ^\h*(if)|(case\h+[\w']+\h+of|do|let|where|[=(])$ <ret> j <a-gt> }
    }
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group agda-highlight global WinSetOption filetype=agda %{
    add-highlighter window/agda ref agda
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/agda }
}

hook global WinSetOption filetype=agda %{
    set-option window extra_word_chars '_' "'"
    hook window ModeChange insert:.* -group agda-trim-indent  agda-trim-indent
    hook window InsertChar \n -group agda-indent agda-indent-on-new-line

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window agda-.+ }
}
