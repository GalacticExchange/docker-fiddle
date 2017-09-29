$ ->
  $("#run_fiddle").on "click", (event) ->
    $("#build_output").html("")
    $("#load_icon").show();
    $("#run_fiddle").addClass('not-active')
    event.preventDefault()
    root.codeEditor.save()
    $("#run_fiddle .c").addClass("pulse-animate")
    $("#fiddle_form").trigger("submit.rails")

  $("#save_fiddle").on "click", (event) ->
      event.preventDefault()
      root.codeEditor.save()
      $.ajax
          type: 'POST',
          url: "/fiddles/",
          data: $("#fiddle_form").serialize(),
          dataType: "script"
  $("#update_fiddle").on "click", (event)  ->
      event.preventDefault()
      root.codeEditor.save()
      $.ajax
          type: 'PUT',
          url: $(this).data("update-url"),
          data: $("#fiddle_form").serialize(),
          dataType: "script"
  $("#fork_fiddle").on "click", (event)  ->
      event.preventDefault()
      root.codeEditor.save()
      $.ajax
          type: 'PUT',
          url: $(this).data("fork-url"),
          data: $("#fiddle_form").serialize(),
          dataType: "script"
  code_type = $('#fiddle_form').find('input[name="fiddle[code_type]"]').val()
  if (code_type == "dockerfile")
    mirror_mode = "dockerfile"
  else
    mirror_mode = "yaml"

  root = exports ? this
  if document.getElementById("fiddle_code")
    root.codeEditor = CodeMirror.fromTextArea document.getElementById("fiddle_code"),
        mode: mirror_mode,
        lineNumbers: true,
        lineWrapping: true,
        tabSize: 2,
        extraKeys:
          Tab: (cm)->
            if cm.getSelection().length
            then CodeMirror.commands.indentMore cm
            else cm.replaceSelection("  ", "end")
          'Shift-Tab': (cm)->
            CodeMirror.commands.indentLess cm

    root.codeEditor.on 'change', () ->
      length = root.codeEditor.getValue().length
      if length == 0
        $.each stuff, (_, item) ->
          if item.length
            item.addClass 'not-active'
      else
        $.each stuff, (_, item) ->
         if item.length
           item.removeClass 'not-active'


  linter_widgets = []
  updateHints = (linter_errors) ->
    $('#lint').removeClass('pulse-animate')
    root.codeEditor.operation ->
      $.each linter_widgets, (_, linter_widget) ->
        root.codeEditor.removeLineWidget linter_widget
      linter_widgets = []
      $.each linter_errors, (_, linter_error) ->
        inline = $('<a class="lint-link" href="' + linter_error.link + '">' + linter_error.code + ' </a>').append(linter_error.message) #TODO cheks
        hint = $('<div class="lint-error"></div>').html(inline).get(0)
        line_number = linter_error.line_number - 1
        if line_number < 0
          line_number = 0
        linter_widget = root.codeEditor.addLineWidget(line_number, hint,
          coverGutter: false
          noHScroll: true
          above: true)
        linter_widgets.push linter_widget
  $('#clear').click ->
    $('#clear').addClass('not-active')
    updateHints []
  $('#lint').click ->
    updateHints []
    $('#lint').addClass('not-active')
    $('#lint').addClass('pulse-animate')
    src = root.codeEditor.getDoc().getValue() + '\n'
    $.post('/linter', {code_type: code_type , code: src }, (linter_errors) ->
      console.log linter_errors
      updateHints linter_errors
      $('#clear').removeClass('not-active')
    ).fail () ->
      error = [{
        'link': '#',
        'code': '',
        'message': 'There was an error processing this dockerfile.',
        'line_number' : 0
      }]
      updateHints error
      $('#clear').removeClass('not-active')


#  $(".key-bindings input").on "click", ->
#      root.codeEditor.setOption('keyMap', $(this).data("keybinding"))
  stuff = []
  stuff.push $('#run_fiddle')
  stuff.push $('#save_fiddle')
  stuff.push $('#update_fiddle')
  stuff.push $('#lint')