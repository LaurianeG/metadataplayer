/** A widget to create a new segment */
IriSP.SliceWidget = function(Popcorn, config, Serializer) {
  IriSP.Widget.call(this, Popcorn, config, Serializer);
  
};

IriSP.SliceWidget.prototype = new IriSP.Widget();

IriSP.SliceWidget.prototype.draw = function() {
  var templ = Mustache.to_html(IriSP.sliceWidget_template);
  this.selector.append(templ);
  
  this.sliceZone = this.selector.find(".Ldt-sliceZone");
  
  /* global variables used to keep the position and width
     of the zone.
  */  
  this.zoneLeft = 0;
  this.zoneWidth = 0;
  
  this.leftHandle = this.selector.find(".Ldt-sliceLeftHandle");
  this.rightHandle = this.selector.find(".Ldt-sliceRightHandle");

  this.leftHandle.draggable({axis: "x",
  drag: IriSP.wrap(this, this.leftHandleDragged),  
  containment: "parent"
  });

  this.rightHandle.draggable({axis: "x",
  drag: IriSP.wrap(this, this.rightHandleDragged),    
  containment: "parent"
  });

  this.leftHandle.css("position", "absolute");
  this.rightHandle.css("position", "absolute");
  
  this._Popcorn.listen("IriSP.SliceWidget.position", 
                        IriSP.wrap(this, this.positionSliceHandler));
  
  this._Popcorn.listen("IriSP.SliceWidget.show", IriSP.wrap(this, this.show));
  this._Popcorn.listen("IriSP.SliceWidget.hide", IriSP.wrap(this, this.hide));
  this.selector.hide();
};

/** responds to an "IriSP.SliceWidget.position" message
    @param params an array with the first element being the left distance in
           percents and the second element the width of the slice in pixels
*/        
IriSP.SliceWidget.prototype.positionSliceHandler = function(params) {
  left = params[0];
  width = params[1];
  
  this.zoneLeft = left;
  this.zoneWidth = width;
  this.sliceZone.css("left", left + "px");
  this.sliceZone.css("width", width + "px");
  this.leftHandle.css("left", (left - 7) + "px");
  this.rightHandle.css("left", left + width + "px");
  
  this._leftHandleOldLeft = left - 7;
  this._rightHandleOldLeft = left + width;
};

/** handle a dragging of the left handle */
IriSP.SliceWidget.prototype.leftHandleDragged = function(event, ui) {
  /* we have a special variable, this._leftHandleOldLeft, to keep the
     previous position of the handle. We do that to know in what direction
     is the handle being dragged
  */
  
  var currentX = this.leftHandle.position()["left"];
  var rightHandleX = Math.floor(this.rightHandle.position()["left"]);
  //ui.position.left = Math.floor(ui.position.left);
  
  if (currentX >= rightHandleX - 7 && ui.position.left >= this._leftHandleOldLeft) {
    /* prevent the handle from moving past the right handle */
    ui.position.left = this._leftHandleOldLeft;
  }
  
  if (ui.position.left > this._leftHandleOldLeft) {
    console.log(ui.position.left, this._leftHandleOldLeft);
    var increment = 1;
  } else if (ui.position.left < this._leftHandleOldLeft)
    var increment = -1;
  else
    var increment = 0;
  
  // the width of the zone is supposed to diminish by increment
  // while at the same time the position of the zone should
  // change by the opposite increment.
  this.zoneWidth = this.zoneWidth - increment;
  this.zoneLeft = Math.floor(this._leftHandleOldLeft + increment + 7);
  
  this.sliceZone.css("width", this.zoneWidth);
  this.sliceZone.css("left", this.zoneLeft + "px");
  this._leftHandleOldLeft = Math.floor(this._leftHandleOldLeft + increment);
  ui.position.left = this._leftHandleOldLeft;
  this.broadcastChanges();
    
};

/** handle a dragging of the right handle */
IriSP.SliceWidget.prototype.rightHandleDragged = function(event, ui) { 
  var currentX = this.rightHandle.position()["left"];
  var leftHandleX = this.leftHandle.position()["left"];
  
  if (currentX <= leftHandleX + 7 && ui.position.left <= this._rightHandleOldLeft) {
    /* prevent the handle from moving past the right handle */
    ui.position.left = this._rightHandleOldLeft;
  }
  
  var increment = currentX - (this.zoneLeft + this.zoneWidth);  

  this.zoneWidth += increment;  
  this.sliceZone.css("width", this.zoneWidth);
  this.broadcastChanges();
  
  this._rightHandleOldLeft = ui.position.left; 
};

/** tell to the world that the coordinates of the slice have
    changed 
*/
IriSP.SliceWidget.prototype.broadcastChanges = function() {
  var leftPercent = (this.zoneLeft / this.selector.width()) * 100;
  var zonePercent = (this.zoneWidth / this.selector.width()) * 100;
  
  this._Popcorn.trigger("IriSP.SliceWidget.zoneChange", [leftPercent, zonePercent]);  
};

IriSP.SliceWidget.prototype.show = function() {
  this.selector.show();
};

IriSP.SliceWidget.prototype.hide = function() {
  this.selector.hide();
};