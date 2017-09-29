# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
  $('#new_upload').fileupload
    dataType: 'json'
    add: (e, data) ->
      types = /(\.|\/)(zip|tar|tar\.gz)$/i
      file = data.files[0]
      if /[a-z0-9]{5}/.test($('#new_upload').find('input[name="fiddle_id"]').val())
        if types.test(file.type) || types.test(file.name)
          $('#new_upload').append(data.context)
          console.log('Size = ' + file['size'])
          if file['size'] > 10240
            alert('Filesize is too big (10 Kb max)');
          else
            data.submit()
      else
        alert("#{file.name} is not a zip)")

    progress: (e, data) ->
      progress = parseInt(data.loaded / data.total * 100, 10)
      $('.progress-bar').css('width', progress + '%')
      if progress == 100
        setTimeout(hide_progress, 2000)
      console.log(progress)
    done: (e, data) ->
      if (data.result == 1)
        $('#run_fiddle').removeClass('not-active')
#        alert('Successfully uploaded the file')
        send_upload_list_ajax()
      else
        console.log(data)
        alert('There was an error uploading the file')
      return
    fail: (e, data) ->
      alert('There was an error uploading the file')
      console.log(data.errorThrown)
      console.log('FAIL')

  update_upload_list = (data) ->
    upload_list = $('#upload_list')
    upload_list.html('')
    if data.message
      upload_list.append data.message
      $('#clear_files').hide()
    else
      $('#clear_files').show()
      row = $('<tr></tr>')
      row.append $('<th></th>').text('File name')
      row.append $('<th></th>').text('File type')
      row.append $('<th></th>').text('Size')
      upload_list.append row
      $.each data.files, (index, value) ->
        row = $('<tr></tr>')
        row.append $('<td></td>').text(value.name)
        row.append $('<td></td>').text(value.mime_type)
        row.append $('<td></td>').text(value.size)
        upload_list.append row
  send_upload_list_ajax = () ->
    token = $('#fiddle_form').find('input[name="fiddle_id"]').val()
    if /[a-z0-9]{5}/.test(token)
      $.ajax(
        url: '/upload/list_files'
        data:{
          token: token
        }
        method: 'GET').done( (data) ->
          update_upload_list data
      ).fail () ->
        alert('The fiddle token is invalid')
    else
      alert('The fiddle token is invalid')

  if $('#upload_list').length
    send_upload_list_ajax()

# We can attach the `fileselect` event to all file inputs on the page
  $(document).on 'change', ':file', ->
    input = $(this)
    numFiles = if input.get(0).files then input.get(0).files.length else 1
    label = input.val().replace(/\\/g, '/').replace(/.*\//, '')
    input.trigger 'fileselect', [
      numFiles
      label
    ]
  # We can watch for our custom `fileselect` event like this
  $(document).ready ->
    $(':file').on 'fileselect', (event, numFiles, label) ->
      input = $(this).parents('.input-group').find(':text')
      log = if numFiles > 1 then numFiles + ' files selected' else label
      if input.length
        input.val log
      else
        if log
          alert log
  $('#clear_files').click( () ->
    token = $('#fiddle_form').find("input[name='fiddle_id']").val()
    if /[a-z0-9]{5}/.test(token)
      $.ajax(
        url: '/upload/clear'
        data:{
          token: token
        }
        method: 'POST').done( (data) ->
          if data.success == 0
            alert(data.message)
          else
            update_upload_list {message: "There are no files to display"}
        ).fail () ->
          alert('The fiddle token is invalid')
    else
      alert('The fiddle token is invalid')
  )
  hide_progress = () ->
    $('.progress-bar').fadeOut('slow')