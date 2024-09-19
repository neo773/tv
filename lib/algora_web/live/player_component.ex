defmodule AlgoraWeb.PlayerComponent do
  use AlgoraWeb, :live_component

  alias Algora.{Library, Events}
  alias AlgoraWeb.Presence

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative">
      <video
        id={@id}
        phx-hook="VideoPlayer"
        class="h-full w-full flex-1 rounded-lg lg:rounded-2xl overflow-hidden"
        controls
        data-media-player
      />
      <div
        id={"mute-overlay-#{@id}"}
        class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-50 cursor-pointer hidden"
        phx-click="unmute"
        phx-target={@myself}
      >
        <svg class="w-24 h-24 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"></path>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2"></path>
        </svg>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    # TODO: log at regular intervals
    # if socket.current_user && socket.assigns.video.is_live do
    #   schedule_watch_event(:timer.seconds(2))
    # end

    socket =
      case assigns[:video] do
        nil ->
          socket

        video ->
          %{current_user: current_user} = assigns

          Events.log_watched(current_user, video)

          Presence.track_user(video.channel_handle, %{
            id: if(current_user, do: current_user.handle, else: "")
          })

          socket
          |> push_event("play_video", %{
            is_live: video.is_live,
            player_id: assigns.id,
            id: video.id,
            url: video.url,
            title: video.title,
            poster: video.thumbnail_url,
            player_type: Library.player_type(video),
            channel_name: video.channel_name,
            current_time: assigns[:current_time] || 0
          })
      end

    {:ok,
     socket
     |> assign(:id, assigns[:id])}
  end

  @impl true
  def handle_event("unmute", _params, socket) do
    {:noreply, push_event(socket, "unmute_video", %{player_id: socket.assigns.id})}
  end
end
