module.exports =
  config:
    hoge:
      type: 'number'
    accessToken:
      type: 'string'

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    #@subscriptions = new CompositeDisposable
    #@subscriptions.add atom.commands.add 'atom-workspace', 'image-copipe:activate': => @attachEvent()
    @attachEvent()

  attachEvent: ->
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.addEventListener 'keydown', (e) =>
      # 雑に cmd + paste を判定
      if (e.metaKey && e.keyCode == 86)
        # clipboard から画像取得
        clipboard = require('clipboard')
        img = clipboard.readImage()
        return if img.isEmpty()

        # insert loading text
        editor = atom.workspace.getActiveEditor()
        range = editor.insertText('Uploading...');
        @post img, (imgUrl) ->
          # replace loading text to markdown img format
          markdown = "![](#{imgUrl})"
          editor.setTextInBufferRange(range[0], markdown)

  post: (img, callback) ->
    # gyazoにupload
    req = require('request')
    options = {
      uri: 'https://upload.gyazo.com/api/upload'
      formData: {
        access_token: atom.config.get('image-copipe.accessToken') || '55de220ab12e95cc0885634bc0713886815f79805373a614efd8da7bd806c768'
        imagedata: img.toPng()
      }
      json: true
    }
    req.post options, (error, response, body) ->
      if (!error && response.statusCode == 200)
        callback(body.url) if callback && body.url
      else
        console.log('error: '+ response.statusCode)
