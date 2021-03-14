defmodule ElixirStreamWeb.Seo do
  @moduledoc """
  This is generic SEO data for any search engine that isn't catered to any one feature.

  https://support.google.com/webmasters/answer/7451184?hl=en
  """

  defmodule Generic do
    defstruct author: "Zest Creative, LLC",
              description:
                "Community of Elixir enthusiasts sharing tips. Made with ❤ with Elixir",
              title: "Elixir Stream",
              language: "en-US"
  end
end
