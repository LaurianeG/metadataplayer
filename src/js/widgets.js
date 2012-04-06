/* the widget classes and definitions */

/**
  * @class Widget is an "abstract" class. It's mostly used to define some properties common to every widget.
  *
  *  Note that widget constructors are never called directly by the user. Instead, the widgets are instantiated by functions
  *  defined in init.js
  *  
  * @constructor
  * @param Popcorn a reference to the popcorn Object
  * @param config configuration options for the widget
  * @param Serializer a serializer instance from which the widget reads data fromCharCode  
*/
IriSP.Widget = function(Popcorn, config, Serializer) {

  if (config === undefined || config === null) {
    config = {}
  }
  
  this._Popcorn = Popcorn;
  this._config = config;  
  this._serializer = Serializer;
  
  if (config.hasOwnProperty("container")) {
     this._id = config.container;
     this.selector = IriSP.jQuery("#" + this._id);
  }

  if (config.hasOwnProperty("spacer")) {
     this._spacerId = config.spacer;
     this.spacer = IriSP.jQuery("#" + this._spacerId);
  }


  if (config.hasOwnProperty("width")) {
     // this.width and not this._width because we consider it public.
     this.width = config.width;     
  }
  
  if (config.hasOwnProperty("height")) {    
     this.height = config.height;     
  }
  
  if (config.hasOwnProperty("heightmax")) {
     this.heightmax = config.heightmax;     
  }

  if (config.hasOwnProperty("widthmax")) {
     this.widthmax = config.widthmax;     
  } 

  if (config.hasOwnProperty("layoutManager")) {
     this.layoutManager = config.layoutManager;
  }
  if (typeof this.selector != "undefined") {
      this.selector.addClass("Ldt-TraceMe").addClass("Ldt-Widget");
      this.selector.attr("widget-type", this._config.type);
  }
  
  // Parsing Widget Defaults
  var _this = this;
  
  if (typeof config.type == "string" && typeof IriSP.widgetsDefaults[config.type] == "object") {
      IriSP._(IriSP.widgetsDefaults[config.type]).each(function(_v, _k) {
          if (typeof config[_k] != "undefined") {
              _this[_k] = config[_k];
          } else {
              _this[_k] = _v;
          }
      });
  }
  
};


IriSP.Widget.prototype.currentMedia = function() {
    return this._serializer.currentMedia();
}

IriSP.Widget.prototype.getDuration = function() {
    return this._serializer.getDuration();
}

/**
  * This method responsible of drawing a widget on screen.
  */
IriSP.Widget.prototype.draw = function() {
  /* implemented by "sub-classes" */  
};

/**
  * Optional method if you want your widget to support redraws.
  */
IriSP.Widget.prototype.redraw = function() {
  /* implemented by "sub-classes" */  
};