defmodule Qwhiplash.GameDynamicSupervisor do
  alias Qwhiplash.Core.Game
  alias Qwhiplash.Boundary.GameServer
  use DynamicSupervisor

  @prompts [
    "Największym marzeniem Julki jest ______.",
    "Kiedy Michał coś robi, zawsze kończy się to ______.",
    "Podczas rodzinnej kolacji Magda Gessler rzuciła ______ na stół.",
    "Anton nie wierzy w Boga, ale za to wierzy w ______.",
    "Akis nauczył mnie, że życie to przede wszystkim ______.",
    "Kamil Szram potrafi zasnąć nawet w ______.",
    "Neo właśnie odkrył, że ______ jest najlepszym sposobem na relaks.",
    "Według polskiego internetu, sukces w życiu zależy głównie od ______.",
    "Mój plan na bogactwo w 2024 roku: ______.",
    "Nowa polska tradycja narodowa to świętowanie ______.",
    "GenZ twierdzi, że nie da się przeżyć dnia bez ______.",
    "Największy sekret TikToka: cała platforma opiera się na ______.",
    "Najlepszy sposób, by zdobyć followersów, to ______.",
    "Julka zawsze mówi: „Życie to nie bajka, to ______”.",
    "Michał ostatnio próbował ______ i skończyło się szpitalem.",
    "Największa polska obsesja w 2024 roku: ______.",
    "Anton twierdzi, że ______ jest kluczem do zrozumienia życia.",
    "Kiedy Magda Gessler nie gotuje, zajmuje się ______.",
    "Kamil Szram powiedział, że jedynym celem w życiu jest ______.",
    "Neo przeprogramował system i teraz główną funkcją komputera jest ______.",
    "Najbardziej sarkastyczny komentarz, jaki usłyszałem od Julki, to: „A może spróbujesz ______?”.",
    "Akis jest tajemniczy, bo podobno kiedyś zrobił ______.",
    "Najgorszy pomysł na reality show: „Życie z ______”.",
    "Polska nauka w końcu znalazła sposób na ______.",
    "Najnowszy polski mem, który zniszczył internet: ______.",
    "Nie wiem, co jest bardziej stresujące: egzamin, czy ______.",
    "Nowa aplikacja społecznościowa skupia się tylko na ______.",
    "Magda Gessler na kolejną rewolucję restauracyjną przynosi ______.",
    "Akis i Misia twierdzą, że sekretem ich związku jest ______.",
    "Najbardziej romantyczny prezent, jaki Akis dał Misi, to ______.",
    "Misia chciała zrobić Akisowi niespodziankę, ale skończyło się na ______.",
    "Akis i Misia kłócą się najczęściej o ______.",
    "Idealny wieczór Akisa i Misi to dużo ______ i zero problemów.",
    "Gdyby Elon Musk był Polakiem, nazwałby swój następny projekt ______.",
    "Julka twierdzi, że jedyną rzeczą wartą uwagi na tym świecie jest ______.",
    "Michał ostatnio powiedział, że oszczędza na ______.",
    "Kamil Szram podobno ma kolekcję ______ w swoim pokoju.",
    "Neo uwielbia wieczory z Netflixem i ______.",
    "Akis został sławny dzięki swojej teorii o ______.",
    "W polskiej edukacji brakuje przede wszystkim ______.",
    "Jedyny sposób, by przekonać GenZ do pracy, to obiecać im ______.",
    "Hubert twierdzi, że jedynym prawdziwym sensem życia jest ______.",
    "Stasiu jest rudy, ale przynajmniej ma ______.",
    "Misia ostatnio odkryła, że nie da się zrobić omletu bez ______.",
    "Michał myślał, że oszczędza prąd, a tak naprawdę marnował go na ______.",
    "Hubert zawsze mówi: „Jeśli życie daje ci cytryny, zrób ______”.",
    "Stasiu twierdzi, że bycie rudym to dar, bo pozwala na ______.",
    "Misia i Michał spędzili cały dzień próbując wymyślić, jak działa ______.",
    "Hubert znalazł nową pasję: ______.",
    "Misia myślała, że może zbudować rakietę z ______.",
    "Michał powiedział, że jedyną rzeczą, której nie rozumie, jest ______.",
    "Hubert i jego nowy biznesplan: sprzedaż ______.",
    "Stasiu, jak na rudego przystało, marzy o karierze w ______.",
    "Misia próbowała naprawić komputer, ale zamiast tego stworzyła ______.",
    "Michał ostatnio pochwalił się swoim największym osiągnięciem: ______.",
    "Hubert i jego nowy trend w internecie: #______.",
    "Misia i Michał postanowili rozwiązać problem globalnego ocieplenia za pomocą ______.",
    "Hubert uczy, że najlepsza motywacja w życiu to ______.",
    "Akis i Misia twierdzą, że sekretem ich związku jest ______.",
    "Najbardziej romantyczny prezent, jaki Akis dał Misi, to ______.",
    "Misia chciała zrobić Akisowi niespodziankę, ale skończyło się na ______.",
    "Akis i Misia kłócą się najczęściej o ______.",
    "Idealny wieczór Akisa i Misi to dużo ______ i zero problemów.",
    "Mikołaj zmienia ______ jak rękawiczki",
    "Maja Doksa twierdzi, że najlepszym uzupełnieniem piwa jest ______.",
    "Ostatnio Maja spiła się tak bardzo, że skończyła na ______ po hotdogach."
  ]

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_game(host_id) do
    case find_game_by_host_id(host_id) do
      {:ok, pid, _} -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      nil -> nil
    end

    DynamicSupervisor.start_child(
      __MODULE__,
      %{
        id: Qwhiplash.Boundary.GameServer,
        start: {Qwhiplash.Boundary.GameServer, :start_link, [{host_id, @prompts}]}
      }
    )
  end

  @spec find_game_by_host_id(String.t()) :: {:ok, pid(), Game.t()} | nil
  def find_game_by_host_id(id) do
    case DynamicSupervisor.which_children(__MODULE__)
         |> Enum.find(&match_host_id(&1, id)) do
      {_, pid, _, _} ->
        {:ok, state} = GameServer.get_game_state(pid)
        {:ok, pid, state}

      nil ->
        nil
    end
  end

  @spec find_game_by_game_code(String.t()) :: {:ok, pid(), Game.t()} | nil
  def find_game_by_game_code(id) do
    case DynamicSupervisor.which_children(__MODULE__)
         |> Enum.find(&match_game_code(&1, id)) do
      {_, pid, _, _} ->
        {:ok, state} = GameServer.get_game_state(pid)
        {:ok, pid, state}

      nil ->
        nil
    end
  end

  @spec find_game_by_code_and_player(String.t(), binary()) ::
          {:ok, pid(), Game.t()} | {:error, :not_found}
  def find_game_by_code_and_player(code, player_id) do
    with {:ok, pid, game} <- find_game_by_game_code(code),
         true <- Map.has_key?(game.players, player_id) do
      {:ok, pid, game}
    else
      _ -> {:error, :not_found}
    end
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp match_host_id({_, pid, _, _}, id) do
    case GameServer.get_host_id(pid) do
      {:ok, host_id} -> host_id == id
      _ -> false
    end
  end

  defp match_game_code({_, pid, _, _}, code) do
    case GameServer.get_game_code(pid) do
      {:ok, game_code} -> game_code == code
      _ -> false
    end
  end
end
