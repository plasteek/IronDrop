class_name Tokenizer
extends RefCounted

var matchers: Array[TokenMatcher]

func _init(_matchers: Array[TokenMatcher]):
  matchers = _matchers

func tokenize(s: String) -> Array[Token]:
  var tokens: Array[Token] = []

  var ptr = 0
  var window = ""
  var last_valid_matcher = null
  
  # Ensure that we iterate 1 more time to check the last character
  while ptr < s.length():
   if ptr < s.length():
     var c = s[ptr]
     window += c
   var is_last_character = ptr >= s.length() - 1

   var matcher = _find_matcher(window)
   if matcher != null:
     ptr += 1
     last_valid_matcher = matcher
     # Only match the longest valid if its not the last element
     if not is_last_character:
      continue

   # If no matcher identifies the window, it's invalid 
   # But we wait until there is something that matches it
   if last_valid_matcher == null:
     ptr += 1
     if not is_last_character:
      continue

   # If it's the last character but there is not match
   # Then there is an invalid token
   if last_valid_matcher == null and is_last_character:
     break

   # Valid tokens only here
   var token = window.left(window.length() - 1)
   # Handle edge case where it's the last character leftover
   if token == "":
     token = window

   # Let user identify what to do with the token
   var token_class = last_valid_matcher.callback.call(token)

   if typeof(token_class) == TYPE_STRING:
     push_error(token_class)
     return tokens
   if token_class != null:
     tokens.push_back(token_class)
   
   # Reset state
   window = ""
   last_valid_matcher = null
   
  if window.length() > 0: # If the string not fully consumed, then error
   push_error("Invalid token: " + window[0])
   return tokens

  return tokens

func _find_matcher(window: String):
  for tokenizer in matchers:
   var res = tokenizer.regex.search(window)
   if res != null:
     return tokenizer
  return null

class TokenMatcher:
  var regex: RegEx
  var callback: Callable
  var expression: String
  func _init(_expression: String, _callback: Callable):
   regex = RegEx.new()
   expression = _expression

   # Wrap the regex so that it identifies the start and end
   if not expression.begins_with("^"):
     expression = expression.insert(0, "^")
   if not expression.ends_with("$"):
     expression += "$"

   regex.compile(expression)
   callback = _callback

class Token:
  var type
  var text: String
  func _init(token_type, token_text: String):
   type = token_type
   text = token_text
