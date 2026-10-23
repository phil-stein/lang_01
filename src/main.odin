package lang_01

import     "core:os"
import     "core:fmt"
import str "core:strings"
import     "core:text/match"
import     "core:strconv"
import     "core:unicode"
import     "core:terminal/ansi"
import     "core:debug/trace"

data_t :: struct
{
  src_path: string,
}
data := data_t{}

Error_Message_Type :: enum
{
  Debug,
  Info,
  Warning,
  Error,
}
RESET     :: ansi.CSI + ansi.RESET  + ansi.SGR
RED       :: ansi.CSI + ansi.FG_RED + ansi.SGR
UNDERLINE :: ansi.CSI + ansi.UNDERLINE + ansi.SGR
print_debug :: proc( tokens: []token_t, args: ..any, sep: string = " " )
{ print( .Debug, tokens, ..args, sep=sep ) }
print_info :: proc( tokens: []token_t, args: ..any, sep: string = " " )
{ print( .Info, tokens, ..args, sep=sep ) }
print_warning :: proc( tokens: []token_t, args: ..any, sep: string = " " )
{ print( .Warning, tokens, ..args, sep=sep ) }
print_error :: proc( tokens: []token_t, args: ..any, sep: string = " " )
{ print( .Error, tokens, ..args, sep=sep ) }
print :: proc( type: Error_Message_Type, tokens: []token_t, args: ..any, sep: string = " " )
{
  fmt.print( RED, "[ERROR] ", RESET, sep="" )
  fmt.println( ..args, sep=sep )

  bytes, err := os.read_entire_file_from_path( data.src_path, context.allocator )
  defer delete(bytes)
  if err != os.ERROR_NONE
  {
    fmt.println( "[ERROR] couldnt read file:", data.src_path )
    os.exit( 1 )
  }
  txt := string(bytes)

  for t in tokens
  {
    fmt.printfln( "       * %v | line: %v, col: %v-%v", t.type, t.line, t.col_start, t.col_end )
      
    line_nr := 0
    it := str.clone( txt, context.temp_allocator )
    for line in str.split_lines_iterator( &it ) 
    {
      line_nr += 1
      // fmt.printfln( "       -> %v %v", line_nr, line)
      if line_nr == t.line
      {
        // fmt.printfln( "       -> %v ", line)
        fmt.printf( "       ->  " )
        for c, ci in line
        {
          if ci >= t.col_start && ci < t.col_end
          {
            fmt.print( RED, UNDERLINE, c, RESET, sep="" )
          }
          else do fmt.print( c )
        }
        fmt.println()
        break
      }
    }
  }
}

main :: proc() 
{
  track: trace.Tracking_Allocator
  trace.tracking_allocator_init(&track, context.allocator)

	context.allocator = trace.tracking_allocator(&track)
	defer trace.tracking_allocator_destroy(&track)
	defer trace.tracking_allocator_print_results(&track)

	context.assertion_failure_proc = trace.assertion_failure_proc

  data.src_path = "lang/test.lang"
  bytes, err := os.read_entire_file_from_path( data.src_path, context.allocator )
  defer delete(bytes)
  if err != os.ERROR_NONE
  {
    fmt.println( "[ERROR] couldnt read file:", data.src_path )
    os.exit( 1 )
  }

  txt := string(bytes)
  tokens := lexer_tokenize_string( &txt )
  defer delete( tokens )
  for t in tokens
  {
    fmt.println( "  [TOKEN]:", t.type, ", val:", t.value, ", line:", t.line )
  }
  free_all( context.temp_allocator )

  asts := parser_generate_ast_tree_from_tokens( tokens )
  defer delete( asts )

  // @TODO: visalize ast tree
  
  free_all( context.temp_allocator )
}

Token_Type :: enum
{
  New_Line,
  Semicolon,
  Arrow_Right,
  Identifier,
  Number,
  Equals,
  Logic_Equals,
  Logic_Or,
  Logic_Less_Than,
  Logic_More_Than,
  Logic_Less_Than_Equals,
  Logic_More_Than_Equals,
  Assign_Equals,
  Assign,
  Assign_Static,
  Add,
  Subtract,
  Multiply,
  Divide,
}
token_value_u :: union 
{
  string,
  int,
  i64,
  u32,
  u64,
  f32,
  f64,
}
token_t :: struct
{
  line      : int,
  col_start : int,
  col_end   : int,

  type  : Token_Type,
  value : token_value_u, 
}

