defmodule FastreplWeb.Layouts do
  use FastreplWeb, :html

  embed_templates "layouts/*"

  attr :active_tab, :any, default: nil

  def side_menu(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-80px)] w-16 flex-col justify-between border-e bg-white">
      <div>
        <div class="inline-flex size-16 items-center justify-center">
          <span class="grid size-10 place-content-center rounded-lg bg-gray-100 text-xs text-gray-600">
            P
          </span>
        </div>

        <div class="border-t border-gray-100">
          <div class="px-2">
            <div class="py-4">
              <.link
                navigate={~p"/settings"}
                class={[
                  "group relative flex justify-center rounded px-2 py-1.5",
                  if(@active_tab == :settings, do: "bg-blue-50 text-blue-700", else: "text-gray-500")
                ]}
              >
                <span class="hero-cog-6-tooth-solid w-4 h-4" />

                <span class="z-50 invisible absolute start-full top-1/2 ms-4 -translate-y-1/2 rounded bg-gray-900 px-2 py-1.5 text-xs font-medium text-white group-hover:visible">
                  Settings
                </span>
              </.link>
            </div>

            <ul class="space-y-2 border-t border-gray-100 pt-4">
              <li>
                <.link
                  navigate={~p"/threads"}
                  class={[
                    "group relative flex justify-center rounded px-2 py-1.5",
                    if(@active_tab == :threads, do: "bg-blue-50 text-blue-700", else: "text-gray-500")
                  ]}
                >
                  <span class="hero-queue-list-solid w-4 h-4" />

                  <span class="z-50 invisible absolute start-full top-1/2 ms-4 -translate-y-1/2 rounded bg-gray-900 px-2 py-1.5 text-xs font-medium text-white group-hover:visible">
                    Threads
                  </span>
                </.link>
              </li>

              <li>
                <.link
                  navigate={~p"/chats"}
                  class={[
                    "group relative flex justify-center rounded px-2 py-1.5",
                    if(@active_tab == :chats, do: "bg-blue-50 text-blue-700", else: "text-gray-500")
                  ]}
                >
                  <span class="hero-chat-bubble-left-right-solid w-4 h-4" />

                  <span class="z-50 invisible absolute start-full top-1/2 ms-4 -translate-y-1/2 rounded bg-gray-900 px-2 py-1.5 text-xs font-medium text-white group-hover:visible">
                    Chats
                  </span>
                </.link>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
