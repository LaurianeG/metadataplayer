IriSP.TagCloudWidget = function(Popcorn, config, Serializer) {
  IriSP.Widget.call(this, Popcorn, config, Serializer);
}

IriSP.TagCloudWidget.prototype = new IriSP.Widget();

IriSP.TagCloudWidget.prototype.draw = function() {
    
    var _urlRegExp = /https?:\/\/[0-9a-zA-Z\.%\/-_]+/g,
        _stopWords = [
            'aussi', 'and', 'avec', 'aux', 'bien', 'car', 'cette', 'comme', 'dans', 'donc', 'des', 'elle', 'encore', 'entre', 'est',
            'être', 'eux', 'faire', 'fait', 'http', 'ici', 'ils', 'les', 'leur', 'leurs', 'mais', 'mes', 'même', 'mon', 'notre',
            'non', 'nos', 'nous', 'ont', 'par', 'pas', 'peu', 'peut', 'plus', 'pour', 'que', 'qui', 'sans', 'ses' ,'son', 'sont', 'sur',
            'tes', 'très', 'the', 'ton', 'tous', 'tout', 'une', 'votre', 'vos', 'vous' ],
        _regexpword = /[^\s\.&;,'"!\?\d\(\)\+\[\]\\\…\-«»:\/]{3,}/g,
        _words = {},
        _showTitle = !this._config.excludeTitle,
        _showDescription = !this._config.excludeDescription,
        _excludePattern = this._config.excludePattern || null,
        _tagCount = this._config.tagCount || 30;
    if (typeof this._config.excludeWords !== "undefined" && this._config.excludeWords.length) {
        IriSP._(this._config.excludeWords).each(function(_w) {
            _stopWords.push(_w.toLowerCase());
        });
    }
    
    IriSP._(this._serializer._data.annotations).each(function(_annotation) {
       if (_annotation.content && _annotation.content.description) {
           var _txt = (_showTitle ? _annotation.content.title : '') + ' ' + (_showDescription ? _annotation.content.description : '')
           IriSP._(_txt.toLowerCase().replace(_urlRegExp, '').match(_regexpword)).each(function(_mot) {
               if (_stopWords.indexOf(_mot) == -1 && (_excludePattern == null || !_excludePattern.test(_mot))) {
                   _words[_mot] = 1 + (_words[_mot] || 0);
               }
           })
       } 
    });
    
    _words = IriSP._(_words)
        .chain()
        .map(function(_v, _k) {
            return {
                "word" : _k,
                "count" : _v
            }
        })
        .filter(function(_v) {
            return _v.count > 2;
        })
        .sortBy(function(_v) {
            return - _v.count;
        })
        .first(_tagCount)
        .value();
    var _max = _words[0].count,
        _min = Math.min(_words[_words.length - 1].count, _max - 1),
        _scale = 16 / Math.sqrt(_max - _min),
        _this = this,
        _html = '<ul>'
            + IriSP._(_words)
                .chain()
                .shuffle()
                .map(function(_word) {
                    var _size = 10 + _scale * Math.sqrt(_word.count - _min);
                    return '<li class="Ldt-TraceMe" style="font-size:'
                        + _size
                        + 'px;">'
                        + _word.word
                        + '</li>'
                })
                .value()
                .join("")
            + '</ul>';
    this.selector
        .addClass("Ldt-TagCloud")
        .html(_html);
    this.selector.find("li").click(function() {
        var _txt = this.textContent.replace(/(^[\s]+|[\s]+$)/g,'');
        _this._Popcorn.trigger("IriSP.search.triggeredSearch", _txt);
    });
    this._Popcorn.listen("IriSP.search", IriSP.wrap(this, function(searchString) {
        var _rgxp = new RegExp("(" + searchString.replace(/(\W)/g,'\\$1') + ")","gi");
        this.selector.find("li").each(function(_i, _e) {
            _e.innerHTML = searchString.length ?
                _e.textContent.replace(_rgxp,'<span class="Ldt-TagCloud-actif Ldt-TraceMe">$1</span>')
                : _e.textContent;
        });
    }));
    this._Popcorn.listen("IriSP.search.closed", IriSP.wrap(this, this.endsearch));
    this._Popcorn.listen("IriSP.search.cleared", IriSP.wrap(this, this.endsearch));
}

IriSP.TagCloudWidget.prototype.endsearch = function() {
    this.selector.find("li").each(function(_i, _e) {
        _e.innerHTML = _e.textContent;
    });
}