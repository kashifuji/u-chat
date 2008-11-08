var DragResize = (function() {

  var $window         = window,
    $document         = document,
    $addEventListener = 'addEventListener',
    $offset           = 'offset',
    $client           = 'client',
    $scroll           = 'scroll',
    $min              = 'min',
    $left             = 'Left',
    $top              = 'Top',
    $width            = 'Width',
    $height           = 'Height',
    $drag             = 'drag',
    $resize           = 'resize',
    $handle           = 'Handle',
    $style            = 'style',
    $ignoreTags       = 'ignoreTags',
    $null             = null;

  var $body          = $document.body,
    $documentElement = $document.documentElement;

  var $methodWrapper = function(method, scope)
  {
    return function() { return method.apply(scope, arguments) };
  },
  $addEvent = function(element, type, proc, scope)
  {
    var listener = $methodWrapper(proc, scope);
    element[$addEventListener] ?
      element[$addEventListener](type, listener, false) :
      element.attachEvent('on' + type, listener);
    return { $element: element, $type: type, $listener: listener };
  },
  $removeEvent = function(info)
  {
    info.$element[$addEventListener] ?
      info.$element.removeEventListener(info.$type, info.$listener, false) :
      info.$element.detachEvent('on' + info.$type, info.$listener);
  },
  $stopEvent = function(event)
  {
    event.stopPropagation && event.stopPropagation();
    event.preventDefault  && event.preventDefault();
    event.cancelBubble = true;
    event.returnValue  = false;
  },
  $getElement = function(id)
  {
    return typeof id === 'string' ? $document.getElementById(id) : id;
  },
  $getScroll = (typeof $window.pageXOffset === 'number' ?
                function() {
                  return { x: $window.pageXOffset, y: $window.pageYOffset };
                } :
                ($documentElement && $documentElement[$client+$width] ?
                 function() {
                   return { x: $documentElement[$scroll+$left], y: $documentElement[$scroll+$top] };
                 } :
                 function() {
                   return { x: $body[$scroll+$left], y: $body[$scroll+$top] };
                 })),
  $getWindowSize = ($window.innerWidth ?
                    function() {
                      return { x: $window.innerWidth, y: $window.innerHeight };
                    } :
                    ($documentElement && $documentElement[$client+$width] ?
                     function() {
                       return { x: $documentElement[$client+$width], y: $documentElement[$client+$height] };
                     } :
                     function() {
                       return { x: $body[$offset+$width], y: $body[$client+$height] };
                     })),
  DragResize = function(container, options)
  {
    options                  = options || {};
    var self                 = this;
    options[$resize+$handle] = $getElement(options[$resize+$handle]);
    self.$container          = (container = $getElement(container));
    self.$minWidth           = options[$min+$width];
    self.$minHeight          = options[$min+$height];
    self[$scroll]            = options[$scroll];
	self.$onClickCallback    = options['onclick'];
    self.$onClickScope       = options['scope'];
	self.$ignoreTags         = {};
    self.$events             = [];
    if((options[$drag+$handle] = $getElement(options[$drag+$handle])) || options[$resize+$handle] != container)
    {
      self.$dragHandle = options[$drag+$handle] || container;
      self.$events.push($addEvent(self.$dragHandle, 'mousedown', self.$drag_onMouseDown, self));
      self.$events.push($addEvent(self.$dragHandle, 'click',     self.$onClick,          self));
    }
    if(self.$dragHandle != container || (options[$resize+$handle] && options[$resize+$handle] != self.$dragHandle))
    {
      self.$resizeHandle = options[$resize+$handle] || container;
      self.$events.push($addEvent(self.$resizeHandle, 'mousedown', self.$resize_onMouseDown, self));
      self.$events.push($addEvent(self.$resizeHandle, 'click',     self.$onClick,            self));
    }
    var ignoreTags = options[$ignoreTags];
    if(typeof ignoreTags === 'string') {
	  ignoreTags = [ignoreTags];
    }
    if(ignoreTags) {
      for(var i = 0 ; i < ignoreTags.length ; ++i) {
        self.$ignoreTags[ignoreTags[i].toUpperCase()] = true;
      }
    }
  };

  DragResize[$min+$width]    = 100;
  DragResize[$min+$height]   = 100;
  DragResize.$dragInfo        = $null;
  DragResize.$ie              = !!$window.ActiveXObject;

  DragResize.$onMouseMove = function(event)
  {
    var info = DragResize.$dragInfo;
    if(info)
    {
      if(DragResize.$ie && !(event.button & 1))
      {
        DragResize.$finish();
        return;
      }
      info.$currentX = event.clientX;
      info.$currentY = event.clientY;
      DragResize.$ie && $stopEvent(event);
    }
  };

  DragResize.$onMouseUp = function(event)
  {
    var info = DragResize.$dragInfo, scroll = $getScroll();
	var self = info.$manager;
    if(info && typeof self.$onClickCallback === 'function' &&
       info.$clickX + info.$baseScX == event.clientX + scroll.x &&
       info.$clickY + info.$baseScY == event.clientY + scroll.y) {
      self.$onClickCallback.call(self.$onClickScope, event);
    }
    DragResize.$finish();
  };

  DragResize.$finish = function()
  {
    var info = DragResize.$dragInfo;
    info && info.$intervalId && clearInterval(info.$intervalId);
    DragResize.$dragInfo = $null;
  };

  DragResize.prototype = {

    $drag_onMouseDown : function(event)
    {
	  var self = this;
	  if(self.$checkIgnoreTags(event))
	    return;
      $stopEvent(event);
      var info    = DragResize.$dragInfo = self.$beginDrag(event, self.$drag_onInterval),
        container = self.$container;
      info.$baseX = container[$offset+$left];
      info.$baseY = container[$offset+$top];
      info.$minX  = 0;
      info.$minY  = 0;
      info.$maxX  = $documentElement[$scroll+$width]  - container[$offset+$width];
      info.$maxY  = $documentElement[$scroll+$height] - container[$offset+$height];
    },

    $drag_onInterval : function()
    {
      this.$updateDrag(function(info, container, x, y, scroll) {
        container[$style].left = x + 'px';
        container[$style].top  = y + 'px';
        if(this[$scroll])
        {
          var frameSize = $getWindowSize(),
            right = x + container[$offset+$width], bottom = y + container[$offset+$height],
            sx = scroll.x, sy = scroll.y;
          x < sx ? (sx = x) : (right > (sx + frameSize.x) && (sx = right - frameSize.x));
          y < sy ? (sy = y) : (bottom > (sy + frameSize.y) && (sy = bottom - frameSize.y));
          (sx != scroll.x || sy != scroll.y) && $window[$scroll](sx, sy);
        }
      });
    },

    $resize_onMouseDown : function(event)
    {
      var self = this;
	  if(self.$checkIgnoreTags(event))
	    return;
      $stopEvent(event);
      var info      = DragResize.$dragInfo = self.$beginDrag(event, self.$resize_onInterval),
        container   = self.$container,
        minWidth    = (typeof self.$minWidth  === 'number' ? self.$minWidth  : DragResize[$min+$width]),
        minHeight   = (typeof self.$minHeight === 'number' ? self.$minHeight : DragResize[$min+$height]);
      info.$baseX   = container[$offset+$left] + container[$offset+$width];
      info.$baseY   = container[$offset+$top]  + container[$offset+$height];
      info.$adjustX = container[$offset+$width]  - container[$client+$width];
      info.$adjustY = container[$offset+$height] - container[$client+$height];
      info.$minX    = container[$offset+$left] + info.$adjustX + minWidth;
      info.$minY    = container[$offset+$top]  + info.$adjustY + minHeight;
      info.$maxX    = $documentElement[$scroll+$width];
      info.$maxY    = container[$style].position != 'absolute' ? 65536 : $documentElement[$scroll+$height];
    },

    $resize_onInterval : function()
    {
      this.$updateDrag(function(info, container, x, y, scroll) {
        container[$style].width  = (x - container[$offset+$left] - info.$adjustX) + 'px';
        container[$style].height = (y - container[$offset+$top]  - info.$adjustY) + 'px';
        if(this[$scroll])
        {
          var frameSize = $getWindowSize(),
            left        = container[$offset+$left], top = container[$offset+$top],
            sx          = scroll.x, sy = scroll.y;

          left < sx              && (sx = left);
          x > (sx + frameSize.x) && (sx = x - frameSize.x);
          top < sy               && (sy = top);
          y > (sy + frameSize.y) && (sy = y - frameSize.y);
          (sx != scroll.x || sy != scroll.y) && $window[$scroll](sx, sy);
        }
      });
    },

	$onClick : function(event) {
	  if(!this.$checkIgnoreTags(event))
        $stopEvent(event);
    },

	$checkIgnoreTags : function(event) {
      var element = event.target || event.srcElement;
      while(element) {
        if(element.nodeType == 1 && this.$ignoreTags[element.tagName.toUpperCase()])
          return element;
        element = element.parentNode;
      }
      return null;
    },

    $beginDrag : function(event, updateProc)
    {
      $stopEvent(event);
      DragResize.$finish();
      var container = this.$container, scroll = $getScroll(),
        mouseX = event.clientX, mouseY = event.clientY,
        scrollX = scroll.x, scrollY = scroll.y;
      return {
        $manager:    this,
        $intervalId: setInterval($methodWrapper(updateProc, this), 30),
        $clickX:     mouseX,
        $clickY:     mouseY,
        $currentX:   mouseX,
        $currentY:   mouseY,
        $prevX:      mouseX,
        $prevY:      mouseY,
        $baseScX:    scrollX,
        $baseScY:    scrollY,
        $currentScX: scrollX,
        $currentScY: scrollY,
        $prevScX:    scrollX,
        $prevScY:    scrollY
      };
    },

    $updateDrag : function(proc)
    {
      var info = DragResize.$dragInfo, scroll = $getScroll();
      if(info.$currentX   != info.$prevX || info.$currentY   != info.$prevY ||
         info.$currentScX != scroll.x    || info.$currentScY != scroll.y)
      {
        var container = this.$container,
          x = Math.min(Math.max(info.$baseX + info.$currentX - info.$clickX + scroll.x - info.$baseScX, info.$minX), info.$maxX),
          y = Math.min(Math.max(info.$baseY + info.$currentY - info.$clickY + scroll.y - info.$baseScY, info.$minY), info.$maxY);
        proc.call(this, info, container, x, y, scroll);
        info.$prevX      = info.$currentX;
        info.$prevY      = info.$currentY;
        info.$currentScX = scroll.x;
        info.$currentScY = scroll.y;
      }
    },

    detach : function()
    {
      var self = this;
      DragResize.$dragInfo && DragResize.$dragInfo.$manager == self &&  DragResize.$finish();
      while(self.$events.length > 0)
        $removeEvent(self.$events.pop());
      self.$container = self.$dragHandle = self.$resizeHandle = $null;
    }

  };

  $addEvent($document, 'mouseup',   DragResize.$onMouseUp,   DragResize);
  $addEvent($document, 'mousemove', DragResize.$onMouseMove, DragResize);

  return DragResize;

})();