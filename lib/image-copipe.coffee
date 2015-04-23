module.exports =
  config:
    gyazoAccessToken:
      type: 'string'
      default: ''

  # packageが有効であれば、まず最初にこの関数が呼ばれる。
  # package.jsonにactivationCommandsが定義されていれば、そのコマンドが実行されるまで遅延される。
  activate: (state) ->
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

        # スクリーンショットではなくブラウザで画像をコピーするとTextが入る場合があるので、クリア
        clipboard.writeText('')

        # insert loading text
        editor = atom.workspace.getActiveEditor()
        range = editor.insertText('Uploading...');
        @post img, (imgUrl) ->
          # replace loading text to markdown img format
          markdown = "![](#{imgUrl})"
          editor.setTextInBufferRange(range[0], markdown)

  post: (img, callback) ->
    accessToken = atom.config.get('image-copipe.gyazoAccessToken')
    callback('error: access token is required.') unless accessToken

    # gyazoにupload
    req = require('request')
    options = {
      uri: 'https://upload.gyazo.com/api/upload'
      formData: {
        access_token: accessToken
        imagedata: img.toPng()
      }
      json: true
    }
    req.post options, (error, response, body) ->
      if (!error && response.statusCode == 200)
        callback(body.url) if callback && body.url
      else
        callback('error: '+ response.statusCode)
