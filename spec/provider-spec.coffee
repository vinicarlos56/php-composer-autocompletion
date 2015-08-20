mockery = require 'mockery'
mockSpawn = require '/usr/local/lib/node_modules/mock-spawn'
provider = {}
spawn = {}

expectedCompletions = [{
    text: '__construct($test)',
    snippet: '__construct(${2:$test})${3}',
    displayText: '__construct($test)',
    type: 'method',
    leftLabel: 'undefined',
    className: 'method-undefined'
    isStatic: false
}, {
    text: 'firstMethod($firstParam, $secondParam)',
    snippet: 'firstMethod(${2:$firstParam},${3:$secondParam})${4}',
    displayText: 'firstMethod($firstParam, $secondParam)',
    type: 'method',
    leftLabel: 'public',
    className: 'method-public'
    isStatic: false
}, {
    text: 'secondParam(KnownObject $firstParam, Second $second)',
    snippet: 'secondParam(${2:$firstParam},${3:$second})${4}',
    displayText: 'secondParam(KnownObject $firstParam, Second $second)',
    type: 'method',
    leftLabel: 'public',
    className: 'method-public'
    isStatic: false
}, {
    text: 'thirdMethod(KnownObject $first, Second $second, Third $third)',
    snippet: 'thirdMethod(${2:$first},${3:$second},${4:$third})${5}',
    displayText: 'thirdMethod(KnownObject $first, Second $second, Third $third)',
    type: 'method',
    leftLabel: 'public',
    className: 'method-public'
    isStatic: false
}]

fullExpectedCompletions = [{
    text: '$publicVar',
    snippet: 'publicVar${2}',
    displayText: '$publicVar',
    type: 'property',
    leftLabel: 'public',
    className: 'method-public'
    isStatic: false
}, {
    text: '$publicStatic',
    snippet: 'publicStatic${2}',
    displayText: '$publicStatic',
    type: 'property',
    leftLabel: 'public static',
    className: 'method-public'
    isStatic: true
}, {
    text: '$privateVar',
    snippet: 'privateVar${2}',
    displayText: '$privateVar',
    type: 'property',
    leftLabel: 'private',
    className: 'method-private'
    isStatic: false
}, {
    text: '$protectedVar',
    snippet: 'protectedVar${2}',
    displayText: '$protectedVar',
    type: 'property',
    leftLabel: 'protected',
    className: 'method-protected'
    isStatic: false
}, {
    text: 'TEST',
    snippet: 'TEST${2}',
    displayText: 'TEST',
    type: 'constant',
    leftLabel: 'undefined',
    className: 'method-undefined'
    isStatic: false
}, {
    text: 'TESTINGCONSTANTS',
    snippet: 'TESTINGCONSTANTS${2}',
    displayText: 'TESTINGCONSTANTS',
    type: 'constant',
    leftLabel: 'undefined',
    className: 'method-undefined'
    isStatic: false
}, {
    text: '__construct($test)',
    snippet: '__construct(${2:$test})${3}',
    displayText: '__construct($test)',
    type: 'method',
    leftLabel: 'undefined',
    className: 'method-undefined'
    isStatic: false
}, {
    text: 'firstMethod($firstParam, $secondParam)',
    snippet: 'firstMethod(${2:$firstParam},${3:$secondParam})${4}',
    displayText: 'firstMethod($firstParam, $secondParam)',
    type: 'method',
    leftLabel: 'public',
    className: 'method-public'
    isStatic: false
}, {
    text: 'secondParam(KnownObject $firstParam, Second $second)',
    snippet: 'secondParam(${2:$firstParam},${3:$second})${4}',
    displayText: 'secondParam(KnownObject $firstParam, Second $second)',
    type: 'method',
    leftLabel: 'public',
    className: 'method-public'
    isStatic: false
}, {
    text: 'thirdMethod(KnownObject $first, Second $second, Third $third)',
    snippet: 'thirdMethod(${2:$first},${3:$second},${4:$third})${5}',
    displayText: 'thirdMethod(KnownObject $first, Second $second, Third $third)',
    type: 'method',
    leftLabel: 'public',
    className: 'method-public'
    isStatic: false
}]

