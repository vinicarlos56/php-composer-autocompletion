proc = require 'child_process'

propertyRegex = /(private|protected|public)\s(static)?\s?\$(\w+)/
constantRegex = /const\s(\w+)/
methodRegex = /function\s(\w+)/
paramMethodRegex = /function\s\w+\(([\s\S]*)\)/
fullMethodRegex = /(public|private|protected)?\s?(static)?\s?function\s(\w+)\((.*)\)/
openFullMethodRegex = /(public|private|protected)?\s?(static)?\s?function\s\w+\(?(.*)?\)?/
methodDisplayTextRegex = /(public|private|protected)?\s?(static)?\s?function\s(\w+\s?\((.*)\))/

module.exports =
    # This will work on JavaScript and CoffeeScript files, but not in js comments.
    selector: '.source.php'
    disableForSelector: '.source.php .comment'

    # This will take priority over the default provider, which has a priority of 0.
    # `excludeLowerPriority` will suppress any providers with a lower priority
    # i.e. The default provider will be suppressed
    inclusionPriority: 0
    excludeLowerPriority: false 
    filterSuggestions: true

    # Required: Return a promise, an array of suggestions, or null.
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->

        prefix = @getPrefix(editor, bufferPosition)

        new Promise (resolve) =>
            if matches = @matchCurrentContext(prefix)
                if matches[0] == "$this->"

                    local = @getLocalAvailableCompletions(editor,prefix)

                    objectType = @getParentClassName(editor)

                    mergeWithLocal = (inheritedCompletions) ->
                        for completion in inheritedCompletions
                            completion.rightLabel = '(inherited)'
                            for localCompletion in local
                                if localCompletion.text == completion.text
                                    localCompletion.rightLabel = '(override)' # don't have to remove?

                        resolve(local.concat(inheritedCompletions))

                    @getObjectAvailableMethods(editor, prefix, objectType, mergeWithLocal)
                else if matches[0] == "parent::"
                    objectType = @getParentClassName(editor)
                    setAsInherited = (completions) ->
                        for completion in completions
                            completion.rightLabel = '(inherited)'

                        resolve(completions)

                    @getObjectAvailableMethods(editor, prefix, objectType, setAsInherited)
                else if matches[0] == "self::"
                    completions = @getLocalAvailableCompletions(editor).filter((item) -> item.isStatic)
                    resolve(completions)
            else if objectType = @isKnownObject(editor, bufferPosition, prefix)
                @getObjectAvailableMethods(editor, prefix, objectType, resolve)
            else
                resolve([])

    matchCurrentContext: (prefix) ->

        prefix.match(/(\$this->|parent::|self::|static::)/)

    getLocalAvailableCompletions: (editor) ->

        inline = []
        completions = []

        for line in editor.buffer.getLines()

            if inline.length == 0
                ma = null

            if inline.length > 0

                inline.push(line)

                ma = inline.join('').match(methodRegex)

                if ma
                    inline = []

            if matches = line.match(propertyRegex)
                completions.push(@createVariableCompletion(matches))
            else if matches = line.match(constantRegex)
                completions.push(@createConstantCompletion matches)
            else if matches = line.match(methodRegex) || ma
                methodMatches = matches.input.match(fullMethodRegex)

                if methodMatches is null
                    inline.push(matches.input)

                unless methodMatches is null
                    completions.push(@createMehodCompletion methodMatches)

        return completions

    createVariableCompletion: (matches) ->
        @createCompletion
            name: "$"+matches[3]
            snippet: "#{matches[3]}${2}"
            isStatic: matches[2] != undefined
            visibility: matches[1]
            type: 'property'

    createConstantCompletion: (matches) ->
        @createCompletion
            name: matches[1]
            snippet: "#{matches[1]}${2}"
            isStatic: false
            visibility: undefined
            type: 'constant'


    createMehodCompletion: (matches) ->
        @createCompletion
            name: @createMethodDisplayText matches.input
            snippet: @createMethodSnippet(matches)
            isStatic: matches[2] != undefined
            visibility: matches[1]
            type: 'method'


    createMethodSnippet: (matches) ->

        parameters = matches[4].match(/\$\w+/g)
        mapped = ''
        parametersLength = 0

        if parameters
            mapped = parameters.map((item,index) -> "${#{index+2}:#{item}}").join(',')
            parametersLength = parameters.length

        "#{matches[3]}(#{mapped})${#{parametersLength+2}}"

    createMethodDisplayText: (input) ->

        matches = input.match(methodDisplayTextRegex)

        unless matches is null

            formattedParams = matches[4].split(',').map(
                (item) ->
                    item.split(' ').filter(
                        (item) ->
                            item != ''
                    ).join(' ')
            ).join(', ')

            matches[3].replace matches[4], formattedParams


    isKnownObject: (editor,bufferPosition,prefix) ->

        currentMethodParams = @getMethodParams(editor,bufferPosition)

        unless currentMethodParams is undefined
            for param in currentMethodParams
                if prefix.indexOf(param.varName) == 0
                    unless param.objectType is undefined
                        regex = "\\$#{param.varName.substr(1)}\\-\\>"
                        return if prefix.match(regex) then param.objectType else false

    getMethodParams: (editor,bufferPosition) ->

        fullMethodString = @getFullMethodDefinition editor,bufferPosition
        parametersString = fullMethodString.match(paramMethodRegex)

        unless parametersString is null
            parametersSplited = parametersString[1].split(',')

            result = parametersSplited.map( (item) ->

                words = item.trim().split(' ')

                objectType: if words[1] then words[0] else undefined
                varName: if words[1] then words[1] else words[0]
            )

        result

    getFullMethodDefinition: (editor,bufferPosition) ->
        lines = editor.buffer.getLines()
        totalLines = lines.length

        inline = []

        for i in [bufferPosition.row...0]

            inline.push(lines[i])

            if matches = lines[i].match(methodRegex)
                fullMethodString = inline.reverse().reduce (previous,current) ->
                    previous.trim()+current.trim()

                if m = fullMethodString.match(fullMethodRegex)
                    return m[0]

         return ''



    getObjectAvailableMethods: (editor,prefix,objectType,resolve)->

        regex = /^use(.*)$/
        currentNamespace = ''

        for line in editor.buffer.getLines()

            if namespaceMatch = line.match(/namespace\s+(.+);/)
                currentNamespace += namespaceMatch[1]

            if matches = line.match(regex)
                isValid = matches[1].split('\\').map(
                    (item) ->
                        l = item.split(';')[0].split(' as ')
                        if l.length == 1
                            l[0] == objectType
                        else if l.length == 2
                            l[0] == objectType or l[1] == objectType

                ).filter(
                    (item) -> item == true
                )
                # console.log isValid, objectType, matches[1].match(objectType)
                if isValid.length > 0
                    return @fetchAndResolveDependencies(matches[1].match(objectType),prefix,resolve)

        if currentNamespace != ''
            fullName = currentNamespace+objectType
            return @fetchAndResolveDependencies(fullName,prefix,resolve)

        return resolve([])

    fetchAndResolveDependencies: (lastMatch, prefix, resolve) ->

        namespace = @parseNamespace(lastMatch)
        script = @getScript()
        autoload = @getAutoloadPath()

        # console.log namespace, script, autoload

        process = proc.spawn "php", [script, autoload, namespace]

        @compiled = ''
        @errorCompiled = ''
        @availableResources = []

        process.stdout.on 'data', (data) =>
            @compiled += data

        process.stderr.on 'data', (data) ->
            @errorCompiled += data

        process.on 'close', (code) =>
            try
                @availableResources = JSON.parse(@compiled)
                # console.log @availableResources

                completions = []

                for resource in @availableResources
                    if prefix.indexOf(resource.name)
                        completions.push(@createCompletion(resource))

                resolve(completions)
            catch error
                console.log error, code, @compiled, @errorCompiled

    getAutoloadPath: ->
        atom.project.getPaths()[0] + '/vendor/autoload.php'

    getScript: ->
        __dirname + '/../scripts/main.php'

    parseNamespace: (lastMatch) ->
        if typeof lastMatch is 'string'
            return lastMatch
        lastMatch.input.substring(1,lastMatch.input.length - 1).split(' as ')[0]

    createCompletion: (completion) ->
        text: completion.name,
        snippet: completion.snippet,
        displayText: completion.name,
        type: completion.type ? 'method',
        leftLabel: "#{completion.visibility}#{if completion.isStatic then ' static' else ''}",
        className: "method-#{completion.visibility}"
        isStatic: completion.isStatic


    getParentClassName: (editor) ->

        namespace = ''

        for line in editor.buffer.getLines()

            # namespaceMatch = line.match(/namespace\s+(.+);/)
            #
            # if namespaceMatch
            #     namespace = namespaceMatch[1]

            classMatch = line.match(/class\s\w+\s?extends?\s?(\w+)?/)

            unless classMatch is null
                return "\\#{classMatch[1]}"

    # (optional): called _after_ the suggestion `replacementPrefix` is replaced
    # by the suggestion `text` in the buffer
    onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
        # console.log triggerPosition, suggestion

    # (optional): called when your provider needs to be cleaned up. Unsubscribe
    # from things, kill any processes, etc.
    dispose: ->

    getPrefix: (editor, bufferPosition) ->
        # Whatever your prefix regex might be
        regex = /[\$\w0-9:>_-]+$/

        # Get the text for the line up to the triggered buffer position
        line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

        # Match the regex to the line, and return the match
        line.match(regex)?[0] or ''
