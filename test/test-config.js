function testConfig(_urlMetadata, _useLocalBuild, _video, _playerType) {
    document.getElementById('LdtPlayer').innerHTML = '';
    _useLocalBuild = (typeof _useLocalBuild !== "undefined" && _useLocalBuild)
    IriSP.libFiles.defaultDir = _useLocalBuild ? "libs/" : "../src/js/libs/";
    IriSP.widgetsDir = _useLocalBuild ? "metadataplayer" : "../src/widgets";
    var _metadata = {
        url: _urlMetadata,
        format: 'ldt'
    };
    var _config = {            
        gui: {
            width : 620,
            container : 'LdtPlayer',
            default_options: {
                metadata: _metadata
            },
            css : _useLocalBuild ? 'metadataplayer/LdtPlayer-core.css' : '../src/css/LdtPlayer-core.css',
            widgets: [
                { type: "Sparkline" },
                { type: "Slider" },
                { type: "Controller" },
                { type: "Polemic" },
                { type: "Segments" },
                { type: "Slice" },
                { type: "Arrow" },
                { type: "Annotation" },
                { type: "CreateAnnotation" },
                { type: "Tweet" },
                { type: "Tagcloud" },
                {
                    type: "AnnotationsList",
                    container: "AnnotationsListContainer"
                },
                { type: "Mediafragment"}
/*                {
                    type: "Trace",
                    default_subject: "tests-iri",
                    js_console: true
            } */
            ]
        },
        player:{
            type:'auto',
            live: true, 
            height: 350, 
            width: 620, 
            provider: "rtmp",
            autostart: true,
            metadata: _metadata
        }
    };
    if (typeof _playerType != "undefined") {
        _config.player.type = _playerType;
    }
    if (typeof _video != "undefined") {
        _config.player.video = _video;
    }
    
    return new IriSP.Metadataplayer(_config);
}