extends Node
signal changed
var language="th"
var english={}
var source_keys=[]
var translated={}
func _ready():
 english=JSON.parse_string(FileAccess.get_file_as_string("res://assets/locales/en.json"))
 source_keys=english.keys()
 source_keys.sort_custom(func(a,b):return a.length()>b.length())
func t(text):
 var value=str(text)
 if language=="th":return value
 if english.has(value):return english[value]
 if translated.has(value):return translated[value]
 var original=value
 # Dynamic names and fragments also use the same catalog.
 for key in source_keys:
  if value.contains(key):value=value.replace(key,english[key])
 translated[original]=value
 return value
func source(text):
 for key in source_keys:
  if english[key]==text:return key
 return text
func set_language(value):
 language="en" if value=="en" else "th"
 TranslationServer.set_locale(language)
 changed.emit()
