# KrakenScript

KrakenScript a set of rules that are interpreted every time a URL gets scanned
to obtain certain text or information

## Syntax

```
($function) $value:
    [$action] $attribute ~ $value | $delimiter |
```
## Example
```
(output) metas.kd:
    [element] meta ~ attrcontent | , |
```

## Functions

### output

'output' allows to write data inside of a file in '$value'

## Actions
### element
'element' searches for an element in the DOM
the '$attribute' value must be the element to search
'$value' is the operation to execute
* content
  * Gets the text of an HTML element
* attrcontent
  * Gets the attribute 'content' from an HTML element  

'$delimiter' is the delimiter used to save the information to the file
