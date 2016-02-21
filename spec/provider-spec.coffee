mockery = require 'mockery'
mockSpawn = require 'mock-spawn'
fs = require 'fs'
provider = {}
spawn = {}

providerPath = '../lib/provider'

expectedCompletions = JSON.parse fs.readFileSync __dirname+'/expected-completions.json', 'utf8'
fullExpectedCompletions =  JSON.parse fs.readFileSync __dirname+'/full-expected-completions.json', 'utf-8'

describe "Provider suite", ->

    beforeEach ->
        verbose = false
        spawn = mockSpawn(verbose)
        mockery.enable({ useCleanCache: true })
        mockery.registerMock('child_process', { spawn: spawn })
        mockery.registerAllowable(providerPath, true)
        mockery.warnOnUnregistered(false)

        provider = require providerPath
        @script = provider.getScript()
        @autoload = provider.getAutoloadPath()


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
            atom.workspace.open(__dirname + '/sample/sample.php',initialLine: 13).then (o) -> editor = o

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
            atom.workspace.open(__dirname + '/sample/sample.php',initialLine: 18).then (o) -> editor = o

        runs ->

            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.isKnownObject(editor,bufferPosition,'$firstParam->')).toEqual('KnownObject')

            editor.setCursorBufferPosition([18, 0])
            expect(provider.isKnownObject(editor,bufferPosition,'$second->')).toEqual('Second')

    it "parses the namespace", ->

        regex = /^use(.*)$/
        namespace = 'use Object\\Space;'
        namespaceWithAlias = 'use Object\\Space as Space;'
        objectType = 'Space'

        expect(provider.parseNamespace(namespace.match(regex)[1].match(objectType)))
            .toEqual('Object\\Space')

        expect(provider.parseNamespace(namespaceWithAlias.match(regex)[1].match(objectType)))
            .toEqual('Object\\Space')

        objectTypeAlias = 'ObjAlias'
        namespaceWithAnotherAlias = 'use Object\\Space as ObjAlias;'
        expect(provider.parseNamespace(namespaceWithAnotherAlias.match(regex)[1].match(objectTypeAlias)))
            .toEqual('Object\\Space')

    it "gets full method definition", ->
        editor = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-multiple.php',initialLine: 25).then (o) -> editor = o

        runs ->

            bufferPosition = editor.getLastCursor().getBufferPosition()

            expect(provider.getFullMethodDefinition(editor,bufferPosition))
                .toEqual('public function thirdMethod(KnownObject $first,Second $second,Third $third)')

            editor.setCursorBufferPosition([2, 0])
            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.getFullMethodDefinition(editor,bufferPosition))
                .toEqual('')

            editor.setCursorBufferPosition([18, 0])
            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.getFullMethodDefinition(editor,bufferPosition))
                .toEqual('public function secondParam(KnownObject $firstParam, Second $second)')

            editor.setCursorBufferPosition([13, 0])
            bufferPosition = editor.getLastCursor().getBufferPosition()
            expect(provider.getFullMethodDefinition(editor,bufferPosition))
                .toEqual('public function firstMethod($firstParam,$secondParam)')

    it "matches multiple line method definition correctly", ->
        editor = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-multiple.php',initialLine: 25).then (o) -> editor = o

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
            atom.workspace.open(__dirname + '/sample/sample-multiple.php').then (o) -> editor = o

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
            atom.workspace.open(__dirname + '/sample/sample-full.php').then (o) -> editor = o

        runs ->
            local = []

            expect(provider.getLocalAvailableCompletions(editor)).toEqual(fullExpectedCompletions)

    it "gets parent class name", ->

        editor = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-var.php').then (o) -> editor = o

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

            expect(completions.length).toEqual(3)

            expect(completions[0].text).toEqual('testMethod($param)')
            expect(completions[0].snippet).toEqual('testMethod(${2:$param})${3}')
            expect(completions[0].displayText).toEqual('testMethod($param)')
            expect(completions[0].type).toEqual('method')
            expect(completions[0].leftLabel).toEqual('public')
            expect(completions[0].className).toEqual('method-public')
            expect(completions[0].isStatic).toEqual(false)

            expect(completions[1].text).toEqual('$pro')
            expect(completions[1].snippet).toEqual('$pro${2}')
            expect(completions[1].displayText).toEqual('$pro')
            expect(completions[1].type).toEqual('property')
            expect(completions[1].leftLabel).toEqual('public')
            expect(completions[1].className).toEqual('method-public')
            expect(completions[1].isStatic).toEqual(false)

            expect(completions[2].text).toEqual('TEST')
            expect(completions[2].snippet).toEqual('TEST${2}')
            expect(completions[2].displayText).toEqual('TEST')
            expect(completions[2].type).toEqual('constant')
            expect(completions[2].leftLabel).toEqual('undefined')
            expect(completions[2].className).toEqual('method-undefined')
            expect(completions[2].isStatic).toEqual(undefined)

        prefix = '$this->test' # does not make any difference on the results
        lastMatch =
            input: '\\Obj as Teste;'

        methodJson = '{"name":"testMethod($param)","visibility":"public","snippet":"testMethod(${2:$param})${3}","isStatic":false,"type":"method"}'
        propertyJson = '{"name":"$pro","visibility":"public","snippet":"$pro${2}","isStatic":false,"type":"property"}'
        constantJson = '{"name":"TEST","snippet":"TEST${2}","type":"constant"}'

        spawn.sequence.add(spawn.simple(1,"[#{methodJson},#{propertyJson},#{constantJson}]"))

        provider.fetchAndResolveDependencies(lastMatch,prefix,resolve)

        expect(spawn.calls.length).toEqual(1)
        expect(spawn.calls[0].command).toEqual('php')
        expect(spawn.calls[0].args).toEqual([@script, @autoload, 'Obj'])


    it "does not get object available methods because no namespace was provided", ->

        editor = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample.php').then (o) -> editor = o

        runs ->
            prefix = ''
            objectType = 'Test'

            resolve = (completions) ->
                expect(completions).toEqual([])

            provider.getObjectAvailableMethods(editor,prefix,objectType,resolve)

    it "tries to find the non aliased object used correctly", ->

        editor = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-use.php').then (o) -> editor = o

        runs ->

            resolve = (completions) ->
                expect(completions.length).toEqual(0)

            prefix = '' # does not make any difference on the results
            objectType = 'KnownObject'

            spawn.sequence.add(spawn.simple(1,"[]"))

            provider.getObjectAvailableMethods(editor,prefix,objectType,resolve)

            expectedNamespace = 'Some\\Name\\KnownObject'
            expect(spawn.calls.length).toEqual(1)
            expect(spawn.calls[0].command).toEqual('php')
            expect(spawn.calls[0].args).toEqual([@script, @autoload, expectedNamespace])

    it "tries to find the aliased object used correctly", ->

        editor = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-use.php').then (o) -> editor = o

        runs ->

            resolve = (completions) ->
                expect(completions.length).toEqual(0)

            prefix = '' # does not make any difference on the results
            objectType = 'Aliased'

            spawn.sequence.add(spawn.simple(1,"[]"))

            provider.getObjectAvailableMethods(editor,prefix,objectType,resolve)

            expectedNamespace = 'Some\\Name\\Second'
            expect(spawn.calls.length).toEqual(1)
            expect(spawn.calls[0].command).toEqual('php')
            expect(spawn.calls[0].args).toEqual([@script, @autoload, expectedNamespace])

    it "falls back to current namespace when used object's namespace is not declared", ->

        editor = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-use.php').then (o) -> editor = o

        runs ->

            resolve = (completions) ->
                expect(completions.length).toEqual(0)

            prefix = '' # does not make any difference on the results

            objectType = 'Third'
            spawn.sequence.add(spawn.simple(1,"[]"))

            provider.getObjectAvailableMethods(editor,prefix,objectType,resolve)

            expectedNamespace = 'Full\\Name\\Space\\Third'

            expect(spawn.calls.length).toEqual(1)
            expect(spawn.calls[0].command).toEqual('php')
            expect(spawn.calls[0].args).toEqual([@script, @autoload, expectedNamespace])

            objectTypeWhithSlash = '\\Third'

            provider.getObjectAvailableMethods(editor,prefix,objectTypeWhithSlash,resolve)

            expect(spawn.calls.length).toEqual(2)
            expect(spawn.calls[1].command).toEqual('php')
            expect(spawn.calls[1].args).toEqual([@script, @autoload, expectedNamespace])

            objectTypeAliasedIncorrectly = '\\Second'
            expectedFallBackNamespace = 'Full\\Name\\Space\\Second'

            provider.getObjectAvailableMethods(editor,prefix,objectTypeAliasedIncorrectly,resolve)

            expect(spawn.calls.length).toEqual(3)
            expect(spawn.calls[2].command).toEqual('php')
            expect(spawn.calls[2].args).toEqual([@script, @autoload, expectedFallBackNamespace])


    it "should return no completions when the prefix does not match", ->

        editor = null
        promise = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample.php').then (o) -> editor = o

        waitsForPromise ->

            scopeDescriptor = null
            prefix = null

            editor.setTextInBufferRange([[18,0],[18,7]], 'test')
            editor.setCursorBufferPosition([18,7])
            bufferPosition = editor.getLastCursor().getBufferPosition()

            provider.getSuggestions({editor, bufferPosition, scopeDescriptor, prefix}).then (p) ->
                promise = p

        runs ->
            expect(promise).toEqual []

    it "should return local completions correctly", ->

        editor = null
        promise = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-multiple.php').then (o) -> editor = o

        waitsForPromise ->

            scopeDescriptor = null
            prefix = null

            editor.setTextInBufferRange([[18,0],[18,7]], '$this->')
            editor.setCursorBufferPosition([18,7])
            bufferPosition = editor.getLastCursor().getBufferPosition()

            provider.getSuggestions({editor, bufferPosition, scopeDescriptor, prefix}).then (p) ->
                promise = p

        runs ->
            expect(promise.length).toEqual 4
            expect(promise).toEqual expectedCompletions

    it "should return self static completions correctly", ->

        editor = null
        promise = null

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-full-static.php').then (o) -> editor = o

        waitsForPromise ->

            scopeDescriptor = null
            prefix = null

            editor.setTextInBufferRange([[23,0],[23,7]], 'self::')
            editor.setCursorBufferPosition([23,7])
            bufferPosition = editor.getLastCursor().getBufferPosition()

            provider.getSuggestions({editor, bufferPosition, scopeDescriptor, prefix}).then (p) ->
                promise = p

        runs ->
            expected = JSON.parse fs.readFileSync __dirname+'/expected-static-completions.json', 'utf-8'
            expect(promise.length).toEqual 2
            expect(promise).toEqual expected

    xit "should return parent completions correctly showing inherited and override with $this-> prefix", ->

        editor = null
        promise = null

        # real test case,no mock at this point
        mockery.deregisterAll()
        mockery.resetCache()
        mockery.disable()

        provider = require providerPath

        waitsForPromise ->
            atom.workspace.open(__dirname + '/sample/sample-full.php').then (o) -> editor = o

        waitsForPromise ->

            scopeDescriptor = null
            prefix = null

            editor.setTextInBufferRange([[20,0],[20,7]], '$this->')
            editor.setCursorBufferPosition([20,7])
            bufferPosition = editor.getLastCursor().getBufferPosition()

            provider.setAutoloadPath __dirname+'/sample/autoload.php'
            provider.getSuggestions({editor, bufferPosition, scopeDescriptor, prefix}).then (p) ->
                promise = p

        runs ->

            expected = JSON.parse fs.readFileSync __dirname+'/expected-parent-completions.json', 'utf-8'
            expect(promise.length).toEqual 13
            expect(promise).toEqual expected
