LocalThemeManager = require '../lib/local-theme-manager'
Utils = require '../lib/utils'
$ = jQuery = require 'jquery'
fs = require 'fs'
path = require 'path'

# A helper method to setup '<atom-text-editor>' test enviornment.
# We call this core environment, and then add or subtract from it in
# each describe block.
buildEditorTestEvironment = () ->
  textEditor = atom.workspace.buildTextEditor()

  # create some "pad" style elements that precede the the theme's style element
  # we use 'spellCheck' and 'gutter' just because these are two actual shadowRootatomStyles
  # that are attached to text-editor
  spellCheckStyle = document.createElement('style')
  spellCheckStyle.setAttribute('source-path', '/tmp/.atom/packages/spellCheck/index.less')
  spellCheckStyle.setAttribute('priority', '0')

  gutterStyle = document.createElement('style')
  gutterStyle.setAttribute('source-path', '/tmp/.atom/packages/gutter/gutter.less')
  gutterStyle.setAttribute('priority', '0')

  themeStyle = document.createElement('style')
  themeStyle.setAttribute('source-path', '/tmp/.atom/packages/test-theme/index.less')
  themeStyle.setAttribute('priority', '1')

  textEditor.getElement().shadowRoot.querySelector('atom-styles').appendChild(spellCheckStyle)
  textEditor.getElement().shadowRoot.querySelector('atom-styles').appendChild(gutterStyle)
  textEditor.getElement().shadowRoot.querySelector('atom-styles').appendChild(themeStyle)

  textEditorSpy = spyOn(atom.workspace, "getActiveTextEditor")
  .andReturn(textEditor)

  # return to caller so they can then use in "expect" statements
  textEditor

describe 'LocalThemeManager', () ->
  beforeEach ->
    @localThemeManager = new LocalThemeManager()
    @utils = new Utils()

    packageManager = atom.packages
    mySpy = spyOn(packageManager, "getActivePackages")
    mySpy.andReturn([ { metadata: { theme: "syntax", name: "test-syntax-theme"}}])

    textEditor = atom.workspace.buildTextEditor()
    atom.workspace.buildTextEditor()
    themeStyle = document.createElement('style')
    themeStyle.setAttribute('source-path', '/tmp/.atom/packages/test-theme/index.less')
    textEditor.getElement().shadowRoot.querySelector('atom-styles').appendChild(themeStyle)

    textEditorSpy = spyOn(atom.workspace, "getActiveTextEditor")
      .andReturn(@textEditor)

  it 'ctor works', () ->
    expect(@localThemeManager.utils).toBeInstanceOf(Utils)

  it 'doIt works', () ->
    # console.log('local-theme-manager-spec.doIt: getActivePackages=' + atom.packages.getActivePackages)
    atom.packages.getActivePackages()
    expect(@localThemeManager.doIt()).toEqual 7

  it 'getActiveSyntaxTheme returns proper theme', () ->
    expect(@localThemeManager.getActiveSyntaxTheme()).toEqual("test-syntax-theme")

  xit 'getThemeCss does promises correctly', () ->
    # hook fs.readFile to return a string without doing io
    cssSnippet = """
atom-text-editor, :host {
  background-color: #e3d5c1;
  color: #000000;
    """
    spyOn(fs, "readFile").andReturn(cssSnippet)

    promise = @localThemeManager.getThemeCss('/home/vturner/.atom/packages/humane-syntax')

    expect(promise).toBeInstanceOf(Promise)

    cssResult = null

    promise
      .then(
        (result) ->
          cssResult = result
          expect(cssResult).not.toBeNull()
        ,(err) ->
          console.log "promise returner err" + err
      )

# here we test a more "real" style tree attached to the mock editor
describe 'LocalThemeManager with complex atom-text-editor style tree', () ->
  beforeEach ->
    @localThemeManager = new LocalThemeManager()
    @utils = new Utils()

    packageManager = atom.packages
    mySpy = spyOn(packageManager, "getActivePackages")
    mySpy.andReturn([ { metadata: { theme: "syntax", name: "test-syntax-theme"}}])

    @textEditor = buildEditorTestEvironment()

  it 'deleteThemeStyleNode works', () ->
    @localThemeManager.deleteThemeStyleNode()

    shadowRoot = @utils.getActiveShadowRoot()
    expect($(shadowRoot).find('atom-styles').find('style').length).toEqual(2)
    expect($(shadowRoot)
      .find('atom-styles')
      .find('style')
      .eq(0)
      .attr('source-path')).toMatch("spellCheck")

    expect($(shadowRoot)
      .find('atom-styles')
      .find('style')
      .eq(1)
      .attr('source-path')).toMatch("gutter")

  it 'addStyleElementToEditor', () ->
    # create a simple style node to append
    styleElement = $('<style>')
      .attr('source-path', '/tmp/dummy-path')
      .attr('context', 'atom-text-editor')
      .attr('priority', '1')

    @localThemeManager.addStyleElementToEditor(styleElement)

    shadowRoot = @utils.getActiveShadowRoot()
    expect($(shadowRoot).find('atom-styles').find('style').length).toEqual(4)

  # this is too hard to unit-test.  The code is expecting the bg color to be
  # at this location:
  #bgColor = node3[0].sheet.rules[0].style.backgroundColor
  # and I don't want to set that up
  xit 'syncEditorBackgroundColor works', () ->
    console.log('syncEditorBackgroundColor: @textEditor=' + @textEditor)

describe "LocalThemeManager getSyntaxThemeLookup tests", () ->
   packageMetadataMock = []
   packageMetadataMock.push {name: 'atom-beautify'}
   packageMetadataMock.push {name: 'choco', theme: 'syntax'}
   packageMetadataMock.push {name: 'humane-syntax', theme: 'syntax'}

   packagePathsMock = []
   packagePathsMock.push "/home/user/.atom/packages/atom-beautify"
   packagePathsMock.push "/home/user/.atom/packages/choco"
   packagePathsMock.push "/home/user/.atom/packages/humane-syntax"

   beforeEach ->
     @localThemeManager = new LocalThemeManager()

     spyOn(atom.packages, "getAvailablePackageMetadata")
       .andReturn(packageMetadataMock)
     spyOn(atom.packages, "getAvailablePackagePaths")
       .andReturn(packagePathsMock)

   it 'getSyntaxThemeLookup works', ->
     result = @localThemeManager.getSyntaxThemeLookup()

     expect(result).toBeInstanceOf(Array)
     expect(result.length).toEqual(2)
     expect(result[0].themeName).toEqual("choco")
     expect(result[0].baseDir).toEqual("/home/user/.atom/packages/choco")
