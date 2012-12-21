
// 画像消す
$.fn.infinite_autopager = function(options) {
    options = $.extend({
                maxNodes  : 100,
                intervals : 5000,
            }, options);
//var maxNodes = 100;
var lastNode = 0;
window.setInterval(function() {
    var hentry = document.getElementsByClassName("hentry");
    var len = hentry.length - options.maxNodes;
    var i;
    for(i = lastNode; i < len; i++) {
        if (hentry[i].nodeType != 1) continue;
        var h = hentry[i].offsetHeight;
        hentry[i].style.display = "list-item";
        hentry[i].style["max-height"] = "1000000px !important";
        hentry[i].style.height = h + "px";
        hentry[i].style.border = 0;
        hentry[i].style.padding = 0;

        var e = hentry[i].firstChild,tmp = e;
        while(e = tmp) {
            tmp = e.nextSibling;
            hentry[i].removeChild(e);
        };
    }
    lastNode = i;
}, options.intervals);
};
$("").infinite_autopager({maxNodes: 40, intervals: 50000});

