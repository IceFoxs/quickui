// Generated by CoffeeScript 1.3.1

/*
Rehydration

This takes static HTML created in normal means for SEO purposes, and looks for
elements decorated with data- properties indicating which elements should be
reconstituted as live QuickUI controls.
*/


/*
Rehydrate controls from static HTML.
*/


(function() {
  var classPropertyNameMap, getCompoundPropertiesFromChildren, getPropertiesFromAttributes, propertyNameMaps, rehydrateControl, restorePropertyCase;

  Control.prototype.rehydrate = function() {
    var $controls, subcontrols;
    subcontrols = this.find("[data-control]").get();
    if (subcontrols.length > 0) {
      subcontrols = subcontrols.reverse();
      $.each(subcontrols, function(index, element) {
        return rehydrateControl(element);
      });
    }
    $controls = Control();
    this.each(function(index, element) {
      var $control, $element;
      $element = Control(element);
      $control = ($element.data("control") ? rehydrateControl(element) : $element);
      return $controls = $controls.add($control);
    });
    return $controls.cast();
  };

  /*
  Rehydrate the given element as a control.
  */


  rehydrateControl = function(element) {
    var $element, className, controlClass, lowerCaseProperties, properties;
    $element = $(element);
    className = $element.data("control");
    if (!className) {
      return;
    }
    $element.removeAttr("data-control");
    controlClass = Control.getClass(className);
    lowerCaseProperties = $.extend({}, getPropertiesFromAttributes(element), getCompoundPropertiesFromChildren(element));
    properties = restorePropertyCase(controlClass, lowerCaseProperties);
    return $(element).control(controlClass, properties);
  };

  /*
  Return the properties indicated on the given element's attributes.
  */


  getPropertiesFromAttributes = function(element) {
    var $element, attributeName, attributes, i, key, length, match, properties, propertyName, regexDataProperty;
    properties = {};
    attributes = element.attributes;
    regexDataProperty = /^data-(.+)/;
    i = 0;
    length = attributes.length;
    while (i < length) {
      attributeName = attributes[i].name;
      match = regexDataProperty.exec(attributeName);
      if (match) {
        propertyName = match[1];
        if (propertyName !== "control") {
          properties[propertyName] = attributes[i].value;
        }
      }
      i++;
    }
    $element = $(element);
    for (key in properties) {
      $element.removeAttr("data-" + key);
    }
    return properties;
  };

  /*  
  Return any compound properties found in the given element's children.
  */


  getCompoundPropertiesFromChildren = function(element) {
    var properties;
    properties = {};
    $(element).children().filter("[data-property]").each(function(index, element) {
      var $element, propertyName, propertyValue;
      $element = Control(element);
      propertyName = $element.attr("data-property");
      if (propertyName !== "control") {
        propertyValue = $element.content();
        properties[propertyName] = propertyValue;
        if (propertyValue instanceof jQuery) {
          return propertyValue.detach();
        }
      }
    }).remove();
    return properties;
  };

  /*
  Map the given property dictionary, in which all property names may be in
  lowercase, to the equivalent mixed case names. Properties which are not
  found in the control class are dropped.
  */


  restorePropertyCase = function(controlClass, properties) {
    var map, mixedCaseName, propertyName, result;
    if ($.isEmptyObject(properties)) {
      return properties;
    }
    map = classPropertyNameMap(controlClass);
    result = {};
    for (propertyName in properties) {
      mixedCaseName = map[propertyName.toLowerCase()];
      if (mixedCaseName) {
        result[mixedCaseName] = properties[propertyName];
      }
    }
    return result;
  };

  /*
  Cached maps for property names in rehydrated control classes. See below.
  */


  propertyNameMaps = {};

  /*
  Return a dictionary for the given class which maps the lowercase forms of
  its properties' names to their full mixed-case property names.
  */


  classPropertyNameMap = function(controlClass) {
    var className, lowerCaseName, map, mixedCaseName;
    className = controlClass.className;
    if (!propertyNameMaps[className]) {
      map = {};
      for (mixedCaseName in controlClass.prototype) {
        lowerCaseName = mixedCaseName.toLowerCase();
        map[lowerCaseName] = mixedCaseName;
      }
      propertyNameMaps[className] = map;
    }
    return propertyNameMaps[className];
  };

  /*
  Auto-loader for rehydration.
  Set data-create-controls="true" on the body tag to have the current
  page automatically rehydrated on load.
  */


  jQuery(function() {
    var $body;
    $body = Control("body");
    if ($body.data("create-controls")) {
      return $body.rehydrate();
    }
  });

}).call(this);
