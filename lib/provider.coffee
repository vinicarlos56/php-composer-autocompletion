proc = require 'child_process'

regexMethod = /function\s(\w+)/

module.exports =
  # This will work on JavaScript and CoffeeScript files, but not in js comments.
  selector: '.source.php'
  disableForSelector: '.source.php .comment'

  # This will take priority over the default provider, which has a priority of 0.
  # `excludeLowerPriority` will suppress any providers with a lower priority
  # i.e. The default provider will be suppressed
  inclusionPriority: 1
  excludeLowerPriority: true

  # Required: Return a promise, an array of suggestions, or null.
  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    new Promise (resolve) =>
        if @isLocalVariable(prefix)
            resolve(@getLocalMethods(editor,prefix))
        if objectType = @isKnownObject(editor,bufferPosition,prefix)
            @getObjectAvailableMethods(editor,prefix,objectType,resolve)

  isLocalVariable: (prefix) ->
    matches = prefix.match(/$$/)
    matches and matches.input == 'this'

  getLocalMethods: (editor,prefix) ->
    completions = []

    for line in editor.buffer.getLines()
        if matches = line.match(regexMethod)
            completions.push(
                text: prefix + '->' + matches[1]
                displayText: matches[1]
                type: 'function'
            )

    completions

  isKnownObject: (editor,bufferPosition,prefix) ->
    currentMethodParams = @getMethodParams(editor,bufferPosition)

    for param in currentMethodParams
        unless param.objectType is undefined
            return if param.varName.substr(1) == prefix then param.objectType else false
 

  getMethodParams: (editor,bufferPosition) ->

    lines = editor.buffer.getLines()
    totalLines = lines.length

    for i in [bufferPosition.row...0]
      if matches = lines[i].match(regexMethod) 
          parametersString = matches.input.match(/function\s\w+\((.*)\)/)
          parametersSplited = parametersString[1].split(',')
          result = parametersSplited.map( (item) ->
            words = item.split(' ')

            objectType: if words[1] then words[0] else undefined
            varName: if words[1] then words[1] else words[0]
          )

          return result

  getObjectAvailableMethods: (editor,prefix,objectType,resolve)->

      regex = /^use(.*)$/

      for line in editor.buffer.getLines()
        if matches = line.match(regex) 
          if lastMatch = matches[1].match(objectType)

            namespace = lastMatch.input.substring(1,lastMatch.input.length - 1)

            str = __dirname + '/../scripts/main.php '
            autoload = '~/projects/laravel/vendor/autoload.php '
           
            # console.log [str+autoload+'\''+namespace+'\'']
            process = proc.exec '/usr/bin/php '+str+autoload+'\''+namespace+'\'' 

            @compiled = ''
            @methods = [] 
            process.stdout.on 'data', (data) =>
                @compiled += data

            process.stderr.on 'data', (data) ->
                console.log 'err: ' + data

            process.on 'close', (code) =>
                try
                    @methods = JSON.parse(@compiled)

                    completions = []

                    for method in @methods
                        completions.push(
                            text: prefix + '->' + method,
                            displayText: method
                            type: 'function'
                        ) 

                    resolve(completions)
                catch error
                    console.log error 

            break
      
  # (optional): called _after_ the suggestion `replacementPrefix` is replaced
  # by the suggestion `text` in the buffer
  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  # (optional): called when your provider needs to be cleaned up. Unsubscribe
  # from things, kill any processes, etc.
  dispose: ->

  # loadCompletions: ->
