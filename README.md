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

  arg_0 : f32 = 0.5
  custom_file->custom_proc( &arg_0 )  // @UNSURE: have pointers ???
}

procedure :: proc( a: int ) -> bool
{
  ret : bool    // defaults to false
  if a == 129
  {
    ret = true
  }
  else
  { ret = false }
  return ret
}
```

## todo
  - [ ] figure out name
    - muh
    - joy / joi 
    - bry / berry
    - alfodr ( meaning: all-father, different name for odin )
    - **ygg** / yggr ( meaning: terrible one, different name for odin )
      - no other meanings except maybe `You Go Girl`
      - **use this one**, bc meaning is fitting and no other meanings
    - **vak** / vakr ( meaning: wakeful, awakener, different name for odin )
      - vāk -> hindu goddess of speech
        - kinda still works but probably use `ygg` instead
      - is pronounced `fuck` [in afrikaans at least](https://en.wiktionary.org/wiki/vak) which is funny
  - [ ] lexer (make tokens)
  - [ ] parser (make ast)
  - [ ] make intermediary format
  - [ ] make runtime interpreter for intermediary format