lexer_tokenize_string :: proc( txt: ^string, alloc:=context.allocator ) -> ( tokens: [dynamic]token_t )
{
  line_nr := 0
  for line in str.split_lines_iterator( txt ) 
  {
    line_nr += 1
    line_not_empty := false

    // for c, &i in line
    for i:=0; i < len(line); i+=1 
    {
      // comments
      if len(line) > i+1 && 
         line[i+0] == '/' &&
         line[i+1] == '/'
      {
        break  // skip comment go to next line
      }
      else if line[i+0] == '+'
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Add, value=nil } )
        line_not_empty = true
      }
      else if line[i+0] == '-'
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Subtract, value=nil } )
        line_not_empty = true
      }
      else if line[i+0] == '*'
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Multiply, value=nil } )
        line_not_empty = true
      }
      else if line[i+0] == '/'
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Divide, value=nil } )
        line_not_empty = true
      }
      else if line[i+0] == ';'
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Semicolon, value=nil } )
        line_not_empty = true
      }
      else if i+1 < len(line) && 
              line[i+0] == '=' &&
              line[i+1] == '=' 
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i+1, type=Token_Type.Logic_Equals, value=nil } )
        line_not_empty = true
        i += 1
      }
      else if line[i+0] == '='
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Equals, value=nil } )
        line_not_empty = true
      }
      else if i+1 < len(line) && 
              line[i+0] == ':' &&
              line[i+1] == '=' 
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i+1, type=Token_Type.Assign_Equals, value=nil } )
        line_not_empty = true
        i += 1
      }
      else if i+1 < len(line) && 
              line[i+0] == ':' &&
              line[i+1] == ':' 
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i+1, type=Token_Type.Assign_Static, value=nil } )
        line_not_empty = true
        i += 1
      }
      else if line[i+0] == ':'
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Assign, value=nil } )
        line_not_empty = true
      }
      else if i+1 < len(line) && 
              line[i+0] == '<' &&
              line[i+1] == '=' 
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i+1, type=Token_Type.Logic_Less_Than_Equals, value=nil } )
        line_not_empty = true
        i += 1
      }
      else if line[i+0] == '<'
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Logic_Less_Than, value=nil } )
        line_not_empty = true
      }
      else if i+1 < len(line) && 
              line[i+0] == '>' &&
              line[i+1] == '=' 
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i+1, type=Token_Type.Logic_More_Than_Equals, value=nil } )
        line_not_empty = true
        i += 1
      }
      else if line[i+0] == '>'
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i, type=Token_Type.Logic_More_Than, value=nil } )
        line_not_empty = true
      }
      else if i+1 < len(line) && 
              line[i+0] == '-' &&
              line[i+1] == '>' 
      {
        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=i+1, type=Token_Type.Arrow_Right, value=nil } )
        line_not_empty = true
        i += 1
      }
      else if match.is_alpha( rune(line[i+0]) )
      {
        end_ident := i

        for ; end_ident < len(line); end_ident += 1
        {
          if !match.is_alnum( rune(line[end_ident]) )
          {
            break
          }
        }
        ident := line[i:end_ident]
        fmt.println( "[IDENTIFIER]:", ident )

        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=end_ident, type=Token_Type.Identifier, value=str.clone(ident, alloc) } )
        line_not_empty = true
        i = end_ident
      }
      else if unicode.is_number( rune(line[i+0]) )
      {
        end_num := i
        for ; end_num < len(line); end_num += 1
        {
          if !unicode.is_number( rune(line[end_num]) )
          {
            break
          }
        }
        num_str := line[i:end_num]
        num, ok := strconv.parse_int( num_str )
        if !ok { fmt.println( "[ERROR] parsing int:", num_str ); continue }
        fmt.println( "[NUMBER]:", num )

        append( &tokens, token_t{ line=line_nr, col_start=i, col_end=end_num, type=Token_Type.Number, value=num } )
        line_not_empty = true
        i = end_num
      }
    }
    if line_not_empty do append( &tokens, token_t{ line=line_nr, col_start=len(line), col_end=len(line), type=Token_Type.New_Line, value=nil } )
  }

  return tokens
}

ast_t :: struct
{
  // left:  ^ast_t,
  // right: ^ast_t,
  left:  int, // index into `asts` 
  right: int, // index into `asts`

  value: token_t,
}

