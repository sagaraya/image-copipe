module.exports =
  config:
    SaveTo:
      type: 'string'
      default: 'local'
      enum: ['local','gyazo.com']
    LocalDir:
      type: 'string'
      default: 'images'
  activate: (state) ->
    @attachEvent()

  attachEvent: ->
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.addEventListener 'keydown', (e) =>
      if (e.metaKey && e.keyCode == 86) # detecting cmd+V TODO hook paste event
        clipboard = require('clipboard')
        img = clipboard.readImage()
        return if img.isEmpty()

        clipboard.writeText('')
        save_to = atom.config.get('image-copipe.SaveTo')
        if save_to=='local'
          require 'date-utils'
          {Directory} = require 'atom'

          editor        = atom.workspace.getActiveTextEditor()
          local_dir     = atom.config.get('image-copipe.LocalDir')
          img_file_name = (new Date().toFormat("YYYY-MM-DD_HH24:MI:SS"))+'.png'
          cur_file_path = new Directory(editor.getPath())
          #console.log "cur_file_path=" + cur_file_path.getPath()
          img_real_path = cur_file_path.getParent().getSubdirectory(local_dir).getFile(img_file_name).getPath()
          #console.log "img_real_path=" + img_real_path
          img_relateive_path = local_dir+'/'+img_file_name
          #console.log "img_relateive_path=" + img_relateive_path
          fs = require "fs"
          fs.writeFile img_real_path, img.toPng(), (error) ->
            if error
              console.error("Error writing file", error)
              markdown = "<!---\n[ERROR] Failed to write: " + img_real_path + "\n--->\n"
              editor.insertText(markdown)
            else
              #markdown = "![](#{img_relateive_path})"
              markdown = "<img src=\"#{img_relateive_path}\" width=\"\">"
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
