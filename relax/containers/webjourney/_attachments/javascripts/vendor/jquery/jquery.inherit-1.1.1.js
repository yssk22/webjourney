/**
 * Inheritance plugin
 *
 * Copyright (c) 2009 Filatov Dmitry (alpha@zforms.ru)
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 * @version 1.1.1
 */

(function($) {

var hasIntrospection = (function(){_}).toString().indexOf('_') > -1,
	emptyBase = function() {};

$.inherit = function() {

	var withMixins = $.isArray(arguments[0]),
		hasBase = $.isFunction(arguments[0]) || withMixins,
		base = hasBase? withMixins? arguments[0][0] : arguments[0] : emptyBase,
		props = arguments[hasBase? 1 : 0] || {},
		staticProps = arguments[hasBase? 2 : 1],
		result = props.__constructor || base.prototype.__constructor?
			function() {
				this.__constructor.apply(this, arguments);
			} : function() {};

	if(!hasBase) {
		result.prototype = props;
		result.prototype.__self = result.prototype.constructor = result;
		return $.extend(result, staticProps);
	}

	var inheritance = function() {};

	$.extend(result, base, staticProps);

	inheritance.prototype = base.prototype;
	result.prototype = new inheritance();
    var resultPtp = result.prototype;
	resultPtp.__self = resultPtp.constructor = result;

	var propList = [];
	$.each(props, function(i) {
		props.hasOwnProperty(i) && propList.push(i);
	});
	// fucking ie hasn't toString, valueOf in for
	$.each(['toString', 'valueOf'], function() {
		props.hasOwnProperty(this) && $.inArray(this, propList) == -1 && propList.push(this);
	});

	var basePtp = base.prototype;
	$.each(propList, function() {
		if(hasBase
			&& $.isFunction(basePtp[this]) && $.isFunction(props[this])
			&& (!hasIntrospection || props[this].toString().indexOf('.__base') > -1)) {

			(function(methodName) {
				var baseMethod = basePtp[methodName],
					overrideMethod = props[methodName];
				resultPtp[methodName] = function() {
					var baseSaved = this.__base;
					this.__base = baseMethod;
					var result = overrideMethod.apply(this, arguments);
					this.__base = baseSaved;
					return result;
				};
			})(this);

		}
		else {
			resultPtp[this] = props[this];
		}
	});

	if(withMixins) {
		var i = 1, mixins = arguments[0], mixin, __constructors = [];
		while(mixin = mixins[i++]) {
			$.each(mixin.prototype, function(propName) {
				if(propName == '__constructor') {
					__constructors.push(this);
				}
				else if(propName != '__self') {
					resultPtp[propName] = this;
				}
			});
		}
		if(__constructors.length > 0) {
			resultPtp.__constructor && __constructors.push(resultPtp.__constructor);
			resultPtp.__constructor = function() {
				var i = 0, __constructor;
				while(__constructor = __constructors[i++]) {
					__constructor.apply(this, arguments);
				}
			};
		}
	}

	return result;

};

})(jQuery);