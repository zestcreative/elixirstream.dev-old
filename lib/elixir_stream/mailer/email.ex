defmodule ElixirStream.Email do
  import Bamboo.Email
  alias ElixirStreamWeb.Router.Helpers, as: Routes

  def approval_reminder(unapproved_tips) do
    endpoint = ElixirStreamWeb.Endpoint
    to = Application.get_env(:elixir_stream, ElixirStream.Email)[:approvers]

    new_email()
    |> to(to)
    |> from("approval@elixirstream.dev")
    |> subject("New tips to approve")
    |> add_text_body_for_tips(unapproved_tips, endpoint)
    |> add_html_body_for_tips(unapproved_tips, endpoint)
  end

  defp add_html_body_for_tips(email, unapproved_tips, endpoint) do
    html_body(
      email,
      """
      <a href="#{Routes.tip_url(endpoint, :index)}">View all tips</a><br><br>
      <hr>
      """ <>
        for tip <- unapproved_tips, into: "" do
          [
            "<hr>",
            """
            <a href="#{Routes.tip_url(endpoint, :show, tip.id)}">View Tip</a>
            """,
            tip.title,
            tip.contributor.name,
            tip.description,
            "<pre><code>",
            tip.code,
            "</code></pre><br>"
          ]
          |> Enum.intersperse("<br><br>")
          |> IO.iodata_to_binary()
        end
    )
  end

  defp add_text_body_for_tips(email, unapproved_tips, endpoint) do
    text_body(
      email,
      """
      View all tips: #{Routes.tip_url(endpoint, :index)}\n\n
      """ <>
        for tip <- unapproved_tips, into: "" do
          [
            Routes.tip_url(endpoint, :show, tip.id),
            tip.title,
            tip.contributor.name,
            tip.description,
            tip.code,
            "===========================================\n\n\n\n"
          ]
          |> Enum.intersperse("\n\n")
          |> IO.iodata_to_binary()
        end
    )
  end
end
