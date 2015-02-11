(function() {
  var LayerDraggable, layer,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  LayerDraggable = (function(_super) {
    __extends(LayerDraggable, _super);

    function LayerDraggable(layer) {
      this.layer = layer;
      this._touchEnd = __bind(this._touchEnd, this);
      this._touchStart = __bind(this._touchStart, this);
      this._updatePosition = __bind(this._updatePosition, this);
      this._deltas = [];
      this._isDragging = false;
      this._start = null;
      this._offset = null;
      this._delta = null;
      this._cursorOffset = null;
      this.enabled = true;
      this.speedX = 1.0;
      this.speedY = 1.0;
      this._attach();
    }

    LayerDraggable.prototype.update = function(event, point) {
      this.layer.x = point.x;
      return this.layer.y = point.y;
    };

    LayerDraggable.prototype._attach = function() {
      return this.layer.on(Events.TouchStart, this._touchStart);
    };

    LayerDraggable.prototype._remove = function() {
      return this.layer.off(Events.TouchStart, this._touchStart);
    };

    LayerDraggable.prototype._updatePosition = function(event) {
      var delta, offset, point, touchEvent;
      if (this.enabled === false) {
        return;
      }
      touchEvent = Events.touchEvent(event);
      offset = {
        x: touchEvent.clientX - this._start.x,
        y: touchEvent.clientY - this._start.y
      };
      delta = {
        x: offset.x - this._offset.x,
        y: offset.y - this._offset.y,
        t: event.timeStamp
      };
      this._offset = {
        x: this._offset.x + delta.x,
        y: this._offset.y + delta.y
      };
      delta.x = delta.x * this.speedX * (1 / this.layer.screenScaleX());
      delta.y = delta.y * this.speedY * (1 / this.layer.screenScaleY());
      this._deltas.push(delta);
      this._delta = delta;
      print(this._offset.x, this.speedX, this._offset.x * this.speedX);
      point = {
        x: parseInt(this._start.x - this._cursorOffset.x + (this._offset.x * this.speedX)),
        y: parseInt(this._start.y - this._cursorOffset.y + (this._offset.y * this.speedY))
      };
      event.offset = this._offset;
      event.delta = this._delta;
      this.emit(Events.DragWillMove, event);
      this.update(event, point);
      this.emit(Events.DragMove, event);
      return this.emit(Events.DragDidMove, event);
    };

    LayerDraggable.prototype._touchStart = function(event) {
      var animation, propertyName, touchEvent, _ref;
      _ref = this.layer.animatingProperties();
      for (propertyName in _ref) {
        animation = _ref[propertyName];
        if (k === "x" || k === "y") {
          animation.stop();
        }
      }
      this._isDragging = true;
      touchEvent = Events.touchEvent(event);
      this._start = {
        x: touchEvent.clientX,
        y: touchEvent.clientY
      };
      this._cursorOffset = {
        x: touchEvent.clientX - this.layer.x,
        y: touchEvent.clientY - this.layer.y
      };
      this._offset = {
        x: 0,
        y: 0
      };
      this._delta = {
        x: 0,
        y: 0
      };
      document.addEventListener(Events.TouchMove, this._updatePosition);
      document.addEventListener(Events.TouchEnd, this._touchEnd);
      return this.emit(Events.DragStart, event);
    };

    LayerDraggable.prototype._touchEnd = function(event) {
      this._isDragging = false;
      document.removeEventListener(Events.TouchMove, this._updatePosition);
      document.removeEventListener(Events.TouchEnd, this._touchEnd);
      this.emit(Events.DragEnd, event);
      return this._deltas = [];
    };

    LayerDraggable.prototype.velocity = function(time) {
      var delta, distance, index, timeDelta, velocity;
      if (time == null) {
        time = 0.1;
      }
      if (this._deltas.length < 1) {
        return {
          x: 0,
          y: 0
        };
      }
      index = this._deltas.length;
      distance = {
        x: 0,
        y: 0
      };
      while (index >= 0) {
        index--;
        delta = this._deltas[index];
        distance.x += Math.abs(delta.x);
        distance.y += Math.abs(delta.y);
        if ((Date.now() - delta.t) > (time * 1000)) {
          break;
        }
      }
      timeDelta = (Date.now() - delta.t) / 1000;
      velocity = {
        x: distance.x / timeDelta,
        y: distance.y / timeDelta
      };
      if (velocity.x === Infinity) {
        velocity.x = 0;
      }
      if (velocity.y === Infinity) {
        velocity.y = 0;
      }
      return velocity;
    };

    LayerDraggable.prototype.emit = function(eventName, event) {
      this.layer.emit(eventName, event);
      return LayerDraggable.__super__.emit.call(this, eventName, event);
    };

    return LayerDraggable;

  })(Framer.BaseClass);

  layer = new Layer;

  layer.d = new LayerDraggable(layer);

  layer.on(Events.DragMove, function() {
    var v;
    layer.d.speedX = Utils.round(Utils.modulate(layer.d._offset.x, [0, 1000], [1, 0], true), 3);
    v = layer.d.velocity();
    return Utils.labelLayer(layer, "" + (Utils.round(v.x, 0)) + " " + (Utils.round(v.y, 0)));
  });

}).call(this);
