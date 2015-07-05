provider = require '../lib/provider'
expectedCompletions = [{
    text : '__construct',
    snippet : '__construct(${2:$test})${3}',
    displayText : '__construct',
    type : 'method',
    leftLabel : 'undefined',
    className : 'method-undefined'
},
{
    text : 'firstMethod',
    snippet : 'firstMethod(${2:$firstParam},${3:$secondParam})${4}',
    displayText : 'firstMethod',
    type : 'method',
    leftLabel : 'public',
    className : 'method-public'
},
{
    text : 'secondParam',
    snippet : 'secondParam(${2:$firstParam},${3:$second})${4}',
    displayText : 'secondParam',
    type : 'method',
    leftLabel : 'public',
    className : 'method-public'
}]

describe "Provider suite", ->
    it "should return the match array if it is a local variable prefix", ->
        expect(provider.isLocalVariable('')).toBe(null)
        expect(provider.isLocalVariable('test')).toBe(null)
        expect(provider.isLocalVariable('$this')).toBe(null)
        expect(provider.isLocalVariable('$this->')).toEqual(['$this->'])

    it "creates the method snippet correctly given the method and parameters string", ->

        expect(provider.createMethodSnippet('testMethod',''))
            .toEqual('testMethod()${2}')

        expect(provider.createMethodSnippet('testMethod','$simpleParam'))
            .toEqual('testMethod(${2:$simpleParam})${3}')

        expect(provider.createMethodSnippet('testMethod','Typed $simpleParam'))
            .toEqual('testMethod(${2:$simpleParam})${3}')

        expect(provider.createMethodSnippet('testMethod','$simpleParam, $secondParam'))
            .toEqual('testMethod(${2:$simpleParam},${3:$secondParam})${4}')

        expect(provider.createMethodSnippet('testMethod','$simpleParam, Typed $secondParam'))
            .toEqual('testMethod(${2:$simpleParam},${3:$secondParam})${4}')

    it "gets the params for the current method", ->
        editor = null

        waitsForPromise ->
            atom.project.open('sample/sample.php',initialLine: 13).then (o) -> editor = o

        runs ->
            expected = [{
                objectType:undefined,
                varName:'$firstParam'
            },{
                objectType:undefined,
                varName:'$secondParam'
            }]

            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.getMethodParams(editor,bufferPosition)).toEqual(expected)

            editor.setCursorBufferPosition([0, 0])

            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.getMethodParams(editor,bufferPosition)).toEqual(undefined)

            editor.setCursorBufferPosition([18, 0])
            bufferPosition = editor.getLastCursor().getBufferPosition()
            expected[0].objectType = 'KnownObject'
            expected[1].objectType = 'Second'
            expected[1].varName = '$second'
            expect(provider.getMethodParams(editor,bufferPosition)).toEqual(expected)

            # bufferPosition = editor.getLastCursor().getBufferPosition()
            # expect(provider.getMethodParams(editor,bufferPosition)).toEqual(undefined)

    it "creates completion", ->
        method =
            name: 'test'
            snippet: 'snippetTest'
            visibility: 'public'
            isStatic: false

        expected =
            text: 'test'
            snippet: 'snippetTest'
            displayText: 'test'
            type: 'method'
            leftLabel: 'public'
            className: 'method-public'

        expect(provider.createCompletion(method)).toEqual(expected)

        method.isStatic = true
        expected.leftLabel = 'public static'

        expect(provider.createCompletion(method)).toEqual(expected)

    it "knows the object", ->
        editor = null

        waitsForPromise ->
            atom.project.open('sample/sample.php',initialLine: 18).then (o) -> editor = o

        runs ->

            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.isKnownObject(editor,bufferPosition,'$firstParam->')).toEqual('KnownObject')

            editor.setCursorBufferPosition([18, 0])
            expect(provider.isKnownObject(editor,bufferPosition,'$second->')).toEqual('Second')

    it "gets local methods", ->
        editor = null

        waitsForPromise ->
            atom.project.open('sample/sample.php').then (o) -> editor = o

        runs ->
            expect(provider.getLocalMethods(editor)).toEqual(expectedCompletions)

    it "parses the namespace", ->

        regex = /^use(.*)$/
        namespace = 'use Object\\Space;'
        namespaceWithAs = 'use Object\\Space as Space;'
        objectType = 'Space'

        expect(provider.parseNamespace(namespace.match(regex)[1].match(objectType)))
            .toEqual('Object\\Space')

        expect(provider.parseNamespace(namespaceWithAs.match(regex)[1].match(objectType)))
            .toEqual('Object\\Space')

    it "gets full method definition", ->
        editor = null

        waitsForPromise ->
            atom.project.open('sample/sample-multiple.php',initialLine: 25).then (o) -> editor = o

        runs ->

            bufferPosition = editor.getLastCursor().getBufferPosition()

            expect(provider.getFullMethodDefinition(editor,bufferPosition))
                .toEqual('public function thirdMethod(KnownObject $first,Second $second,Third $third)')

            editor.setCursorBufferPosition([2, 0])
            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.getFullMethodDefinition(editor,bufferPosition))
                .toEqual('')

    it "matches multiple line method definition correctly", ->
        editor = null

        waitsForPromise ->
            atom.project.open('sample/sample-multiple.php',initialLine: 25).then (o) -> editor = o

        runs ->

            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.isKnownObject(editor,bufferPosition,'$first->')).toEqual('KnownObject')

            editor.setCursorBufferPosition([25, 0])
            expect(provider.isKnownObject(editor,bufferPosition,'$second->')).toEqual('Second')

            editor.setCursorBufferPosition([25, 0])
            expect(provider.isKnownObject(editor,bufferPosition,'$third->')).toEqual('Third')

    it "gets local methods correctly with multiline method definition", ->
        editor = null

        expectedCompletions.push
            text : 'thirdMethod',
            snippet : 'thirdMethod(${2:$first},${3:$second},${4:$third})${5}',
            displayText : 'thirdMethod',
            type : 'method',
            leftLabel : 'public',
            className : 'method-public'

        waitsForPromise ->
            atom.project.open('sample/sample-multiple.php').then (o) -> editor = o

        runs ->
            # console.log provider.getLocalMethods(editor)
            expect(provider.getLocalMethods(editor)).toEqual(expectedCompletions)


