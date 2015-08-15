module.exports =
  # packageが有効であれば、まず最初にこの関数が呼ばれる。
  # package.jsonにactivationCommandsが定義されていれば、そのコマンドが実行されるまで遅延される。
  config:
    SaveTo:
      type: 'string'
      default: 'gyazo.com'
      enum: ['local path /pic','gyazo.com']
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
        save_to_flag = atom.config.get('image-copipe.SaveTo')
        if save_to_flag=='local path /pic'
          img_dir = 'pic'
          img_file_name = (new Date().toISOString())+'.png'
          editor = atom.workspace.getActiveTextEditor()
          {File, Directory} = require 'atom'
          cur_file_path = new Directory(editor.getPath())
          img_real_path = cur_file_path.getParent().getParent().getSubdirectory(img_dir).getFile(img_file_name).getPath()
          console.log img_real_path
          img_relateive_path = '/'+img_dir+'/'+img_file_name
          fs = require "fs"
          fs.writeFile img_real_path, img.toPng(), (error) ->
            console.error("Error writing file", error) if error
          markdown = "![](#{img_relateive_path})"
          editor.insertText(markdown)
        else
          # insert loading text
          editor = atom.workspace.getActiveTextEditor()
          range = editor.insertText('Uploading...');
          @postToImgur img, (imgUrl) ->
            # replace loading text to markdown img format
            markdown = "![](#{imgUrl})"
            editor.setTextInBufferRange(range[0], markdown)


  postToImgur: (img, callback) ->
    clientId = "1ff14dd2c113a60"

    req = require('request')
    options = {
      uri: 'https://api.imgur.com/3/upload'
      headers: {
        Authorization: "Client-ID " + clientId
      }
      formData: {
        image: img.toPng()
      }
      json: true
    }
    req.post options, (error, response, body) ->
      if (!error && response.statusCode == 200)
        callback(body.data.link) if callback && body.data && body.data.link
      else
        callback('error: '+ response.statusCode)
