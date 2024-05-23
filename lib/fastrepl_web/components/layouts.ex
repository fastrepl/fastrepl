defmodule FastreplWeb.Layouts do
  use FastreplWeb, :html

  embed_templates "layouts/*"

  def side_menu(assigns) do
    ~H"""
    <div class="flex h-[calc(100vh-100px)] w-16 flex-col justify-between border-e bg-white">
      <div>
        <div class="inline-flex size-16 items-center justify-center">
          <span class="grid size-10 place-content-center rounded-lg bg-gray-100 text-xs text-gray-600">
            L
          </span>
        </div>

        <div class="border-t border-gray-100">
          <div class="px-2">
            <div class="py-4">
              <a
                href="#"
                class={[
                  "group relative flex justify-center rounded px-2 py-1.5",
                  if(@active_tab == :settings, do: "bg-blue-50 text-blue-700", else: "text-gray-500")
                ]}
              >
                <span class="hero-cog-6-tooth-solid w-4 h-4" />

                <span class="invisible absolute start-full top-1/2 ms-4 -translate-y-1/2 rounded bg-gray-900 px-2 py-1.5 text-xs font-medium text-white group-hover:visible">
                  Settings
                </span>
              </a>
            </div>

            <ul class="space-y-2 border-t border-gray-100 pt-4">
              <li>
                <a
                  href="#"
                  class="group relative flex justify-center rounded px-2 py-1.5 text-gray-500 hover:bg-gray-50 hover:text-gray-700"
                >
                  <span class="hero-command-line-solid w-4 h-4" />

                  <span class="invisible absolute start-full top-1/2 ms-4 -translate-y-1/2 rounded bg-gray-900 px-2 py-1.5 text-xs font-medium text-white group-hover:visible">
                    Coding
                  </span>
                </a>
              </li>

              <li>
                <a
                  href="#"
                  class="group relative flex justify-center rounded px-2 py-1.5 text-gray-500 hover:bg-gray-50 hover:text-gray-700"
                >
                  <span class="hero-chat-bubble-left-right-solid w-4 h-4" />

                  <span class="invisible absolute start-full top-1/2 ms-4 -translate-y-1/2 rounded bg-gray-900 px-2 py-1.5 text-xs font-medium text-white group-hover:visible">
                    Chat
                  </span>
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
