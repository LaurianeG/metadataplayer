IriSP.createAnnotationWidget = function(Popcorn, config, Serializer) {
  IriSP.Widget.call(this, Popcorn, config, Serializer);
  this._hidden = true;
  this.keywords = IriSP.widgetsDefaults["createAnnotationWidget"].keywords;
};


IriSP.createAnnotationWidget.prototype = new IriSP.Widget();

IriSP.createAnnotationWidget.prototype.clear = function() {
    this.selector.find(".Ldt-SaTitle").text("");
    this.selector.find(".Ldt-SaDescription").text("");
    this.selector.find(".Ldt-SaKeywordText").text("");
};

IriSP.createAnnotationWidget.prototype.showWidget = function() {
  this.layoutManager.slice.after("ArrowWidget")
                          .before("createAnnotationWidget")
                          .jQuerySelector().hide();
  this.selector.show();
};

IriSP.createAnnotationWidget.prototype.hideWidget = function() {
  this.selector.hide();
  this.layoutManager.slice.after("ArrowWidget")
                          .before("createAnnotationWidget")
                          .jQuerySelector().show();
};

IriSP.createAnnotationWidget.prototype.draw = function() {
  var _this = this;

  var annotationMarkup = IriSP.templToHTML(IriSP.createAnnotationWidget_template);
	this.selector.append(annotationMarkup);
  
  this.selector.hide();
  for (var i = 0; i < this.keywords.length; i++) {
    var templ = IriSP.templToHTML("<span class='Ldt-createAnnotation-absent-keyword'>{{keyword}}</span>", 
                                  {keyword: this.keywords[i]});
                                  
    this.selector.find(".Ldt-createAnnotation-keywords").append(templ);
  }
  
  
  this._Popcorn.listen("IriSP.PlayerWidget.AnnotateButton.clicked", 
                        IriSP.wrap(this, this.handleAnnotateSignal));  
};

IriSP.createAnnotationWidget.prototype.handleAnnotateSignal = function() {
  if (this._hidden == false) {
    this.selector.hide();
    this._hidden = true;
  } else {
    this.selector.show();
    this._hidden = false;
  }
};