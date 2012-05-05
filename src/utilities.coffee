###
Utilities
###


$.extend Control,

  ###
  Given a value, returns a corresponding class:
  - A string value returns the global class with that string name.
  - A function value returns that function as is.
  - An object value returns a new anonymous class created from that JSON.
  ###
  getClass: ( value ) ->
    classFn = undefined
    if value is null or value is ""
            # Special cases used to clear class-valued properties.
      classFn = null
    else if $.isFunction value
      classFn = value
    else if $.isPlainObject value
      classFn = Control.subclass value
    else
      classFn = window[ value ]
      # TODO: Use string replacements
      throw "Unable to find a class called \"" + value + "\"." unless classFn
    classFn


  # Return true if the given element is a control.
  # TODO: Remove in favor of ":control"?
  isControl: ( element ) ->
    Control( element ).control() isnt undefined


###
Selector for ":control": reduces the set of matched elements to the ones
which are controls.
 
With this, $foo.is( ":control" ) returns true if at least one element in $foo
is a control, and $foo.filter( ":control" ) returns just the controls in $foo.
###
$.expr[":"].control = ( elem ) ->
  controlClass = Control( elem )._controlClass()
  ( if controlClass then controlClass is Control or controlClass:: instanceof Control else false )


Control::extend


  ###
  Return the array of elements cast to their closest JavaScript class ancestor.
  E.g., a jQuery $( ".foo" ) selector might pick up instances of control classes
  A, B, and C. If B and C are subclasses of A, this will return an instance of
  class A. So Control( ".foo" ).cast() does the same thing as A( ".foo" ), but without
  having to know the type of the elements in advance.
  
  The highest ancestor class this will return is the current class, even for plain
  jQuery objects, in order to allow Control methods ( like content() ) to be applied to
  the result.
  ###
  cast: ( defaultClass ) ->
    defaultClass = defaultClass or @constructor
    setClass = undefined
    i = 0
    length = @length
    while i < length
      $element = @nth( i )
      elementClass = $element._controlClass() or defaultClass
      setClass = elementClass  if setClass is undefined or ( setClass:: ) instanceof elementClass
      i++
    setClass = setClass or defaultClass  # In case "this" had no elements.
    setClass @


  ###
  Overload of standard $.each() that adds support for a no-argument form.
  If called with arguments, this each() will work as normal. When called with
  no arguments, it will return the controls in "this" as an array of subarrays.
  Each subarray has a single element of the same class as the current control.
  E.g., if "this" contains a jQuery object with
  
    [ control1, control2, control3, ... ]
    
  Then calling segments() returns
  
    [ [control1], [control2], [control3], ... ]
  
  This is useful in for loops and list comprehensions, and avoids callbacks.
  It is more sophisticated than simply looping over the control as a jQuery
  object, because that just loops over plain DOM elements, where this each()
  lets us loop over jQuery/Control objects that retain type information and,
  thus, direct access to class members.
  ###
  each: ( args... ) ->
    if args.length == 0
      # Return the controls in this as an array of subarrays.
      @constructor element for element in @
    else
      jQuery::each.apply this, args   # Defer to standard $.each()


  ###
  Execute a function once for each control in the array. The callback should
  look like
  
    $controls.eachControl( function( index, control ) {
      
    });
    
  This is similar to $.each(), but preserves type, so "this" and the control
  parameter passed to the callback are of the correct control class.
  ###
  eachControl: ( fn ) ->
    i = 0
    length = @length
    # TODO: for loop
    while i < length
      $control = @nth( i ).control()
      result = fn.call $control, i, $control
      break  if result is false
      i++
    @


  # Allow controls have an element ID specified on them in markup.
  id: ( id ) ->
    @attr "id", id


  ###
  Experimental function like eq, but faster because it doesn't manipulate
  the selector stack.
  ###
  nth: ( index ) ->
    @constructor @[ index ]


  ###
  Invoke the indicated setter functions on the control to
  set control properties. E.g.,
  
     $c.properties( { foo: "Hello", bar: 123 } );
  
  is shorthand for $c.foo( "Hello" ).bar( 123 ).
  ###
  properties: ( properties ) ->
    for propertyName of properties
      if @[ propertyName ] is undefined
        message = "Tried to set undefined property " + @className() + "." + propertyName + "()."
        throw message
      value = properties[ propertyName ]
      @[ propertyName ].call @, value
    @


  ###
  Get/set the given property on multiple elements at once. If called
  as a getter, an array of the property's current values is returned.
  If called as a setter, that property of each element will be set to
  the corresponding defined member of the values array. (Array values
  which are undefined will not be set.)
  ###
  propertyVector: ( propertyName, values ) ->
    propertyFn = @[ propertyName ]
    if values is undefined
      # Getter
      results = []
      i = 0
      length = @length
      while i < length
        results[i] = propertyFn.call @nth( i )
        i++
      results
    else
      # Setter
      i = 0
      length1 = @length
      length2 = values.length
      while i < length1 and i < length2
        propertyFn.call @nth( i ), values[i]  unless not values[i]
        i++
      @
      
      
  ###
  Save or retrieve an element associated with the control using the
  given key. For a collection of controls, the getter maps the collection
  to a collection of the corresponding elements.
  ###
  referencedElement: ( key, elements ) ->
    if elements is undefined
            # Map a collection of control instances to the given element
            # defined for each instance.
      elements = []
      i = 0
      length = @length

      while i < length
        element = $( @[i] ).data key
        elements.push element if element isnt undefined
        i++
      $result = Control( elements ).cast()
            # To make the element function $.end()-able, we want to call
            # jQuery's public pushStack() API. Unfortunately, that call
            # won't allow us to both a) return a result of the proper class
            # AND b) ensure that the result of calling end() will be of
            # the proper class. So, we directly set the internal prevObject
            # member used by end().
      $result.prevObject = @
      $result
    else
      i = 0
      length = @length

      while i < length
        $( @[i] ).data key, elements[i]
        i++
      @


  ###
  The tabindex of the control.
  ###
  tabindex: ( tabindex ) ->
    @attr "tabindex", tabindex
