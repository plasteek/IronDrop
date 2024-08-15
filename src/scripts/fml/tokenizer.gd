class_name FMLTokenizer
extends RefCounted

# FML Tokenizer implementation

const TokenMatcher = Tokenizer.TokenMatcher
const Token = Tokenizer.Token

enum TokenType {
  FUNC_NAME,
  COMMA,
  LEFT_BRACKET,
  RIGHT_BRACKET,
  STRING
}

var _tokenizer: Tokenizer
func _init():
  _tokenizer = Tokenizer.new([
   # Possibly incomplete string
   TokenMatcher.new("(['\"])((?!\\1).)*?\\1", _create_string_token),
   # Function Names
   TokenMatcher.new('[A-Za-z_]+', func(t): return Token.new(TokenType.FUNC_NAME, t)),
   # Operators
   TokenMatcher.new('[(),]', _create_op_token),
   # Comment
   TokenMatcher.new('#[^\n]*', func(_t): pass ),
   # Space do nothing to ignore space
   TokenMatcher.new(" ", func(_t): pass )
  ])

func tokenize(fml: String) -> Array[Token]:
  return _tokenizer.tokenize(fml)

func _create_op_token(token: String):
  var type = null
  match (token):
   "(":
     type = TokenType.LEFT_BRACKET
   ")":
     type = TokenType.RIGHT_BRACKET
   ",":
     type = TokenType.COMMA
  return Token.new(type, token)

func _create_string_token(token: String):
  # Remove quotation and extract the content
  var normalized = token.substr(1, token.length() - 2)
  return Token.new(TokenType.STRING, normalized)
