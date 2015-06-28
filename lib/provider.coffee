proc = require 'child_process'

regexMethod = /function\s(\w+)/

module.exports =
  # This will work on JavaScript and CoffeeScript files, but not in js comments.
  selector: '.source.php'
  disableForSelector: '.source.php .comment'

  # This will take priority over the default provider, which has a priority of 0.
  # `excludeLowerPriority` will suppress any providers with a lower priority
  # i.e. The default provider will be suppressed
  inclusionPriority: 100
  excludeLowerPriority: true
  filterSuggestions: true

  # Required: Return a promise, an array of suggestions, or null.
  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    prefix = @getPrefix(editor,bufferPosition)
    new Promise (resolve) =>
        if @isLocalVariable(prefix)
            resolve(@getLocalMethods(editor,prefix))
        if objectType = @isKnownObject(editor,bufferPosition,prefix)
            @getObjectAvailableMethods(editor,prefix,objectType,resolve)

  isLocalVariable: (prefix,bufferPosition) ->
    prefix.match(/\$this->/)

  getLocalMethods: (editor,prefix) ->

    completions = []

    for line in editor.buffer.getLines()
        if matches = line.match(regexMethod)
            if matches[1].indexOf(prefix)

                methodMatches = matches.input.match(/(public|private|protected)?\s?(static)?\s?function\s\w+\((.*)\)/)
                visibility = methodMatches[1]
                isStatic = methodMatches[2]
                parametersString = methodMatches[3]
                
                completions.push(
                    text: matches[1]
                    snippet: @createMethodSnippet(matches[1],parametersString)
                    displayText: matches[1]
                    type: 'method'
                    leftLabel: "#{visibility}" 
                    className: "method-#{visibility}"
                )

    completions

  createMethodSnippet: (method,parametersString) ->

      parameters = parametersString.match(/\$\w+/g)

      if parameters 

          mapped = parameters.map(
            (item,index) -> 
                "${#{index+2}:#{item}}"
          ).join(',')

          "#{method}(#{mapped})${#{parameters.length+2}}" 


  isKnownObject: (editor,bufferPosition,prefix) ->
    currentMethodParams = @getMethodParams(editor,bufferPosition)

    for param in currentMethodParams
        unless param.objectType is undefined
            regex = "\\$"+param.varName.substr(1)+"\\-\\>"
            # console.log (new RegExp(regex)), prefix, regex
            return if prefix.match(regex) then param.objectType else false
 

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
                        if method.indexOf(prefix)
                            completions.push(
                                text: method,
                                displayText: method
                                type: 'method'
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
  getPrefix: (editor, bufferPosition) ->
    # Whatever your prefix regex might be
    regex = /[\$\w0-9>_-]+$/

    # Get the text for the line up to the triggered buffer position
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

    # Match the regex to the line, and return the match
    line.match(regex)?[0] or ''
