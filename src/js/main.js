/* main file */


if ( window.IriSP === undefined && window.__IriSP === undefined ) { 
  /**
    We define here IriSP, the object under which everything goes.
    We also alias it to __IriSP for backward compatibility
  */
	var IriSP = {}; 
	var __IriSP = IriSP; /* for backward compatibility */
}

IriSP.loadLibs = function( libs, config, metadata_url, callback ) {
    // Localize jQuery variable
		IriSP.jQuery = null;
    var $L = $LAB.script(libs.jQuery).script(libs.swfObject)
                .script(libs.jQueryUI)
                                   
    if (config.player.type === "jwplayer") {
      // load our popcorn.js lookalike
      $L = $L.script(libs.jwplayer);
    } else {
      // load the real popcorn
      $L = $L.script(libs.popcorn).script(libs["popcorn.code"]);
      if (config.player.type === "youtube") {
        $L = $L.script(libs["popcorn.youtube"]);
      } 
      if (config.player.type === "vimeo")
        $L = $L.script(libs["popcorn.vimeo"]);
      
      /* do nothing for html5 */
    }       
    
    /* widget specific requirements */
    for (var idx in config.gui.widgets) {
      if (config.gui.widgets[idx].type === "PolemicWidget") {        
        $L.script(libs.raphael);
      }
    }
    
    // same for modules
    /*
    for (var idx in config.modules) {
      if (config.modules[idx].type === "PolemicWidget")
        $L.script(libs.raphaelJs);
    }
    */

    $L.wait(function() {
      IriSP.jQuery = window.jQuery.noConflict( true );
      IriSP._ = window._.noConflict();
      IriSP.underscore = IriSP._;
      
      var css_link_jquery = IriSP.jQuery( "<link>", { 
        rel: "stylesheet", 
        type: "text/css", 
        href: libs.cssjQueryUI,
        'class': "dynamic_css"
      } );
      var css_link_custom = IriSP.jQuery( "<link>", { 
        rel: "stylesheet", 
        type: "text/css", 
        href: config.gui.css,
        'class': "dynamic_css"
      } );
      
      css_link_jquery.appendTo('head');
      css_link_custom.appendTo('head');
          
      IriSP.setupDataLoader();
      IriSP.__dataloader.get(metadata_url, 
          function(data) {
            /* save the data so that we could re-use it to
               configure the video
            */
            IriSP.__jsonMetadata = data;
            callback.call(window) });
    });
};