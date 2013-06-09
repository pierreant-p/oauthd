# oauthd
# http://oauth.io
#
# Copyright (c) 2013 thyb, bump
# Licensed under the MIT license.

_check = (arg, format, errors) ->
	if format instanceof RegExp
		return typeof arg == 'string' && arg.match(format)

	if Array.isArray(format)
		for possibility in format
			return true if _check arg, possibility
		return false

	if typeof format == 'object'
		if arg? && typeof arg == 'object'
			success = true
			for k,v of format
				if not _check arg[k], v
					if errors?
						errors[k] = 'Invalid format'
						success = false
					else
						return false
			return success
		return false

	return !format ||
		format == 'any' && arg? ||
		format == 'none' && not arg? ||
		format == 'null' && arg == null ||
		format == 'string' && typeof arg == 'string' ||
		format == 'regexp' && arg instanceof RegExp ||
		format == 'object' && arg? && typeof arg == 'object' ||
		format == 'function' && typeof arg == 'function' ||
		format == 'array' && Array.isArray(arg) ||
		format == 'number' && (arg instanceof Number || typeof arg == 'number') ||
		format == 'int' && (parseFloat(arg) == parseInt(arg)) && !isNaN(arg) ||
		format == 'bool' && (arg instanceof Boolean || typeof arg == 'boolean') ||
		format == 'date' && arg instanceof Date

_clone = (item) ->
	return item if not item?
	return Number item if item instanceof Number
	return String item if item instanceof String
	return Boolean item if item instanceof Boolean

	if Array.isArray(item)
		result = []
		for index, child of item
			result[index] = _clone child
		return result

	if typeof item == "object" && ! item.prototype
		result = {}
		for i of item
			result[i] = _clone item[i]
		return result

	return item


# Error class

class CheckError extends Error
	constructor: ->
		Error.captureStackTrace @, @constructor
		@message = "Invalid format"
		@body = {}
		if arguments.length == 1
			@message = arguments[0]
		else if arguments.length
			@status = "fail"
			@body[arguments[0]] = arguments[1]
		super @message
	check: (name, arg, format) ->
		@status = "fail"
		return _check name, arg, @body if arguments.length == 2 # args=name, format=arg
		o = {}; f = {}
		o[name] = arg; f[name] = format
		_check o, f, @body
	error: (@message) -> @status = "error"
	failed: -> Object.keys(@body).length || @status == "error"


# Exports

check = ->
	checked = Array.prototype.pop.call arguments, arguments
	formats = arguments
	return =>
		args = Array.prototype.slice.call arguments
		callback = args.pop()
		if args.length != formats.length
			return callback new CheckError 'Bad parameters count'
		error = new CheckError
		for i,argformat of formats
			if not error.check(args[i], argformat) and not error.failed()
				error.error 'Bad parameters format'
		return callback error if error.failed()
		return checked.apply @, arguments

check.clone = (cloned) -> =>
	return cloned.apply @, _clone arguments

check.Error = CheckError
check.nullv = {} # this means a null

check.format =
	mail: /^[a-zA-Z0-9._%\-\+]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
	provider: /^[a-zA-Z0-9._\-]{2,}$/
	key: /^[a-zA-Z0-9\-_]{23,27}$/

module.exports = check
