# lang_01

custom interpreted language based on [odin](https://odin-lang.org), isnt one to one but very similar

## example
```odin

fmt         :: @import "core:fmt"
custom_file :: @import "../lang/custom_file.lang"

main :: proc()
{
  fmt->println( "hello world" )
  
  x := 123 // auto casts to int
  x = x +2 * 3
  b := procedure( x )

  fmt->println( "b:", b )

  custom_file->custom_proc()
}

procedure :: proc( a: int ) -> bool
{
  ret : bool    // defaults to false
  if a == 129
  {
    return true
  }
  else
  {
    return false
  }
}
```

## todo
  - [ ] figure out name
    - muh
    - joy / joi 
    - bry / berry
    - alfodr ( meaning: all-father, different name for odin )
    - ygg / yggr ( meaning: terrible one, different name for odin )
    - vak / vakr ( meaning: wakeful, awakener, different name for odin )
  - [ ] lexer (make tokens)
  - [ ] parser (make ast)
  - [ ] make intermediary format
  - [ ] make runtime interpreter for intermediary format