describe "Provider suite", ->

    beforeEach ->
        providerPath = '../lib/provider'
        verbose = false
        spawn = mockSpawn(verbose)
        mockery.enable({ useCleanCache: true })
        mockery.registerMock('child_process', { spawn: spawn })
        mockery.registerAllowable(providerPath, true);

        provider = require providerPath


    afterEach ->
        mockery.deregisterAll()
        mockery.resetCache()
        mockery.disable()

    it "creates the method snippet correctly given the method and parameters string", ->

        fullMethodRegex = /(public|private|protected)?\s?(static)?\s?function\s(\w+)\((.*)\)/

        matches = "public function testMethod() {".match(fullMethodRegex)
        expect(provider.createMethodSnippet(matches))
            .toEqual('testMethod()${2}')

        matches = "public function testMethod($simpleParam) {".match(fullMethodRegex)
        expect(provider.createMethodSnippet(matches))
            .toEqual('testMethod(${2:$simpleParam})${3}')

        matches = "public function testMethod(Typed $simpleParam) {".match(fullMethodRegex)
        expect(provider.createMethodSnippet(matches))
            .toEqual('testMethod(${2:$simpleParam})${3}')

        matches = "public function testMethod($simpleParam, $secondParam) {".match(fullMethodRegex)
        expect(provider.createMethodSnippet(matches))
            .toEqual('testMethod(${2:$simpleParam},${3:$secondParam})${4}')

        matches = "public function testMethod($simpleParam, Typed $secondParam) {".match(fullMethodRegex)
        expect(provider.createMethodSnippet(matches))
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
            isStatic: false

        expect(provider.createCompletion(method)).toEqual(expected)

        method.isStatic = true
        expected.leftLabel = 'public static'
        expected.isStatic = true

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

        waitsForPromise ->
            atom.project.open('sample/sample-multiple.php').then (o) -> editor = o

        runs ->
            expect(provider.getLocalAvailableCompletions(editor)).toEqual(expectedCompletions)

    it "match current context", ->
        expect(provider.matchCurrentContext('$this->')).toNotEqual(null)
        expect(provider.matchCurrentContext('parent::')).toNotEqual(null)
        expect(provider.matchCurrentContext('self::')).toNotEqual(null)
        expect(provider.matchCurrentContext('static::')).toNotEqual(null)
        expect(provider.matchCurrentContext('other::')).toEqual(null)

    it "gets local available completions", ->

        editor = null
        local = []

        waitsForPromise ->
            atom.project.open('sample/sample-full.php').then (o) -> editor = o

        runs ->
            local = []

            expect(provider.getLocalAvailableCompletions(editor)).toEqual(fullExpectedCompletions)

    it "gets parent class name", ->

        editor = null

        waitsForPromise ->
            atom.project.open('sample/sample-var.php').then (o) -> editor = o

        runs ->
            expect(provider.getParentClassName(editor)).toEqual('\\SomeParent')

    it "creates method display text", ->

        expect(provider.createMethodDisplayText('not a method'))
            .toEqual(undefined)
        expect(provider.createMethodDisplayText('public function testMethod()'))
            .toEqual('testMethod()')
        expect(provider.createMethodDisplayText('public function testMethod($param)'))
            .toEqual('testMethod($param)')
        expect(provider.createMethodDisplayText('public function testMethod(Typed $param)'))
            .toEqual('testMethod(Typed $param)')
        expect(provider.createMethodDisplayText('public function testMethod(Typed $param, Second $param)'))
            .toEqual('testMethod(Typed $param, Second $param)')
        expect(provider.createMethodDisplayText('public function testMethod(Typed $param,Second $param)'))
            .toEqual('testMethod(Typed $param, Second $param)')
        expect(provider.createMethodDisplayText('public function testMethod(  Typed $param,      Second $param)'))
            .toEqual('testMethod(Typed $param, Second $param)')
        expect(provider.createMethodDisplayText('public function testMethod(  Typed $param,    Second $param,    Third  $p)'))
            .toEqual('testMethod(Typed $param, Second $param, Third $p)')

    it "executes the command correctly and returns the completions", ->

        resolve = (completions) ->
            expect(completions[0].text).toEqual('testMethod')

        lastMatch =
            input: '\\Obj as Teste;'

        spawn.sequence.add(spawn.simple(1,'[{"name":"testMethod"}]'))

        provider.fetchAndResolveDependencies(lastMatch,'$this->test',resolve)

        expect(spawn.calls.length).toEqual(1)
        expect(spawn.calls[0].command).toEqual('php')
        expect(spawn.calls[0].args).toEqual([provider.getScript(), provider.getAutoloadPath(), 'Obj'])
