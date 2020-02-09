defmodule PhoenixIntegration.Form.Messages do
  @moduledoc """
  The various messages - both warnings and errors - that can be given to the user. 
  """

  def no_such_name_in_form(change, form, form_action) do
    IO.puts """
      #{IO.ANSI.red()}Attempted to set missing input in form
      #{IO.ANSI.green()}Form action: #{IO.ANSI.red()}#{form_action}
      #{IO.ANSI.green()}Setting key: #{IO.ANSI.red()}#{inspect change.path}
      #{IO.ANSI.green()}And value: #{IO.ANSI.red()}#{inspect change.value}
      #{IO.ANSI.green()}Into form: #{IO.ANSI.yellow()}
      """ <> Floki.raw_html(form)
  end

end
  