parser_generate_ast_tree_from_tokens :: proc( tokens: [dynamic]token_t ) -> ( asts: [dynamic]ast_t )
{
  ast_arr := make( [dynamic]ast_t, 0 )
  parser_parse_expression( tokens, 0, &ast_arr )
  append( &asts, ..ast_arr[:] )
  delete( ast_arr )
  return asts
}
parser_parse_expression :: proc( tokens: [dynamic]token_t, offs: int, asts: ^[dynamic]ast_t ) -> ( node_idx: int )
{
  switch tokens[offs].type
  {
    case .Arrow_Right:              fallthrough
    case .Add:                      fallthrough
    case .Subtract:                 fallthrough
    case .Multiply:                 fallthrough
    case .Divide:                   fallthrough
    case .Equals:                   fallthrough
    case .Logic_Equals:             fallthrough
    case .Logic_Or:                 fallthrough
    case .Logic_Less_Than:          fallthrough
    case .Logic_More_Than:          fallthrough
    case .Logic_Less_Than_Equals:   fallthrough
    case .Logic_More_Than_Equals:   fallthrough
    case .Assign_Equals:            fallthrough
    case .Assign:                   fallthrough
    case .Assign_Static:            
    {
      // fmt.println( "[ERROR] binary operator at start of expression:", tokens[offs].type )
      // binary operator
      ast_idx := append( asts, ast_t{ value=tokens[offs] } )
      return ast_idx 
    }
    case .Semicolon: fallthrough
    case .New_Line:
    {
      // fmt.println( "[ERROR] new line at start of expression:", tokens[offs].type )
      return -1
    }
    case .Number:   fallthrough
    case .Identifier:
    {
      ast_idx_l := append( asts, ast_t{ value=tokens[offs] } )
      // ast_idx_02 := parser_parse_expression( tokens, offs+1, asts )

      if offs+1 >= len(tokens)
      {
        return ast_idx_l
      }

      switch tokens[offs +1].type
      {
        case .Arrow_Right:              fallthrough
        case .Add:                      fallthrough
        case .Subtract:                 fallthrough
        case .Multiply:                 fallthrough
        case .Divide:                   fallthrough
        case .Equals:                   fallthrough
        case .Logic_Equals:             fallthrough
        case .Logic_Or:                 fallthrough
        case .Logic_Less_Than:          fallthrough
        case .Logic_More_Than:          fallthrough
        case .Logic_Less_Than_Equals:   fallthrough
        case .Logic_More_Than_Equals:   fallthrough
        case .Assign_Equals:            fallthrough
        case .Assign:                   fallthrough
        case .Assign_Static: 
        {
          ast_idx_op := parser_parse_expression( tokens, offs+1, asts )
          asts[ast_idx_op].left  = ast_idx_l

          if offs+2 >= len(tokens)
          {
            fmt.println( "[ERROR] binary operator:", tokens[offs +1].type, ", only has one value on left side" )
            return ast_idx_op
          }
          asts[ast_idx_op].right = parser_parse_expression( tokens, offs +2, asts )

          return ast_idx_op
        }
        case .Semicolon: fallthrough
        case .New_Line:
        {
          // fmt.println( "[ERROR] new line at start of expression:", tokens[offs].type )
          return ast_idx_l
        }
        case .Number:   fallthrough
        case .Identifier:
        {
          print_error( []token_t{ tokens[offs], tokens[offs +1] } , "Number/Identifier next to Number/Identifier" )
          return -1
        }
      }

    }
  }

  return -1
}
// parser_parse_expression :: proc( tokens: [dynamic]token_t, offs: int, asts: ^[dynamic]ast_t )
// {
//   if len(tokens) <= offs+2
//   {
//       
//   }
// 
//   switch tokens[offs].type
//   {
//     case .Add:                      fallthrough
//     case .Subtract:                 fallthrough
//     case .Multiply:                 fallthrough
//     case .Divide:                   fallthrough
//     case .Equals:                   fallthrough
//     case .Logic_Equals:             fallthrough
//     case .Logic_Or:                 fallthrough
//     case .Logic_Less_Than:          fallthrough
//     case .Logic_More_Than:          fallthrough
//     case .Logic_Less_Than_Equals:   fallthrough
//     case .Logic_More_Than_Equals:   fallthrough
//     case .Assign_Equals:            fallthrough
//     case .Assign:                   fallthrough
//     case .Assign_Static:            
//     {
//       fmt.println( "[ERROR] binary operator at start of expression:", tokens[offs].type )
//       return asts
//     }
//     case New_Line:
//     {
//       fmt.println( "[ERROR] new line at start of expression:", tokens[offs].type )
//       return asts
//     }
//     case Identifier:
//     {
//       ast_idx := append( asts, ast_t{ token=tokens[offs] } )
// 
//       switch tokens[offs +1].type
//       { 
//         case .Add:                      fallthrough
//         case .Subtract:                 fallthrough
//         case .Multiply:                 fallthrough
//         case .Divide:                   fallthrough
//         case .Equals:                   fallthrough
//         case .Logic_Equals:             fallthrough
//         case .Logic_Or:                 fallthrough
//         case .Logic_Less_Than:          fallthrough
//         case .Logic_More_Than:          fallthrough
//         case .Logic_Less_Than_Equals:   fallthrough
//         case .Logic_More_Than_Equals:   fallthrough
//         case .Assign_Equals:            fallthrough
//         case .Assign:                   fallthrough
//         case .Assign_Static:            
//         {
//           ast_left_idx := append( asts, ast_t{ token=tokens[offs +1] } )
//           
//           asts[ast_idx].left = &asts[ast_left_idx]
// 
//           parser_parse_expression( tokens, offs+2 )
//         }
//       }
//     }
//     case .Number:
//     {
//     }
//   }
// }
